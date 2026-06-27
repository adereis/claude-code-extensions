#!/bin/bash
# Tests for claude-code-session-resume.py parsing logic.
#
# Focuses on the two subtle, regression-prone behaviors:
#   - git-commit detection: catch compound commands (recall) without being
#     fooled by commit-like text that was merely printed (precision)
#   - parse_session_jsonl: title extraction + commit/result matching end-to-end
#
# The script's filename has hyphens, so it can't be `import`ed by name; we load
# it from its path with importlib. Only function defs run at import (main() is
# guarded), so importing is safe.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
SCRIPT="$SCRIPT_DIR/../scripts/claude-code-session-resume.py"

test_begin "session-resume parsing"

_stdout=$(python3 - "$SCRIPT" <<'PY'
import importlib.util, sys, json, tempfile, os

spec = importlib.util.spec_from_file_location("ccsr", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def b(x):
    return "True" if x else "False"

# --- command detection: recall (real commits, incl. compound forms) ---
print("simple=" + b(m._command_makes_commit('git commit -m x')))
print("compound=" + b(m._command_makes_commit('git add -A && git commit -m "feat: x"')))
print("softreset=" + b(m._command_makes_commit('git reset --soft HEAD~1 && git add -A && git commit -m x')))
print("globalopt=" + b(m._command_makes_commit('git -C /tmp/repo commit -m x')))
print("amend=" + b(m._command_makes_commit('git commit --amend --no-edit')))

# --- command detection: precision (must NOT count these) ---
print("log=" + b(m._command_makes_commit('git log --oneline -5')))
print("grep=" + b(m._command_makes_commit('git log --grep=commit')))
print("echo=" + b(m._command_makes_commit("echo 'run git commit later'")))
print("pystr=" + b(m._command_makes_commit('python3 -c "x = 1 if \'git commit\' in cmd else 0"')))

# --- result-line extraction from git's "[branch sha] summary" output ---
def one(t):
    r = m._commits_from_result(t)
    return f"{r[0][0]}|{r[0][1]}" if r else "NONE"
print("res_simple=" + one("[main abc1234] fix: thing\n 1 file changed, 2 insertions(+)"))
print("res_detached=" + one("[detached HEAD def5678] msg"))
print("res_root=" + one("[main (root-commit) abcdef0] init"))
print("res_info=" + one("[INFO] not a commit line"))
print("res_branchonly=" + one("[main] already up to date"))

# --- end-to-end: title + commit gated on a real invocation, phantom rejected ---
recs = [
    {"type": "ai-title", "aiTitle": "My Session Title"},
    {"type": "user", "message": {"role": "user",
        "content": [{"type": "text", "text": "do the thing"}]}},
    # Real commit: compound command + matching result.
    {"type": "assistant", "message": {"role": "assistant", "content": [
        {"type": "tool_use", "id": "T1", "name": "Bash",
         "input": {"command": 'git add -A && git commit -m "feat: x"'}}]}},
    {"type": "user", "message": {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "T1",
         "content": [{"type": "text", "text": "[main abc1234] feat: x\n 1 file changed"}]}]}},
    # Phantom: a non-commit command whose output merely contains a commit line.
    {"type": "assistant", "message": {"role": "assistant", "content": [
        {"type": "tool_use", "id": "T2", "name": "Bash",
         "input": {"command": "git log --oneline -1"}}]}},
    {"type": "user", "message": {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "T2",
         "content": [{"type": "text", "text": "[main deadbee] phantom not a real commit"}]}]}},
]
fd, fp = tempfile.mkstemp(suffix=".jsonl")
with os.fdopen(fd, "w") as f:
    for r in recs:
        f.write(json.dumps(r) + "\n")
parsed = m.parse_session_jsonl(fp)
os.unlink(fp)
print("title=" + parsed["title"])
print("ncommits=" + str(len(parsed["git_commits"])))
print("commit0=" + (f"{parsed['git_commits'][0][0]}:{parsed['git_commits'][0][1]}"
                    if parsed["git_commits"] else "NONE"))
print("phantom=" + b(any(sha == "deadbee" for sha, _ in parsed["git_commits"])))
PY
)

# Recall: real commits detected, including compound/global-option forms.
assert_output_contains "simple=True"
assert_output_contains "compound=True"
assert_output_contains "softreset=True"
assert_output_contains "globalopt=True"
assert_output_contains "amend=True"

# Precision: commit-like text that isn't a commit invocation is ignored.
assert_output_contains "log=False"
assert_output_contains "grep=False"
assert_output_contains "echo=False"
assert_output_contains "pystr=False"

# Result parsing yields (sha, summary); non-commit brackets are rejected.
assert_output_contains "res_simple=abc1234|fix: thing"
assert_output_contains "res_detached=def5678|msg"
assert_output_contains "res_root=abcdef0|init"
assert_output_contains "res_info=NONE"
assert_output_contains "res_branchonly=NONE"

# End-to-end: title shown, only the real commit counted, phantom dropped.
assert_output_contains "title=My Session Title"
assert_output_contains "ncommits=1"
assert_output_contains "commit0=abc1234:feat: x"
assert_output_contains "phantom=False"

test_summary "session-resume"
