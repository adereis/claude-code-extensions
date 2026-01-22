#!/bin/bash
#
# PreToolUse hook: Block writes to /tmp (security risk with predictable names)
#
# Upstream issue: https://github.com/anthropics/claude-code/issues/14085
# This hook may become unnecessary once the issue is resolved.
#
# How it works:
# - Intercepts Write tool calls targeting /tmp/
# - Intercepts Bash commands that write to /tmp/
# - Allows read-only Bash commands (ls, cat, head, tail, etc.)
# - Returns permissionDecision: "deny" (hard block, no user override)
#

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')

deny_with_reason() {
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$1"
  }
}
EOF
    exit 0
}

# Handle Write tool
if [ "$tool_name" = "Write" ]; then
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    # Resolve to absolute path to catch traversal (e.g., ../../../tmp/)
    resolved_path=$(realpath -m "$file_path" 2>/dev/null || echo "$file_path")
    if [[ "$resolved_path" =~ ^/tmp/ ]]; then
        deny_with_reason "Writing to /tmp is blocked (predictable names are a security risk). Use ~/tmp instead."
    fi
    exit 0
fi

# Handle Bash tool
if [ "$tool_name" = "Bash" ]; then
    command=$(echo "$input" | jq -r '.tool_input.command // ""')

    # Check for /tmp/ references (must be start of path, not embedded like ~/tmp/)
    # Match: space or redirect followed by /tmp/, or ../tmp/ traversal
    if ! echo "$command" | grep -qE '(^|[[:space:]]|[>])/tmp/|\.\./tmp/'; then
        exit 0
    fi

    # Allow read-only commands
    # Pattern: command starts with a read-only tool followed by space/flag and /tmp path
    read_only_pattern='^[[:space:]]*(ls|cat|head|tail|less|more|file|stat|wc|md5sum|sha256sum|sha1sum|xxd|hexdump|strings|readlink|test|\[)([[:space:]]|$)'
    if echo "$command" | grep -qE "$read_only_pattern"; then
        exit 0
    fi

    # Allow rm (cleanup is fine)
    if echo "$command" | grep -qE '^[[:space:]]*rm[[:space:]]'; then
        exit 0
    fi

    # Allow git commands (may mention /tmp in commit messages, not actual writes)
    if echo "$command" | grep -qE '^[[:space:]]*git[[:space:]]'; then
        exit 0
    fi

    # Block commands that likely write to /tmp
    # This catches: redirects (> /tmp, >> /tmp), tee, mktemp, touch, cp, mv, etc.
    deny_with_reason "Writing to /tmp is blocked (predictable names are a security risk). Use ~/tmp instead."
fi

exit 0
