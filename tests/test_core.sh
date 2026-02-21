#!/bin/bash
# Basic tests for mac-dev-audit
# Run with: ./tests/test_core.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$SCRIPT_DIR/mac-dev-audit"

echo "Running mac-dev-audit tests..."
echo ""

# Test 1: Help flag
echo -n "Test 1: --help flag... "
if $AUDIT --help | grep -q "macOS Dev Audit Tool"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Version flag
echo -n "Test 2: --version flag... "
if $AUDIT --version | grep -q "mac-dev-audit version"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Run disk module
echo -n "Test 3: Disk module runs... "
if $AUDIT --modules disk 2>&1 | grep -q "Disk Usage"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: JSON output valid
echo -n "Test 4: JSON output is valid... "
if $AUDIT --modules disk --json 2>&1 | python3 -m json.tool > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Threshold flag
echo -n "Test 5: --threshold flag... "
if $AUDIT --modules disk --threshold 10 2>&1 | grep -q "Disk Usage"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 6: Invalid module
echo -n "Test 6: Invalid module rejected... "
if $AUDIT --modules invalid 2>&1 | grep -q "Unknown module"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 7: Report file creation
echo -n "Test 7: Report file created... "
REPORT_FILE="/tmp/mac-dev-audit-test-$$.txt"
$AUDIT --modules disk --report "$REPORT_FILE" > /dev/null 2>&1
if [[ -f "$REPORT_FILE" ]]; then
    rm -f "$REPORT_FILE"
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 8: Memory module runs
echo -n "Test 8: Memory module runs... "
if $AUDIT --modules memory 2>&1 | grep -q "Memory Usage"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 9: Processes module runs
echo -n "Test 9: Processes module runs... "
if $AUDIT --modules processes 2>&1 | grep -q "Heavy Processes"; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo ""
echo "All tests passed!"
