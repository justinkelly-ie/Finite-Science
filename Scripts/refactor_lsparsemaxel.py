import re

file_path = "/var/home/justin/Projects/Linear-Physi../idris2-Universe/src/LMath/SparseMaxel.idr"
with open(file_path, "r") as f:
    content = f.read()

# Add import Math.Core
if "import public Math.Core" not in content:
    content = content.replace("import LMath.Twist", "import LMath.Twist\nimport public Math.Core")

# Remove SparseMaxel record definition
content = re.sub(r"\|\|\| A SparseMaxel is a field valuation.*?record SparseMaxel where\n  constructor MkSparseMaxel\n.*?LMath\.Core\.Amplitude\)", "", content, flags=re.DOTALL)

# Rename restrictToPixel to avoid clash
content = content.replace("restrictToPixel : LMath.Core.Geometry", "restrictAmplitudesToPixel : LMath.Core.Geometry")
content = content.replace("restrictToPixel targetGeom maxel =", "restrictAmplitudesToPixel targetGeom maxel =")

# Remove emptySparseMaxel
content = re.sub(r"\|\|\| The empty SparseMaxel.*?emptySparseMaxel = MkSparseMaxel Math\.Multiset\.ZeroM", "", content, flags=re.DOTALL)

# Remove singletonSparseMaxel
content = re.sub(r"\|\|\| A singleton SparseMaxel.*?Math\.Multiset\.fromList \[\(\(geom, amp\), 1\)\]\)", "", content, flags=re.DOTALL)

# Remove superposeStates
content = re.sub(r"\|\|\| Superposition.*?superposeStates \(MkSparseMaxel m1\) \(MkSparseMaxel m2\) = MkSparseMaxel \(Math\.Multiset\.addMultiset m1 m2\)", "", content, flags=re.DOTALL)

# Remove stateLag
content = re.sub(r"\|\|\| The total Leibniz Lag.*?stateLag \(MkSparseMaxel m\) = Math\.Multiset\.multiplicityAll m", "", content, flags=re.DOTALL)

# Remove isSynchronised
content = re.sub(r"\|\|\| Checks that every Geometry.*?in all \(\\g => elem g subNodes\) pipCoords", "", content, flags=re.DOTALL)

# Remove UniverseState record
content = re.sub(r"public export\nrecord UniverseState where\n  constructor MkUniverseState\n  substrate    : LMath\.Core\.Substrate\n  stateVector  : SparseMaxel", "", content, flags=re.DOTALL)

with open(file_path, "w") as f:
    f.write(content)
