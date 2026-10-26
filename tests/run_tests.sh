#!/bin/sh
# Lumen-OS Test Runner
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== Running Lumen-OS Test Suite ==="
python3 "$DIR/test_system.py"
echo "=== All Tests Passed Successfully! ==="
