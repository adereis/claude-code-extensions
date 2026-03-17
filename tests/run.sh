#!/bin/bash
# Test runner: executes all automated test_*.sh files
# Usage: ./tests/run.sh [test_name]  — run all, or a specific test file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
overall_fail=0

if [ -n "$1" ]; then
    # Run specific test
    test_file="$SCRIPT_DIR/test_${1}.sh"
    if [ ! -f "$test_file" ]; then
        test_file="$SCRIPT_DIR/$1"
    fi
    if [ ! -f "$test_file" ]; then
        echo "Test not found: $1"
        exit 1
    fi
    bash "$test_file"
    exit $?
fi

# Run all test files
for test_file in "$SCRIPT_DIR"/test_*.sh; do
    bash "$test_file"
    [ $? -ne 0 ] && overall_fail=1
done

echo ""
if [ "$overall_fail" -eq 0 ]; then
    echo "All test suites passed."
else
    echo "Some tests failed."
fi
exit $overall_fail
