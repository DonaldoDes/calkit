#!/bin/bash
# Integration test for: calkit events create
# Permission-aware: graceful in permission-denied mode

BINARY="./calkit"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

echo "=== events create integration tests ==="

# Test 1: Missing arguments should exit 1
$BINARY events create 2>/dev/null
if [ $? -eq 1 ]; then
    pass "no args exits 1"
else
    fail "no args should exit 1"
fi

# Test 2: Missing --start should exit 1
$BINARY events create "Test" --end 2026-03-20T15:00:00 2>/dev/null
if [ $? -eq 1 ]; then
    pass "missing --start exits 1"
else
    fail "missing --start should exit 1"
fi

# Test 3: Missing --end should exit 1
$BINARY events create "Test" --start 2026-03-20T14:00:00 2>/dev/null
if [ $? -eq 1 ]; then
    pass "missing --end exits 1"
else
    fail "missing --end should exit 1"
fi

# Test 4: Invalid date should exit 1
$BINARY events create "Test" --start "not-a-date" --end 2026-03-20T15:00:00 2>/dev/null
if [ $? -eq 1 ]; then
    pass "invalid date exits 1"
else
    fail "invalid date should exit 1"
fi

# Test 5: --help should exit 0
$BINARY events create --help 2>/dev/null
if [ $? -eq 0 ]; then
    pass "create --help exits 0"
else
    fail "create --help should exit 0"
fi

# Test 6: Valid create (permission-dependent)
OUTPUT=$($BINARY events create "calkit-test-event" --start 2026-12-31T23:00:00 --end 2026-12-31T23:30:00 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    if echo "$OUTPUT" | grep -q "calkit-test-event"; then
        pass "create event succeeds with correct output"
    else
        fail "create event output missing title"
    fi
    # Clean up: extract ID and delete
    EVENT_ID=$(echo "$OUTPUT" | grep "ID" | awk '{print $NF}')
    if [ -n "$EVENT_ID" ]; then
        echo "  (cleanup: created event $EVENT_ID — manual deletion may be needed)"
    fi
elif [ $EXIT_CODE -eq 2 ]; then
    pass "create event exits 2 (permission denied — expected in CI)"
else
    fail "create event unexpected exit code: $EXIT_CODE"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
