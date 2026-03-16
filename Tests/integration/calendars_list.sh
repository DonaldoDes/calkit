#!/bin/bash
# Integration tests — calkit calendars list (US-002)
# Note: If calendar permission is not granted, exit code 2 is expected.
# These tests verify behavior in BOTH scenarios.

BINARY="./calkit"

echo "=== Integration Tests: calendars list ==="

# Test 1: calendars list exits 0 (granted) or 2 (denied) — never 1
EXIT_CODE=0
$BINARY calendars list > /dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] || [ "$EXIT_CODE" -eq 2 ]; then
  echo "✓ calendars list exits $EXIT_CODE (valid)"
else
  echo "✗ calendars list exited $EXIT_CODE (expected 0 or 2)"; exit 1
fi

# If permission denied, skip output-dependent tests
if [ "$EXIT_CODE" -eq 2 ]; then
  echo "⚠ Calendar permission denied — skipping output tests"
  echo "  Grant access in System Settings > Privacy > Calendars to run full suite"

  # Still test --json with permission denied
  EXIT_CODE_JSON=0
  $BINARY calendars list --json > /dev/null 2>&1 || EXIT_CODE_JSON=$?
  [ "$EXIT_CODE_JSON" -eq 2 ] && echo "✓ calendars list --json exits 2 (permission denied)" || { echo "✗ --json should also exit 2"; exit 1; }

  # Test help
  HELP_OUTPUT=$($BINARY calendars --help 2>/dev/null)
  echo "$HELP_OUTPUT" | grep -qi 'list' && echo "✓ calendars --help mentions list" || { echo "✗ calendars --help should mention list"; exit 1; }

  echo ""
  echo "=== Integration tests passed (permission-denied mode) ==="
  exit 0
fi

# === Permission granted path ===

# Test 2: calendars list produces non-empty output
OUTPUT=$($BINARY calendars list 2>/dev/null)
[ -n "$OUTPUT" ] && echo "✓ calendars list has output" || { echo "✗ calendars list output is empty"; exit 1; }

# Test 3: calendars list output contains brackets (source column)
echo "$OUTPUT" | grep -q '\[' && echo "✓ output contains source brackets" || { echo "✗ output missing source brackets"; exit 1; }

# Test 4: calendars list --json exits 0
$BINARY calendars list --json > /dev/null 2>&1 && echo "✓ calendars list --json exits 0" || { echo "✗ calendars list --json should exit 0"; exit 1; }

# Test 5: calendars list --json produces valid JSON
JSON_OUTPUT=$($BINARY calendars list --json 2>/dev/null)
echo "$JSON_OUTPUT" | python3 -m json.tool > /dev/null 2>&1 && echo "✓ JSON output is valid" || { echo "✗ JSON output is invalid"; exit 1; }

# Test 6: JSON output is an array
echo "$JSON_OUTPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); assert isinstance(data, list)" 2>/dev/null && echo "✓ JSON output is an array" || { echo "✗ JSON output should be an array"; exit 1; }

# Test 7: JSON entries have required fields
echo "$JSON_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if len(data) > 0:
    entry = data[0]
    assert 'id' in entry, 'missing id'
    assert 'title' in entry, 'missing title'
    assert 'source' in entry, 'missing source'
    assert 'color' in entry, 'missing color'
    print('has entries with required fields')
else:
    print('no calendars found (empty array)')
" 2>/dev/null && echo "✓ JSON entries have required fields" || { echo "✗ JSON entries missing fields"; exit 1; }

# Test 8: calendars --help mentions list
HELP_OUTPUT=$($BINARY calendars --help 2>/dev/null)
echo "$HELP_OUTPUT" | grep -qi 'list' && echo "✓ calendars --help mentions list" || { echo "✗ calendars --help should mention list"; exit 1; }

echo ""
echo "=== All calendars list integration tests passed ==="
