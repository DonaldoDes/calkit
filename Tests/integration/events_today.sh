#!/bin/bash
# Integration test for: calkit events today / events range
# Tests exit codes and output format.
# Note: Calendar permission may not be granted in CI — exit 2 is acceptable.

set -e

BINARY="./calkit"
PASS=0
FAIL=0

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

# --- events today ---

OUTPUT=$($BINARY events today 2>&1) || EXIT=$?
EXIT=${EXIT:-0}

if [ "$EXIT" -eq 0 ] || [ "$EXIT" -eq 2 ]; then
    pass "events today exits 0 or 2 (permission)"
else
    fail "events today exited $EXIT (expected 0 or 2)"
fi

# If permission denied, verify appropriate message
if [ "$EXIT" -eq 2 ]; then
    if echo "$OUTPUT" | grep -q "accès au calendrier refusé"; then
        pass "events today permission-denied message correct"
    else
        fail "events today permission-denied message missing"
    fi
fi

# If permission granted, verify output is non-empty
if [ "$EXIT" -eq 0 ]; then
    if [ -n "$OUTPUT" ]; then
        pass "events today produces output"
    else
        fail "events today produced empty output"
    fi
fi

# --- events today --json ---

OUTPUT=$($BINARY events today --json 2>&1) || EXIT_JSON=$?
EXIT_JSON=${EXIT_JSON:-0}

if [ "$EXIT_JSON" -eq 0 ]; then
    # Validate JSON
    if echo "$OUTPUT" | python3 -m json.tool > /dev/null 2>&1; then
        pass "events today --json produces valid JSON"
    else
        fail "events today --json produces invalid JSON"
    fi
elif [ "$EXIT_JSON" -eq 2 ]; then
    pass "events today --json exits 2 (permission denied, acceptable)"
else
    fail "events today --json exited $EXIT_JSON (expected 0 or 2)"
fi

# --- events range with valid dates ---

OUTPUT=$($BINARY events range 2026-03-16 2026-03-23 2>&1) || EXIT_RANGE=$?
EXIT_RANGE=${EXIT_RANGE:-0}

if [ "$EXIT_RANGE" -eq 0 ] || [ "$EXIT_RANGE" -eq 2 ]; then
    pass "events range exits 0 or 2"
else
    fail "events range exited $EXIT_RANGE (expected 0 or 2)"
fi

# --- events range with missing args ---

OUTPUT=$($BINARY events range 2>&1) || EXIT_MISSING=$?
EXIT_MISSING=${EXIT_MISSING:-0}

if [ "$EXIT_MISSING" -eq 1 ]; then
    pass "events range with missing args exits 1"
else
    fail "events range with missing args exited $EXIT_MISSING (expected 1)"
fi

# --- Report ---

echo ""
echo "=== events integration: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
