#!/bin/bash
# Integration tests — calkit reminders create/complete/delete (US-010, US-011, US-012)

set -e

BINARY="./calkit"

echo "=== Integration: reminders CRUD ==="

# Test 1: create a test reminder
CREATE_OUTPUT=$($BINARY reminders create "Test calkit CRUD" --json 2>&1)
REMINDER_ID=$(echo "$CREATE_OUTPUT" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

if [ -z "$REMINDER_ID" ]; then
  echo "✗ Create failed — could not extract ID"
  echo "Output: $CREATE_OUTPUT"
  exit 1
fi
echo "✓ reminders create succeeded (id: $REMINDER_ID)"

# Test 2: complete the reminder
$BINARY reminders complete "$REMINDER_ID" > /dev/null 2>&1 && echo "✓ reminders complete succeeded" || { echo "✗ reminders complete failed"; exit 1; }

# Test 3: delete the reminder
$BINARY reminders delete "$REMINDER_ID" > /dev/null 2>&1 && echo "✓ reminders delete succeeded" || { echo "✗ reminders delete failed"; exit 1; }

# Test 4: delete non-existent reminder returns exit code 3
if $BINARY reminders delete "id-qui-nexiste-pas-123" > /dev/null 2>&1; then
  echo "✗ Delete of non-existent should exit non-zero"; exit 1
else
  echo "✓ Delete non-existent exits non-zero"
fi

# Test 5: complete non-existent reminder returns exit code 3
if $BINARY reminders complete "id-qui-nexiste-pas-123" > /dev/null 2>&1; then
  echo "✗ Complete of non-existent should exit non-zero"; exit 1
else
  echo "✓ Complete non-existent exits non-zero"
fi

# Test 6: create --help
$BINARY reminders create --help > /dev/null 2>&1 && echo "✓ create --help exits 0" || { echo "✗ create --help failed"; exit 1; }

# Test 7: complete --help
$BINARY reminders complete --help > /dev/null 2>&1 && echo "✓ complete --help exits 0" || { echo "✗ complete --help failed"; exit 1; }

# Test 8: delete --help
$BINARY reminders delete --help > /dev/null 2>&1 && echo "✓ delete --help exits 0" || { echo "✗ delete --help failed"; exit 1; }

echo "=== All reminders CRUD tests passed ==="
