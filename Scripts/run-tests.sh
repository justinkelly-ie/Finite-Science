#!/bin/bash
# Run all QuickCheck tests for the LUniverse project
# Usage: ./run-tests.sh
#
# This script must be run inside the Fedora toolbox:
#   toolbox run -c fedora-toolbox-44 ./run-tests.sh

set -e

cd "$(dirname "$0")/.."

echo "╔══════════════════════════════════════════╗"
echo "║   LUniverse QuickCheck Test Suite        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Build the main library
echo "▶ Building idris2-Universe..."
(cd ../idris2-Universe && pack build idris2-LUniverse.ipkg 2>&1)
echo "  ✅ idris2-Universe module"
echo ""

# Step 2: Run Unified Tests
echo "▶ Running Unified Linear-Physics Test Harness (Wiki output)..."
(cd ../idris2-Universe-Wiki && pack build idris2-Universe-Wiki.ipkg 2>&1 && ./build/exec/luniverse 2>&1)
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║   All tests complete                     ║"
echo "╚══════════════════════════════════════════╝"
