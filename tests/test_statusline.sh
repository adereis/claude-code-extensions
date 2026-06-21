#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_helper.sh"
SCRIPT="$SCRIPT_DIR/../settings/statusline.sh"

test_begin "outputs current directory from input"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"/home/testuser/project"},"context_window":{},"cost":{}}'
assert_output_contains "/home/testuser/project"

test_begin "abbreviates home directory to ~"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$HOME"'/myproj"},"context_window":{},"cost":{}}'
assert_output_contains "~/myproj"

test_begin "shows context percentage, formatted to whole percent"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{"used_percentage":42.4},"cost":{}}'
assert_output_contains "42% used"

test_begin "shows quota from 5-hour rate limit (subscription)"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"rate_limits":{"five_hour":{"used_percentage":73}},"cost":{}}'
assert_output_contains "73% used"

test_begin "shows cost in its own column"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"cost":{"total_cost_usd":1.2345}}'
assert_output_contains '$1.2345'

test_begin "shows cost alongside quota on subscription"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"rate_limits":{"five_hour":{"used_percentage":73}},"cost":{"total_cost_usd":1.2345}}'
assert_output_contains '$1.2345'

test_begin "abbreviates vim mode to three letters"
run_hook "$SCRIPT" '{"vim":{"mode":"NORMAL"},"workspace":{"current_dir":"'"$PWD"'"},"context_window":{},"cost":{}}'
assert_output_contains '\[NOR\]'

test_begin "shows git branch in a git repo"
run_hook "$SCRIPT" '{"workspace":{"current_dir":"'"$SCRIPT_DIR/.."'"},"context_window":{},"cost":{}}'
assert_output_contains "main"

test_summary "statusline"
