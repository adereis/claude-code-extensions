#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
SCRIPT="$SCRIPT_DIR/../settings/statusline.sh"

test_begin "outputs user@host"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"cost":{}}'
assert_output_contains "$(whoami)@$(hostname -s)"

test_begin "outputs current directory from input"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"/home/testuser/project"},"context_window":{},"cost":{}}'
assert_output_contains "/home/testuser/project"

test_begin "shows context percentage when provided"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{"used_percentage":42.5},"cost":{}}'
assert_output_contains "42.5%"

test_begin "shows cost when provided"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"cost":{"total_cost_usd":1.2345}}'
assert_output_contains '$1.2345'

test_begin "shows git branch in a git repo"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$SCRIPT_DIR/.."'"},"context_window":{},"cost":{}}'
assert_output_contains "main"

test_summary "statusline"
