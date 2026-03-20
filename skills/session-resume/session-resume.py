#!/usr/bin/env python3
"""Smart session resume for Claude Code.

Shows enriched session history (multiple prompts, git commits, files touched)
and lets you pick a session to resume.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
PROJECTS_DIR = CLAUDE_DIR / "projects"

# Pattern to detect skill/command invocations in user prompts
_COMMAND_RE = re.compile(
    r"<command-name>\s*/(\S+)\s*</command-name>"
)


_SKILL_EXPANSION_RE = re.compile(
    r"^Base directory for this skill:"
)


def _clean_prompt(text: str) -> str:
    """Clean up a user prompt, replacing command XML with /command-name.

    Returns empty string for prompts that should be skipped entirely
    (e.g., skill expansion content injected by Claude Code).
    """
    m = _COMMAND_RE.search(text)
    if m:
        return f"/{m.group(1)}"
    # Skip skill expansion content (SKILL.md injected as user message)
    if _SKILL_EXPANSION_RE.match(text):
        return ""
    return text


def cwd_to_project_key(cwd: str) -> str:
    """Convert a working directory path to the Claude project key format."""
    return cwd.replace("/", "-")


def find_project_dir(cwd: str) -> Path | None:
    """Find the Claude project directory for a given working directory."""
    key = cwd_to_project_key(cwd)
    candidate = PROJECTS_DIR / key
    if candidate.is_dir():
        return candidate
    return None


def all_project_dirs() -> list[Path]:
    """Return all project directories that have sessions (index or JSONL files)."""
    results = []
    if not PROJECTS_DIR.is_dir():
        return results
    for d in sorted(PROJECTS_DIR.iterdir()):
        if not d.is_dir():
            continue
        has_index = (d / "sessions-index.json").exists()
        has_jsonl = any(d.glob("*.jsonl"))
        if has_index or has_jsonl:
            results.append(d)
    return results


def load_sessions_index(project_dir: Path) -> list[dict]:
    """Load sessions from index + any JSONL files not in the index."""
    index_file = project_dir / "sessions-index.json"
    entries = []
    indexed_ids = set()

    if index_file.exists():
        with open(index_file) as f:
            data = json.load(f)
        entries = data.get("entries", [])
        indexed_ids = {e["sessionId"] for e in entries}

    # Discover JSONL files not represented in the index
    for jsonl in project_dir.glob("*.jsonl"):
        sid = jsonl.stem
        if sid in indexed_ids:
            continue
        entry = _entry_from_jsonl(jsonl, sid)
        if entry:
            entries.append(entry)

    return entries


def _entry_from_jsonl(jsonl_path: Path, session_id: str) -> dict | None:
    """Build a minimal session entry by reading JSONL metadata."""
    first_user = None
    last_timestamp = None
    msg_count = 0

    with open(jsonl_path) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") in ("user", "assistant"):
                msg_count += 1
                ts = obj.get("timestamp")
                if ts:
                    last_timestamp = ts
            if obj.get("type") == "user" and first_user is None:
                first_user = obj

    if not first_user:
        return None

    msg = first_user.get("message", {})
    content = msg.get("content", "")
    if isinstance(content, list):
        for c in content:
            if isinstance(c, dict) and c.get("type") == "text":
                content = c["text"]
                break
        else:
            content = ""
    first_prompt = content.strip() if isinstance(content, str) else ""

    created = first_user.get("timestamp", "")
    return {
        "sessionId": session_id,
        "fullPath": str(jsonl_path),
        "firstPrompt": first_prompt or "No prompt",
        "summary": "",
        "messageCount": msg_count,
        "created": created,
        "modified": last_timestamp or created,
        "gitBranch": first_user.get("gitBranch", ""),
        "projectPath": first_user.get("cwd", ""),
        "isSidechain": False,
    }


def parse_session_jsonl(jsonl_path: str) -> dict:
    """Parse a session JSONL file to extract prompts, git commands, and files."""
    path = Path(jsonl_path)
    if not path.exists():
        return {}

    user_prompts = []  # list of (serial_number, text)
    prompt_num = 0
    git_commits = []  # list of (sha, message)
    files_edited = set()
    # Track pending git commit tool calls to match with their results
    pending_commits = {}  # tool_use_id -> commit_message

    with open(path) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg = obj.get("message", {})
            if not isinstance(msg, dict):
                continue

            role = msg.get("role", "")
            content = msg.get("content", "")

            # Extract user prompts
            if role == "user":
                text = ""
                if isinstance(content, str) and content.strip():
                    text = content.strip()
                elif isinstance(content, list):
                    for c in content:
                        if isinstance(c, dict) and c.get("type") == "text":
                            text = c["text"].strip()
                            break
                if text:
                    text = _clean_prompt(text)
                    if text:
                        prompt_num += 1
                        user_prompts.append((prompt_num, text))

            # Extract tool calls from assistant messages
            if isinstance(content, list):
                for c in content:
                    if not isinstance(c, dict):
                        continue

                    # Match tool results to pending git commits
                    if c.get("type") == "tool_result" and c.get("tool_use_id") in pending_commits:
                        tool_id = c["tool_use_id"]
                        commit_msg = pending_commits.pop(tool_id)
                        result = c.get("content", "")
                        if isinstance(result, list):
                            for r in result:
                                if isinstance(r, dict) and r.get("type") == "text":
                                    result = r["text"]
                                    break
                            else:
                                result = ""
                        # Extract SHA from result: [branch SHA] message
                        sha_match = re.search(r"\[[\w/-]+\s+([0-9a-f]{7,})\]", str(result))
                        sha = sha_match.group(1)[:7] if sha_match else ""
                        git_commits.append((sha, commit_msg))
                        continue

                    if c.get("type") != "tool_use":
                        continue
                    name = c.get("name", "")
                    inp = c.get("input", {})

                    if name == "Bash":
                        cmd = inp.get("command", "")
                        # Only match actual git commit commands, not scripts
                        # that mention "git commit"
                        if cmd.startswith("git commit"):
                            # HEREDOC: git commit -m "$(cat <<'EOF'\nSummary line
                            m = re.search(
                                r"""cat\s*<<\s*'?EOF'?\s*\n(.+?)(?:\n|$)""", cmd
                            )
                            if m:
                                commit_msg = m.group(1).strip()[:80]
                            else:
                                # Simple: git commit -m "message"
                                m = re.search(
                                    r"""-m\s+["'](.+?)["']""", cmd
                                )
                                commit_msg = m.group(1)[:80] if m else "(commit)"
                            pending_commits[c.get("id", "")] = commit_msg

                    elif name in ("Write", "Edit"):
                        fp = inp.get("file_path", "")
                        if fp:
                            files_edited.add(fp)

    # Any pending commits without results (e.g., failed or still running)
    for tool_id, commit_msg in pending_commits.items():
        git_commits.append(("", commit_msg))

    return {
        "user_prompts": user_prompts,
        "git_commits": git_commits,
        "files_edited": sorted(files_edited),
    }


def format_age(iso_str: str) -> str:
    """Format an ISO timestamp as a human-readable age string."""
    try:
        dt = datetime.fromisoformat(iso_str)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        delta = now - dt
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return "just now"
        elif seconds < 3600:
            m = seconds // 60
            return f"{m}m ago"
        elif seconds < 86400:
            h = seconds // 3600
            return f"{h}h ago"
        else:
            d = seconds // 86400
            return f"{d}d ago"
    except (ValueError, TypeError):
        return "unknown"


def format_duration(created: str, modified: str) -> str:
    """Format session duration from created/modified timestamps."""
    try:
        c = datetime.fromisoformat(created)
        m = datetime.fromisoformat(modified)
        delta = m - c
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return f"{seconds}s"
        elif seconds < 3600:
            return f"{seconds // 60}m"
        else:
            h = seconds // 3600
            m = (seconds % 3600) // 60
            return f"{h}h{m}m" if m else f"{h}h"
    except (ValueError, TypeError):
        return "?"


def truncate(text: str, length: int) -> str:
    """Truncate text to length, adding ellipsis if needed."""
    text = text.replace("\n", " ").strip()
    if len(text) <= length:
        return text
    return text[: length - 1] + "\u2026"


HOME = str(Path.home())


def shorten_path(path: str) -> str:
    """Replace $HOME prefix with ~ for display."""
    if path.startswith(HOME + "/"):
        return "~" + path[len(HOME):]
    if path == HOME:
        return "~"
    return path


def project_path_from_key(key: str) -> str:
    """Convert a project directory key back to a path."""
    # Keys look like -home-areis-projects-foo, meaning /home/areis/projects/foo
    return key.replace("-", "/", 1).replace("-", "/")


def display_session(idx: int, entry: dict, parsed: dict | None, verbose: bool):
    """Display a single session entry."""
    sid = entry["sessionId"]
    age = format_age(entry.get("modified", entry.get("created", "")))
    duration = format_duration(entry.get("created", ""), entry.get("modified", ""))
    branch = entry.get("gitBranch", "")
    summary = entry.get("summary", "")
    msg_count = entry.get("messageCount", 0)
    project = entry.get("projectPath", "")

    # Header line
    branch_str = f"  [{branch}]" if branch else ""
    print(f"  \033[1;33m{idx}\033[0m  {age}, {duration}, {msg_count} msgs{branch_str}  {sid}")

    # Summary
    if summary:
        print(f"     \033[1m{truncate(summary, 90)}\033[0m")

    # Prompts: show arc (first, second-to-last, last) with serial numbers
    if parsed and parsed.get("user_prompts"):
        prompts = parsed["user_prompts"]
        selected = _select_arc_prompts(prompts)
        for num, text in selected:
            label = f"#{num:<3d}"
            print(f"     \033[2m{label} {truncate(text, 81)}\033[0m")
    else:
        # Fall back to firstPrompt from index
        first = entry.get("firstPrompt", "")
        if first and first != "No prompt":
            print(f"     \033[2m> {truncate(first, 85)}\033[0m")

    # Git commits
    if parsed and parsed.get("git_commits"):
        commits = parsed["git_commits"]
        limit = len(commits) if verbose else 3
        for sha, msg in commits[:limit]:
            sha_str = f"{sha} " if sha else ""
            print(f"     \033[32m{sha_str}{truncate(msg, 85 - len(sha_str))}\033[0m")
        remaining = len(commits) - limit
        if remaining > 0:
            print(f"     \033[32m  ...and {remaining} more commit(s)\033[0m")

    # Files (verbose only)
    if verbose and parsed and parsed.get("files_edited"):
        files = parsed["files_edited"]
        limit = 10
        for fp in files[:limit]:
            # Show relative to project if possible
            project = entry.get("projectPath", "")
            if project and fp.startswith(project):
                fp = fp[len(project) :].lstrip("/")
            else:
                fp = shorten_path(fp)
            print(f"     \033[36m\u270e {fp}\033[0m")
        remaining = len(files) - limit
        if remaining > 0:
            print(f"     \033[36m  ...and {remaining} more file(s)\033[0m")

    print()


def _select_arc_prompts(prompts: list[tuple]) -> list[tuple]:
    """Select prompts that tell the session's story: first, second-to-last, last."""
    if len(prompts) <= 3:
        return prompts

    selected = [prompts[0]]
    if len(prompts) >= 3:
        selected.append(prompts[-2])
    selected.append(prompts[-1])
    return selected


def main():
    parser = argparse.ArgumentParser(
        description="Smart session resume for Claude Code"
    )
    parser.add_argument(
        "-n",
        "--count",
        type=int,
        default=10,
        help="Number of sessions to show (default: 10)",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Show extra details (files edited)"
    )
    parser.add_argument(
        "-a",
        "--all",
        action="store_true",
        help="Show sessions from all projects, not just current directory",
    )
    parser.add_argument(
        "-p",
        "--project",
        type=str,
        default=None,
        help="Show sessions for a specific project path",
    )
    parser.add_argument(
        "-l",
        "--skill",
        action="store_true",
        help="Non-interactive output with session IDs (for /session-resume skill)",
    )
    args = parser.parse_args()

    # Determine which project(s) to show
    if args.all:
        project_dirs = all_project_dirs()
        if not project_dirs:
            print("No Claude Code sessions found.", file=sys.stderr)
            sys.exit(1)
    else:
        target = args.project or os.getcwd()
        project_dir = find_project_dir(target)
        if project_dir is None:
            print(
                f"No Claude Code sessions found for: {target}", file=sys.stderr
            )
            print(
                "Use --all to see sessions from all projects, or --project <path>.",
                file=sys.stderr,
            )
            sys.exit(1)
        project_dirs = [project_dir]

    # Collect all sessions, skipping those without JSONL files (unresumable)
    all_sessions = []
    for pd in project_dirs:
        entries = load_sessions_index(pd)
        for e in entries:
            e["_project_dir"] = str(pd)
            # Check if the session's JSONL file actually exists
            fp = e.get("fullPath", "")
            if fp and Path(fp).exists():
                all_sessions.append(e)
            elif (pd / f"{e['sessionId']}.jsonl").exists():
                all_sessions.append(e)
            # else: stale index entry, skip

    # Sort by modified time (most recent first) to pick the top N,
    # then reverse so newest appears at the bottom (closest to prompt)
    all_sessions.sort(
        key=lambda e: e.get("modified", e.get("created", "")), reverse=True
    )
    sessions = all_sessions[: args.count]
    sessions.reverse()

    if not sessions:
        print("No sessions found.", file=sys.stderr)
        sys.exit(1)

    # Show header
    if args.all:
        print(f"\n\033[1mClaude Code Sessions (all projects, showing {len(sessions)})\033[0m\n")
    else:
        target = args.project or os.getcwd()
        print(f"\n\033[1mClaude Code Sessions for {shorten_path(target)} (showing {len(sessions)})\033[0m\n")

    # Parse JSONL files where available, display sessions
    current_project = None
    for i, entry in enumerate(sessions, 1):
        # Show project header if --all and project changed
        if args.all:
            proj = entry.get("projectPath", "unknown")
            if proj != current_project:
                current_project = proj
                print(f"  \033[1;35m--- {shorten_path(proj)} ---\033[0m\n")

        # Try to parse JSONL — fullPath in the index may be stale,
        # so also check for the file by session ID in the project dir
        jsonl_path = entry.get("fullPath", "")
        if not jsonl_path or not Path(jsonl_path).exists():
            candidate = Path(entry["_project_dir"]) / f"{entry['sessionId']}.jsonl"
            if candidate.exists():
                jsonl_path = str(candidate)
        parsed = parse_session_jsonl(jsonl_path) if jsonl_path else None

        display_session(i, entry, parsed, args.verbose)

    if args.skill:
        sys.exit(0)

    # Selection — Enter defaults to the last (most recent) session
    default = len(sessions)
    print(f"\033[1mSelect session to resume [{default}] (q to quit):\033[0m ", end="")
    try:
        choice = input().strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(0)

    if choice.lower() in ("q", "quit"):
        sys.exit(0)

    if choice == "":
        num = default
    else:
        try:
            num = int(choice)
        except ValueError:
            print(f"Invalid selection: {choice}", file=sys.stderr)
            sys.exit(1)

    if num < 1 or num > len(sessions):
        print(f"Selection out of range: {num}", file=sys.stderr)
        sys.exit(1)

    selected = sessions[num - 1]
    session_id = selected["sessionId"]
    project_path = selected.get("projectPath", "")

    # Verify project directory exists
    if project_path and not os.path.isdir(project_path):
        print(
            f"\nProject directory no longer exists: {project_path}",
            file=sys.stderr,
        )
        print("Cannot resume this session.", file=sys.stderr)
        sys.exit(1)

    # Show command and confirm
    cmd = f"claude --resume {session_id}"
    needs_cd = project_path and os.path.realpath(project_path) != os.path.realpath(os.getcwd())
    if needs_cd:
        print(f"\n  cd {shorten_path(project_path)} && {cmd}\n")
    else:
        print(f"\n  {cmd}\n")

    print("\033[1mRun this command? [Y/n]\033[0m ", end="")
    try:
        confirm = input().strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(0)

    if confirm.lower() in ("n", "no"):
        sys.exit(0)

    # Execute
    if needs_cd:
        os.chdir(project_path)
    os.execvp("claude", ["claude", "--resume", session_id])


if __name__ == "__main__":
    main()
