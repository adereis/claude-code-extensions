# Hooks

Claude Code hooks are scripts that run at specific points during tool execution. Copy this directory to `~/.claude/hooks/`, then add the configuration snippets below to your `~/.claude/settings.json`.

## git-push-guard.sh

**Command confirmation guard** — forces human confirmation before specific commands execute, even when Bash is pre-approved via permissions.

This is useful as a safety net for autonomous or semi-autonomous sessions: you can broadly allow Bash commands for speed, while still requiring explicit approval for high-impact operations. The hook intercepts commands *after* Claude Code's own permission check, so it acts as an additional protection layer.

**Default behavior:** Guards `git push` commands. Prevents accidental pushes when Claude is running autonomously.

**Adapting to other commands:** The script uses parallel `PATTERNS` and `REASONS` arrays. Uncomment the built-in examples or add your own — the first matching pattern wins and its reason is shown to the user:

| Guard | Pattern | Use case |
|-------|---------|----------|
| `git push` (default) | `\bgit\s+push\b` | Prevent unreviewed pushes |
| `kubectl delete` | `\bkubectl\s+delete\b` | Protect cluster resources |
| `docker rm` | `\bdocker\s+rm\b` | Prevent container removal |
| `terraform destroy` | `\bterraform\s+destroy\b` | Protect infrastructure |
| `rm -rf` | `\brm\s+-rf\b` | Prevent recursive deletion |

Multiple guards are handled within a single script — just add more `PATTERNS+=` / `REASONS+=` pairs. Each match produces a specific reason so the user knows exactly which command triggered the confirmation.

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/git-push-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Merge the `hooks` object into your existing settings.json. If you already have `PreToolUse` hooks, add the new hook object to the existing array.

## tmp-write-guard.sh

**Path write deny guard** — hard-blocks writes to specific paths with no user override. Uses `permissionDecision: "deny"` for unconditional blocking.

This differs from the command confirmation guard: instead of *asking* before proceeding, it *denies* outright. Use this for security boundaries where the answer is always "no".

**Default behavior:** Blocks writes to `/tmp/` (predictable filenames are a security risk). Claude sees the error message and should use `~/tmp` instead.

**Note:** Despite documentation suggesting equivalence, `"block"` shows a prompt while `"deny"` prevents execution entirely.

**Upstream issue:** https://github.com/anthropics/claude-code/issues/14085 — The `/tmp` block may become unnecessary once resolved.

**Adapting to other paths:** The script uses parallel `BLOCKED_PATHS` and `DENY_MESSAGES` arrays. Add entries to block additional paths:

| Guard | Path | Use case |
|-------|------|----------|
| `/tmp/` (default) | `/tmp/` | Prevent insecure temp file creation |
| `/etc/` | `/etc/` | Protect system configuration |
| `/var/run/` | `/var/run/` | Protect runtime state |

**Smart exceptions** (apply to all blocked paths):
- Read-only commands (`cat`, `ls`, `head`, `tail`, etc.) are allowed
- Cleanup commands (`rm`) are allowed
- Git commands are allowed (paths may appear in commit messages)
- Redirects from read-only commands (`cat > /path`) are still blocked

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tmp-write-guard.sh"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tmp-write-guard.sh"
          }
        ]
      }
    ]
  }
}
```

## test-edit-guard.sh

Forces structured analysis before editing test files. Addresses the problem where Claude "fixes" failing tests instead of recognizing that the code is incomplete.

**Problem it solves:** When tests fail, it's tempting to modify the tests to pass. But often the tests are correct and the code is incomplete (e.g., backporting only part of a feature, missing a dependency).

**Behavior:**
- Detects test files by name patterns (`test_*`, `*_test.*`, `*.spec.*`, etc.) and directory (`test/`, `tests/`, `__tests__/`)
- Uses `additionalContext` to inject a nudge Claude sees after the edit executes
- Prompts Claude to verify the edit was correct and revert if the code was incomplete
- Logs to `~/tmp/hook-debug.log` when triggered (for debugging)

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/test-edit-guard.sh"
          }
        ]
      }
    ]
  }
}
```

## continue-plan.sh

**Stop event handler** — auto-continues multi-phase plan execution. When enabled via environment variable, Claude continues autonomously instead of stopping after each phase.

Unlike the guards above (which intercept tool calls), this hook intercepts the `Stop` event — it runs when Claude would normally stop and wait for input. It uses exit code 2 to block stopping and injects instructions via stderr.

**Features:**
- Disabled by default (must set `CLAUDE_AUTO_PLAN=1`)
- Stops after 5 restarts (prevents infinite loops)
- Detects `ALL_PHASES_COMPLETE` marker to stop early
- Instructs Claude to run tests, make autonomous decisions, and record them in `DECISIONS.md`

**Usage:**

```bash
CLAUDE_AUTO_PLAN=1 claude
```

**Configuration:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/continue-plan.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```
