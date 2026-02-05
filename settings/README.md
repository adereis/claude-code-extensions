# Settings

Claude Code settings configurations. Add these snippets to your `~/.claude/settings.json`.

## statusline.sh

A bash-prompt-style statusline showing git status, context usage, and session cost.

**Example output:**
```
areis@laptop:/home/areis/project (main*+%) [ctx: 12.3%] [$0.0542]
```

**Components:**

| Component | Color | Description |
|-----------|-------|-------------|
| `user@host` | Green | Current user and hostname |
| `/path/to/dir` | Blue | Working directory |
| `(branch*+%)` | Yellow | Git branch with status indicators |
| `[ctx: X%]` | Magenta | Context window usage percentage |
| `[$Y.YYYY]` | Cyan | Session cost in USD |

**Git indicators:**
- `*` = uncommitted changes (dirty working tree)
- `+` = staged changes (ready to commit)
- `%` = untracked files

**Installation:**

1. Copy `statusline.sh` to `~/.claude/settings/`
2. Make it executable: `chmod +x ~/.claude/settings/statusline.sh`
3. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/settings/statusline.sh"
  }
}
```

**Inline alternative:**

If you prefer not to use a separate script, use this one-liner directly in settings.json:

```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); git_info=''; if git -C \"$cwd\" rev-parse --git-dir >/dev/null 2>&1; then branch=$(git -C \"$cwd\" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C \"$cwd\" --no-optional-locks rev-parse --short HEAD 2>/dev/null); dirty=$(git -C \"$cwd\" --no-optional-locks diff --quiet 2>/dev/null || echo '*'); staged=$(git -C \"$cwd\" --no-optional-locks diff --cached --quiet 2>/dev/null || echo '+'); untracked=$(git -C \"$cwd\" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | grep -q . && echo '%' || echo ''); [ -n \"$branch\" ] && git_info=$(printf '\\033[33m (%s%s%s%s)\\033[00m' \"$branch\" \"$dirty\" \"$staged\" \"$untracked\"); fi; context_used=$(echo \"$input\" | jq -r '.context_window.used_percentage // empty'); context_info=''; [ -n \"$context_used\" ] && context_info=$(printf '\\033[35m [ctx: %.1f%%]\\033[00m' \"$context_used\"); cost=$(echo \"$input\" | jq -r '.cost.total_cost_usd // empty'); cost_info=''; [ -n \"$cost\" ] && cost_info=$(printf '\\033[36m [$%.4f]\\033[00m' \"$cost\"); printf '\\033[01;32m%s@%s\\033[00m:\\033[01;34m%s\\033[00m%s%s%s' \"$(whoami)\" \"$(hostname -s)\" \"$cwd\" \"$git_info\" \"$context_info\" \"$cost_info\""
  }
}
```

**Why these metrics?**

- **Context usage**: Helps you know when to start a fresh session before hitting limits
- **Session cost**: Awareness of spend, especially useful with expensive models like Opus
- **Git status**: At-a-glance repo state without running `git status`

**Customization:**

The script uses ANSI color codes. To change colors, modify the `\033[XXm` sequences:
- `32` = green, `33` = yellow, `34` = blue, `35` = magenta, `36` = cyan
- `01;XX` = bold variant
