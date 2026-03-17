# Interactive Tests

Tests that require a live Claude Code session. Run these by asking Claude to
execute them (e.g., "run the interactive tests" or "test the push hook live").

## IT-01: git-push-guard fires on push

**Setup:** Create a temp bare repo and local repo in ~/tmp.
**Action:** Attempt `git push` to the bare repo.
**Expected:** Claude is prompted for confirmation before push executes.
**Teardown:** Remove ~/tmp/test-push-hook/.

## IT-02: tmp-write-guard blocks /tmp writes

**Action:** Ask Claude to write a file to /tmp/test-hook.txt.
**Expected:** The Write tool call is denied with "Use ~/tmp instead" message.
**Verify:** The file /tmp/test-hook.txt does NOT exist.

## IT-03: tmp-write-guard allows ~/tmp writes

**Action:** Ask Claude to write a file to ~/tmp/test-hook.txt.
**Expected:** The write succeeds without being blocked.
**Teardown:** Remove ~/tmp/test-hook.txt.

## IT-04: test-edit-guard injects context on test file edit

**Setup:** Create a dummy test file ~/tmp/test_example.py.
**Action:** Ask Claude to edit the test file (e.g., add a comment).
**Expected:** Hook fires and injects "TEST FILE EDITED" context. Check
~/tmp/hook-debug.log for a log entry.
**Teardown:** Remove ~/tmp/test_example.py.

## IT-05: statusline displays correctly

**Action:** Observe the Claude Code status bar during normal operation.
**Expected:** Shows user@host:cwd, git branch with indicators, context %, and
session cost.
