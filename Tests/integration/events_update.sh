#!/bin/bash
# Integration tests for `calkit events update`
# Permission-aware: skips EventKit tests if access is denied.

set -uo pipefail

BINARY="./calkit"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Integration: events update ==="

# --- CLI-level tests (no EventKit needed) ---

# No args -> exit 1 + help text
CODE=0
OUTPUT=$($BINARY events update 2>&1) || CODE=$?
if [ "$CODE" -eq 1 ] && echo "$OUTPUT" | grep -q "Usage:"; then
    pass "no args -> exit 1 + help"
else
    fail "no args -> expected exit 1 + help (got exit $CODE)"
fi

# ID only, no fields -> exit 1
CODE=0
OUTPUT=$($BINARY events update abc123 2>&1) || CODE=$?
if [ "$CODE" -eq 1 ] && echo "$OUTPUT" | grep -qi "champ"; then
    pass "id only, no fields -> exit 1"
else
    fail "id only, no fields -> expected exit 1 (got exit $CODE)"
fi

# --help -> exit 0
CODE=0
OUTPUT=$($BINARY events update --help 2>&1) || CODE=$?
if [ "$CODE" -eq 0 ] && echo "$OUTPUT" | grep -q "Modifier"; then
    pass "--help -> exit 0"
else
    fail "--help -> expected exit 0 (got exit $CODE)"
fi

# Invalid date -> exit 1
CODE=0
OUTPUT=$($BINARY events update abc123 --start not-a-date 2>&1) || CODE=$?
if [ "$CODE" -eq 1 ] && echo "$OUTPUT" | grep -qi "invalide"; then
    pass "invalid date -> exit 1"
else
    fail "invalid date -> expected exit 1 (got exit $CODE)"
fi

# --- EventKit tests (permission-aware) ---

# Check if calendar access is granted by trying a read operation
if $BINARY events today > /dev/null 2>&1; then
    # Unknown ID -> exit 3
    CODE=0
    OUTPUT=$($BINARY events update NONEXISTENT_ID_12345 --title "Test" 2>&1) || CODE=$?
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
echo "=== events update integration OK ==="
