#!/bin/bash
# Integration tests for `calkit events delete`
# Permission-aware: skips EventKit tests if access is denied.

set -uo pipefail

BINARY="./calkit"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Integration: events delete ==="

# --- CLI-level tests (no EventKit needed) ---

# No args -> exit 1 + help text
CODE=0
OUTPUT=$($BINARY events delete 2>&1) || CODE=$?
if [ "$CODE" -eq 1 ] && echo "$OUTPUT" | grep -q "Usage:"; then
    pass "no args -> exit 1 + help"
else
    fail "no args -> expected exit 1 + help (got exit $CODE)"
fi

# --help -> exit 0
CODE=0
OUTPUT=$($BINARY events delete --help 2>&1) || CODE=$?
if [ "$CODE" -eq 0 ] && echo "$OUTPUT" | grep -q "Supprimer"; then
    pass "--help -> exit 0"
else
    fail "--help -> expected exit 0 (got exit $CODE)"
fi

# Invalid span -> exit 1
CODE=0
OUTPUT=$($BINARY events delete abc123 --span allEvents 2>&1) || CODE=$?
if [ "$CODE" -eq 1 ] && echo "$OUTPUT" | grep -qi "span"; then
    pass "invalid span -> exit 1"
else
    fail "invalid span -> expected exit 1 (got exit $CODE)"
fi

# --- EventKit tests (permission-aware) ---

# Check if calendar access is granted by trying a read operation
if $BINARY events today > /dev/null 2>&1; then
    # Unknown ID -> exit 3
    CODE=0
    OUTPUT=$($BINARY events delete NONEXISTENT_ID_12345 2>&1) || CODE=$?
    if [ "$CODE" -eq 3 ] && echo "$OUTPUT" | grep -qi "introuvable"; then
        pass "unknown id -> exit 3"
    else
        fail "unknown id -> expected exit 3 (got exit $CODE)"
    fi
else
    echo "  SKIP: EventKit access not granted -- skipping permission-dependent tests"
fi

# --- Summary ---
echo ""
echo "  Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
echo "=== events delete integration OK ==="
