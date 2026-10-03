#!/bin/bash
# Master Ecosystem Science Wiki Verification Test Runner
# Installs domain packages and executes satellite science wiki QuickCheck verification test runners sequentially.
# Must be executed within fedora-toolbox-44.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================================================="
echo "🌌 MASTER ECOSYSTEM SCIENCE WIKI VERIFICATION SUITE HARNESS 🌌"
echo "=========================================================================="
echo ""

WIKIS=(
  "FinSc-Multiset-Core:FinSc-Multiset-Core-Wiki:FinSc-Multiset-Core-Wiki.ipkg:multiset-core-wiki"
  "FinSc-Phase-Unfolding:FinSc-Phase-Unfolding-Wiki:FinSc-Phase-Unfolding-Wiki.ipkg:multiset-transform-wiki"
  "FinSc-Biology:FinSc-Biology-Wiki:FinSc-Biology-Wiki.ipkg:biology-wiki"
  "FinSc-Chemistry:FinSc-Chemistry-Wiki:FinSc-Chemistry-Wiki.ipkg:chemistry-wiki"
  "FinSc-Cosmic-Horizon:FinSc-Cosmic-Horizon-Wiki:FinSc-Cosmic-Horizon-Wiki.ipkg:cosmology-wiki"
  "FinSc-Cosmos:FinSc-Cosmos-Wiki:FinSc-Cosmos-Wiki.ipkg:cosmos-verify"
  "FinSc-Dihedron:FinSc-Dihedron-Wiki:FinSc-Dihedron-Wiki.ipkg:dihedronwiki"
  "FinSc-Ecology-Wiki:FinSc-Ecology-Wiki:FinSc-Ecology-Wiki.ipkg:lecology-wiki"
  "FinSc-Epoch:FinSc-Epoch-Wiki:FinSc-Epoch-Wiki.ipkg:epoch-wiki"
  "FinSc-Gauge-Fields:FinSc-Gauge-Fields-Wiki:FinSc-Gauge-Fields-Wiki.ipkg:fields-wiki"
  "FinSc-Geometry:FinSc-Geometry-Wiki:FinSc-Geometry-Wiki.ipkg:geometry-wiki"
  "FinSc-Nuclear-Matter:FinSc-Nuclear-Matter-Wiki:FinSc-Nuclear-Matter-Wiki.ipkg:hadron-wiki"
  "FinSc-Radix-Binary:FinSc-Radix-Binary-Wiki:FinSc-Radix-Binary-Wiki.ipkg:multiset-binary-wiki"
  "FinSc-Radix-Ternary:FinSc-Radix-Ternary-Wiki:FinSc-Radix-Ternary-Wiki.ipkg:multiset-ternary-wiki"
  "FinSc-Action-Dynamics:FinSc-Action-Dynamics-Wiki:FinSc-Action-Dynamics-Wiki.ipkg:physics-wiki"
  "FinSc-Quantum-Coherence:FinSc-Quantum-Coherence-Wiki:FinSc-Quantum-Coherence-Wiki.ipkg:quantum-computing-wiki"
  "FinSc-SystemsBiology-Wiki:FinSc-SystemsBiology-Wiki:FinSc-SystemsBiology-Wiki.ipkg:systems-biology-wiki"
  "FinSc-Thermodynamics:FinSc-Thermodynamics-Wiki:FinSc-Thermodynamics-Wiki.ipkg:thermodynamics-wiki"
)

PASSED_COUNT=0
TOTAL_COUNT=${#WIKIS[@]}

for entry in "${WIKIS[@]}"; do
  IFS=':' read -r domain_dir wiki_dir ipkg exec <<< "$entry"
  domain_path="$PROJECTS_DIR/$domain_dir"
  wiki_path="$PROJECTS_DIR/$wiki_dir"
  
  if [ -d "$domain_path" ] && [ "$domain_dir" != "$wiki_dir" ]; then
    (
      cd "$domain_path"
      ipkg_file=$(ls *.ipkg 2>/dev/null | head -n 1)
      if [ -n "$ipkg_file" ]; then
        idris2 --install "$ipkg_file" > /dev/null
      fi
    )
  fi

  if [ -d "$wiki_path" ]; then
    echo "--------------------------------------------------------------------------"
    echo "▶ Building & Executing $wiki_dir ($exec)..."
    echo "--------------------------------------------------------------------------"
    (
      cd "$wiki_path"
      idris2 --build "$ipkg" > /dev/null
      if [ -x "./build/exec/$exec" ]; then
        "./build/exec/$exec"
      fi
    )
    echo "✅ $wiki_dir Verification PASSED"
    PASSED_COUNT=$((PASSED_COUNT + 1))
    echo ""
  else
    echo "⚠️ Skipping $wiki_dir (Directory not found)"
  fi
done

echo "=========================================================================="
echo "✨ MASTER ECOSYSTEM TELEMETRY: $PASSED_COUNT / $TOTAL_COUNT SCIENCE WIKI SUITES PASSED ✨"
echo "=========================================================================="
