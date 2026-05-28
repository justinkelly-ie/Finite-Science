#!/bin/bash
set -e

# migrate-repos.sh
# Automates the extraction of idris2-Multiset, idris2-chromogeometry, and idris2-QuickCheck
# into standalone sibling repositories, renames Linear-Physics to Nat-Science,
# and updates pack/git config dynamically.

cd "$(dirname "$0")/.."
PROJECTS_DIR="$(pwd)/.."

echo "▶ Starting Natural Science Multi-Repository Migration..."

# Step 1: Copy folders up to become standalone siblings
for repo in idris2-Multiset idris2-chromogeometry idris2-QuickCheck; do
  if [ -d "$repo" ]; then
    echo "  → Copying $repo to standalone folder at $PROJECTS_DIR/$repo..."
    cp -r "$repo" "$PROJECTS_DIR/"
    
    # Initialize Git in the sibling directory
    echo "  → Initializing git repository in $PROJECTS_DIR/$repo..."
    (
      cd "$PROJECTS_DIR/$repo"
      git init -b main
      git add .
      git commit -m "feat: initial commit of standalone $repo extracted from Linear-Physics"
    )
  else
    echo "  ⚠️ Warning: $repo folder not found in current directory."
  fi
done

# Step 2: Rename Linear-Physics root to Nat-Science
echo "  → Renaming Linear-Physics root to Nat-Science..."
mv "$PROJECTS_DIR/Linear-Physics" "$PROJECTS_DIR/Nat-Science"

# Navigate into the new Nat-Science directory
cd "$PROJECTS_DIR/Nat-Science"

# Step 3: Remove nested dependency folders now that they are standalone siblings
echo "  → Removing legacy nested folders inside Nat-Science..."
rm -rf idris2-Multiset idris2-chromogeometry idris2-QuickCheck

# Step 4: Rename and update IPKG
echo "  → Renaming Linear-Physics.ipkg to Nat-Science.ipkg..."
mv Linear-Physics.ipkg Nat-Science.ipkg
sed -i 's/package Linear-Physics/package Nat-Science/' Nat-Science.ipkg

# Step 5: Update pack.toml in Nat-Science
echo "  → Updating Nat-Science/pack.toml with sibling paths..."
sed -i 's/\[custom.all.Linear-Physics\]/\[custom.all.Nat-Science\]/' pack.toml
sed -i 's/ipkg = "Linear-Physics.ipkg"/ipkg = "Nat-Science.ipkg"/' pack.toml
sed -i 's/path = "idris2-chromogeometry"/path = "..\/idris2-chromogeometry"/' pack.toml
sed -i 's/path = "idris2-Multiset"/path = "..\/idris2-Multiset"/' pack.toml
sed -i 's/path = "idris2-QuickCheck"/path = "..\/idris2-QuickCheck"/' pack.toml

# Step 6: Update test script references
echo "  → Updating Scripts/run-tests.sh..."
sed -i 's/Linear-Physics.ipkg/Nat-Science.ipkg/' Scripts/run-tests.sh

echo "✅ Local multi-repository migration completed successfully!"
echo "Next steps:"
echo "1. On GitHub, rename your 'Linear-Physics' repo to 'Nat-Science'."
echo "2. Locally, run: git remote set-url origin https://github.com/justin/Nat-Science.git"
echo "3. Run your tests in Nat-Science: toolbox run -c fedora-toolbox-44 ./Scripts/run-tests.sh"
