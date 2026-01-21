#!/bin/bash
#
# PreToolUse hook: Require confirmation for git push commands
#
# How it works:
# - Receives JSON on stdin with tool_name and tool_input
# - Checks if it's a Bash command containing "git push"
# - Returns JSON with permissionDecision: "ask" to require confirmation
# - Exit 0 = success (parse stdout for decision)
#

# Read JSON from stdin
input=$(cat)

# Extract tool name and command using jq
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only process Bash tool calls
if [ "$tool_name" != "Bash" ]; then
    exit 0
fi

# Check if command contains "git push"
if echo "$command" | grep -qE '\bgit\s+push\b'; then
    # Return JSON requesting user confirmation
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Git push requires explicit approval"
  }
}
EOF
    exit 0
fi

# All other commands: no decision (use normal permission flow)
exit 0
