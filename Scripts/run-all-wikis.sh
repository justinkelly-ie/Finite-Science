#!/bin/bash
# Master Ecosystem Science Wiki Verification Test Runner
# Executes all 10 satellite science wiki QuickCheck verification test runners sequentially.
# Must be executed within fedora-toolbox-44.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================================================="
echo "🌌 MASTER ECOSYSTEM SCIENCE WIKI VERIFICATION SUITE HARNESS 🌌"
echo "=========================================================================="
echo ""

WIKIS=(
  "Idris2-Epoch-Wiki:Idris2-Epoch-Wiki.ipkg:epoch-wiki"
  "Idris2-Biology-Wiki:Idris2-Biology-Wiki.ipkg:biology-wiki"
  "Idris2-Chemistry-Wiki:Idris2-Chemistry-Wiki.ipkg:chemistry-wiki"
  "Idris2-Cosmology-Wiki:Idris2-Cosmology-Wiki.ipkg:cosmology-wiki"
  "Idris2-Dihedron-Wiki:idris2-Dihedron-Wiki.ipkg:dihedronwiki"
  "Idris2-Electromagnetism-Wiki:Idris2-Electromagnetism-Wiki.ipkg:em-wiki"
  "Idris2-Fields-Wiki:Idris2-Fields-Wiki.ipkg:fields-wiki"
  "Idris2-Hadron-Wiki:Idris2-Hadron-Wiki.ipkg:hadron-wiki"
  "Idris2-Physics-Wiki:Idris2-Physics-Wiki.ipkg:physics-wiki"
  "Idris2-Topology-Wiki:Idris2-Topology-Wiki.ipkg:topology-wiki"
)

PASSED_COUNT=0
TOTAL_COUNT=${#WIKIS[@]}

for entry in "${WIKIS[@]}"; do
  IFS=':' read -r dir ipkg exec <<< "$entry"
  repo_path="$PROJECTS_DIR/$dir"
  
  if [ -d "$repo_path" ]; then
    echo "--------------------------------------------------------------------------"
    echo "▶ Building & Executing $dir ($exec)..."
    echo "--------------------------------------------------------------------------"
    (
      cd "$repo_path"
      /var/home/justin/.local/bin/idris2 --build "$ipkg" > /dev/null
      "./build/exec/$exec"
    )
    echo "✅ $dir Verification PASSED"
    PASSED_COUNT=$((PASSED_COUNT + 1))
    echo ""
  else
    echo "⚠️ Skipping $dir (Directory not found)"
  fi
done

echo "=========================================================================="
echo "✨ MASTER ECOSYSTEM TELEMETRY: $PASSED_COUNT / $TOTAL_COUNT SCIENCE WIKI SUITES PASSED ✨"
echo "=========================================================================="
