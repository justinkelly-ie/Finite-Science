#!/bin/bash
# Push all Natural Science sibling repositories cleanly
# Usage: ./Scripts/push-all.sh

set -e

# Colors for premium CLI presentation
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}╔══════════════════════════════════════════╗"
echo -e "║   Natural Science Git Sync Orchestrator  ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
echo ""

# The list of directories to synchronize (relative to parent of Scripts)
REPOS=(
  "Finite-Science"
  "idris2-LUniverse"
  "idris2-Universe-Wiki"
  "idris2-QuickCheck"
  "idris2-Multiset"
  "idris2-Chromogeometry"
)

# Parent workspace directory
cd "$(dirname "$0")/../.."

RESULTS=()

for REPO in "${REPOS[@]}"; do
  echo -e "${BOLD}▶ Syncing repo: ${REPO}...${NC}"
  
  if [ ! -d "$REPO" ]; then
    echo -e "  ${RED}❌ Directory not found: ${REPO}${NC}"
    RESULTS+=("${REPO}: ❌ NOT FOUND")
    echo ""
    continue
  fi

  (
    cd "$REPO"
    
    # Ensure branch is main
    BRANCH=$(git branch --show-current || echo "main")
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
      echo "  • Staging uncommitted changes (e.g. README.md, .gitattributes)..."
      git add .
      git commit -m "Stabilized repository layout: synced README and metadata attributes" || true
    fi

    # Push to remote
    echo "  • Pushing changes to remote branch: ${BRANCH}..."
    if git push origin "$BRANCH" 2>&1; then
      echo -e "  ${GREEN}✅ Pushed successfully!${NC}"
      exit 0
    else
      echo -e "  ${RED}❌ Push failed (Authentication or remote issue)${NC}"
      exit 1
    fi
  ) && STATE=$? || STATE=$?

  if [ $STATE -eq 0 ]; then
    RESULTS+=("${REPO}: ✅ SUCCESS")
  else
    RESULTS+=("${REPO}: ❌ FAILED (Requires interactive terminal push)")
  fi
  echo ""
done

echo -e "${BOLD}╔══════════════════════════════════════════╗"
echo -e "║   Sync Summary                           ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
for RESULT in "${RESULTS[@]}"; do
  echo -e "  ${RESULT}"
done
echo ""
