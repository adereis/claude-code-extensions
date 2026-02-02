#!/bin/bash
#
# PreToolUse hook: Force analysis before editing test files
#
# Problem this solves:
# When tests fail, it's tempting to "fix the tests" without analyzing WHY
# they failed. Often the tests are correct and the code is incomplete
# (e.g., backporting only part of a feature).
#
# How it works:
# - Intercepts Edit tool calls targeting test files
# - Injects a structured analysis prompt before proceeding
# - Uses additionalContext to add context Claude sees before the edit
#

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')

# Only care about Edit tool
if [ "$tool_name" != "Edit" ]; then
    exit 0
fi

file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
filename=$(basename "$file_path")
dirname=$(dirname "$file_path")

# Detect test files by common patterns
is_test_file=false

# Filename patterns
case "$filename" in
    test_*|*_test.*|*_test_*|*Test.*|*Tests.*|*.test.*|*.spec.*)
        is_test_file=true
        ;;
esac

# Directory patterns (test/, tests/, __tests__/, spec/)
case "$dirname" in
    */test/*|*/tests/*|*/__tests__/*|*/spec/*|test|tests|__tests__|spec)
        is_test_file=true
        ;;
esac

if [ "$is_test_file" = false ]; then
    exit 0
fi

# Log for debugging (verify hook fired)
echo "$(date '+%Y-%m-%d %H:%M:%S') test-edit-guard: $file_path" >> ~/tmp/hook-debug.log

# Inject analysis prompt via additionalContext (shown after edit executes)
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "TEST FILE EDITED: Before continuing, verify this was the right call.\n\nCommon mistake: \"fixing\" tests when the code is actually incomplete (e.g., partial backport, missing dependency). If the original test expectation was correct, revert your edit and discuss with the user or fix the code instead."
  }
}
EOF
