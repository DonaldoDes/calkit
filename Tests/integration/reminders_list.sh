#!/bin/bash
# Integration tests — calkit reminders list (US-009)

set -e

BINARY="./calkit"

echo "=== Integration: reminders list ==="

# Test 1: list returns exit code 0
$BINARY reminders list > /dev/null 2>&1 && echo "✓ reminders list exits 0" || { echo "✗ reminders list failed"; exit 1; }

# Test 2: --json returns valid JSON
OUTPUT=$($BINARY reminders list --json 2>&1)
echo "$OUTPUT" | python3 -c "import sys, json; json.load(sys.stdin)" > /dev/null 2>&1 && echo "✓ --json produces valid JSON" || { echo "✗ --json output is not valid JSON"; exit 1; }

# Test 3: --completed flag accepted
$BINARY reminders list --completed > /dev/null 2>&1 && echo "✓ --completed exits 0" || { echo "✗ --completed failed"; exit 1; }

# Test 4: --help returns exit code 0
$BINARY reminders list --help > /dev/null 2>&1 && echo "✓ --help exits 0" || { echo "✗ --help failed"; exit 1; }

# Test 5: unknown list returns exit code 3
if $BINARY reminders list --list "ListeQuiNExistePas123456" > /dev/null 2>&1; then
  echo "✗ Unknown list should exit non-zero"; exit 1
else
  echo "✓ Unknown list exits non-zero"
fi

echo "=== All reminders list tests passed ==="
