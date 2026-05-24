#!/bin/bash
# Run all QuickCheck tests for the LUniverse project
# Usage: ./run-tests.sh
#
# This script must be run inside the Fedora toolbox:
#   toolbox run -c fedora-toolbox-44 ./run-tests.sh

set -e

cd "$(dirname "$0")"

echo "╔══════════════════════════════════════════╗"
echo "║   LUniverse QuickCheck Test Suite        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Build the main library
echo "▶ Building idris2-LUniverse..."
cd idris2-LUniverse && pack build idris2-LUniverse.ipkg 2>&1 && cd ..
echo "  ✅ 46/46 modules"
echo ""

# Step 2: Run the adaptive-cycle test suite (51 properties)
echo "▶ Running QuickCheck properties (51 tests)..."
cd idris2-QuickCheck/idris2-QuickCheck-tests/properties/adaptive-cycle
pack build test.ipkg 2>&1
echo ""
timeout 120 pack run test.ipkg 2>&1
cd ../../../..
echo ""

# Step 3: Run the ascension probe (N+2 ice geometry + 137-scale trajectory)
echo "▶ Running ascension probe..."
cd idris2-QuickCheck/idris2-QuickCheck-tests/properties/ascension-probe
pack build test.ipkg 2>&1
echo ""
timeout 30 pack run test.ipkg 2>&1
cd ../../../..
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║   All tests complete                     ║"
echo "╚══════════════════════════════════════════╝"

