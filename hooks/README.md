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
