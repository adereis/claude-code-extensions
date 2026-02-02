# Hooks

Claude Code hooks are scripts that run at specific points during tool execution. Copy this directory to `~/.claude/hooks/`, then add the configuration snippets below to your `~/.claude/settings.json`.

## git-push-guard.sh

Requires explicit confirmation before any `git push` command executes. Prevents accidental pushes when Claude is running autonomously.

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

Hard-blocks writes to `/tmp/` (security risk due to predictable filenames). Claude sees the error message and should use `~/tmp` instead.

**Note:** Uses `permissionDecision: "deny"` for a hard block. Despite documentation suggesting equivalence, `"block"` shows a prompt while `"deny"` prevents execution entirely.

**Upstream issue:** https://github.com/anthropics/claude-code/issues/14085 — This hook may become unnecessary once the issue is resolved.

**Behavior:**
- Denies: `Write` tool to `/tmp/*`, bash commands that write to `/tmp/`
- Allows: read-only commands (`cat`, `ls`, `head`, `tail`) and cleanup (`rm`)

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

Auto-continues multi-phase plan execution. When enabled via environment variable, Claude continues autonomously instead of stopping after each phase.

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
