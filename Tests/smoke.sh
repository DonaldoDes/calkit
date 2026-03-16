#!/bin/bash
# Smoke tests — calkit US-001

set -e

BINARY="./calkit"

echo "=== Smoke Tests calkit ==="

# Test 1: binaire compilé existe
[ -f "$BINARY" ] && echo "✓ Binary exists" || { echo "✗ Binary not found"; exit 1; }

# Test 2: --help retourne exit code 0
$BINARY --help > /dev/null 2>&1 && echo "✓ --help exits 0" || { echo "✗ --help failed"; exit 1; }

# Test 3: -h retourne exit code 0
$BINARY -h > /dev/null 2>&1 && echo "✓ -h exits 0" || { echo "✗ -h failed"; exit 1; }

# Test 4: aucun argument retourne exit code 0 (affiche help)
$BINARY > /dev/null 2>&1 && echo "✓ No args exits 0" || { echo "✗ No args should exit 0"; exit 1; }

# Test 5: argument inconnu retourne exit code 1
if $BINARY --unknown-arg > /dev/null 2>&1; then
  echo "✗ Unknown arg should exit 1"; exit 1
else
  echo "✓ Unknown arg exits 1"
fi

# Test 6: help domaine calendars
$BINARY calendars --help > /dev/null 2>&1 && echo "✓ calendars --help exits 0" || { echo "✗ calendars --help failed"; exit 1; }

# Test 7: help domaine events
$BINARY events --help > /dev/null 2>&1 && echo "✓ events --help exits 0" || { echo "✗ events --help failed"; exit 1; }

# Test 8: help domaine reminders
$BINARY reminders --help > /dev/null 2>&1 && echo "✓ reminders --help exits 0" || { echo "✗ reminders --help failed"; exit 1; }

# Test 9: domaine inconnu retourne exit code 1
if $BINARY foobar > /dev/null 2>&1; then
  echo "✗ Unknown domain should exit 1"; exit 1
else
  echo "✓ Unknown domain exits 1"
fi

# Test 10: commande stub retourne exit code 1 (pas encore implémentée)
if $BINARY events today > /dev/null 2>&1; then
  echo "✗ Stub command should exit 1"; exit 1
else
  echo "✓ Stub command exits 1"
fi

echo ""
echo "=== All smoke tests passed ==="
