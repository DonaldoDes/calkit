#!/bin/bash
# Integration tests — calkit reminders lists (US-008)

set -e

BINARY="./calkit"

echo "=== Integration: reminders lists ==="

# Test 1: lists returns exit code 0
$BINARY reminders lists > /dev/null 2>&1 && echo "✓ reminders lists exits 0" || { echo "✗ reminders lists failed"; exit 1; }

# Test 2: --json returns valid JSON
OUTPUT=$($BINARY reminders lists --json 2>&1)
echo "$OUTPUT" | python3 -c "import sys, json; json.load(sys.stdin)" > /dev/null 2>&1 && echo "✓ --json produces valid JSON" || { echo "✗ --json output is not valid JSON"; exit 1; }

# Test 3: --help returns exit code 0
$BINARY reminders lists --help > /dev/null 2>&1 && echo "✓ --help exits 0" || { echo "✗ --help failed"; exit 1; }

echo "=== All reminders lists tests passed ==="
