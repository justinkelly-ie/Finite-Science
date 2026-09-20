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
echo "▶ Building Idris2-Cosmology..."
(cd ../Idris2-Cosmology && /var/home/justin/.local/bin/idris2 --build Idris2-Cosmology.ipkg 2>&1)
echo "  ✅ Idris2-Cosmology module"
echo ""

# Step 2: Run Unified Tests
echo "▶ Running Unified Cosmology Test Harness (Wiki output)..."
(cd ../Idris2-Cosmology-Wiki && /var/home/justin/.local/bin/idris2 --build Idris2-Cosmology-Wiki.ipkg 2>&1 && ./build/exec/cosmology-wiki 2>&1)
echo ""

# Step 3: All tests complete
echo "╔══════════════════════════════════════════╗"
echo "║   All tests complete                     ║"
echo "╚══════════════════════════════════════════╝"
