#!/bin/bash
# Statusline script for Claude Code
# Shows: user@host:cwd (git-branch*+%) [ctx: X%] [$Y.YYYY]
#
# Git indicators:
#   * = uncommitted changes (dirty)
#   + = staged changes
#   % = untracked files
#
# Usage: Configure in settings.json with:
#   "statusLine": { "type": "command", "command": "~/.claude/settings/statusline.sh" }

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Git info: branch + status indicators
git_info=''
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
          || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    dirty=$(git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || echo '*')
    staged=$(git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || echo '+')
    untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | grep -q . && echo '%' || echo '')
    [ -n "$branch" ] && git_info=$(printf '\033[33m (%s%s%s%s)\033[00m' "$branch" "$dirty" "$staged" "$untracked")
fi

# Context window usage
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_info=''
[ -n "$context_used" ] && context_info=$(printf '\033[35m [ctx: %.1f%%]\033[00m' "$context_used")

# Session cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost_info=''
[ -n "$cost" ] && cost_info=$(printf '\033[36m [$%.4f]\033[00m' "$cost")

# Output: user@host:cwd (branch*+%) [ctx: X%] [$Y.YYYY]
printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m%s%s%s' \
    "$(whoami)" "$(hostname -s)" "$cwd" "$git_info" "$context_info" "$cost_info"
