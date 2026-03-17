#!/bin/bash
# Integration test: calkit events search
# Tests basic search behavior and exit codes.
# Note: Calendar permission may not be granted in CI — exit 2 is acceptable.

set -e

BINARY="./calkit"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== events search integration tests ==="

# Missing term → exit 1
OUTPUT=$($BINARY events search 2>&1) || EXIT=$?
EXIT=${EXIT:-0}
if [ "$EXIT" -eq 1 ]; then
    pass "search without term exits 1"
else
    fail "search without term exited $EXIT (expected 1)"
fi

# Search with term → exit 0 or 2 (permission denied acceptable)
EXIT=0
OUTPUT=$($BINARY events search "xyznonexistent12345" 2>&1) || EXIT=$?
if [ "$EXIT" -eq 0 ] || [ "$EXIT" -eq 2 ]; then
    pass "search with term exits 0 or 2 (exit $EXIT)"
else
    fail "search with term exited $EXIT (expected 0 or 2)"
fi

# If permission granted, verify "Aucun résultat" message
if [ "$EXIT" -eq 0 ]; then
    if echo "$OUTPUT" | grep -q "Aucun résultat"; then
        pass "search no-match shows 'Aucun résultat' message"
    else
        fail "search no-match missing 'Aucun résultat' message"
    fi
fi

# Search with --json → exit 0 or 2
OUTPUT=$($BINARY events search "xyznonexistent12345" --json 2>&1) || EXIT_JSON=$?
EXIT_JSON=${EXIT_JSON:-0}
if [ "$EXIT_JSON" -eq 0 ]; then
    if echo "$OUTPUT" | python3 -m json.tool > /dev/null 2>&1; then
        pass "search --json produces valid JSON"
    else
        fail "search --json produces invalid JSON"
    fi
elif [ "$EXIT_JSON" -eq 2 ]; then
    pass "search --json exits 2 (permission denied, acceptable)"
else
    fail "search --json exited $EXIT_JSON (expected 0 or 2)"
fi

# Search with --from/--to → exit 0 or 2
OUTPUT=$($BINARY events search "test" --from 2026-01-01 --to 2026-12-31 2>&1) || EXIT_RANGE=$?
EXIT_RANGE=${EXIT_RANGE:-0}
if [ "$EXIT_RANGE" -eq 0 ] || [ "$EXIT_RANGE" -eq 2 ]; then
    pass "search with date range exits 0 or 2 (exit $EXIT_RANGE)"
else
    fail "search with date range exited $EXIT_RANGE (expected 0 or 2)"
fi

echo ""
echo "=== events search: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
