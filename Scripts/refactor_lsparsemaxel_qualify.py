import re

file_path = "/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src/LMath/SparseMaxel.idr"
with open(file_path, "r") as f:
    content = f.read()

content = content.replace(" SparseMaxel ", " Math.Core.SparseMaxel ")
content = content.replace(" SparseMaxel\n", " Math.Core.SparseMaxel\n")
content = content.replace("(SparseMaxel ", "(Math.Core.SparseMaxel ")

content = content.replace(" UniverseState ", " Math.Core.UniverseState ")
content = content.replace(" UniverseState\n", " Math.Core.UniverseState\n")
content = content.replace("(UniverseState ", "(Math.Core.UniverseState ")

content = content.replace(" MkSparseMaxel ", " Math.Core.MkSparseMaxel ")
content = content.replace("(MkSparseMaxel ", "(Math.Core.MkSparseMaxel ")

content = content.replace(" MkUniverseState ", " Math.Core.MkUniverseState ")
content = content.replace("(MkUniverseState ", "(Math.Core.MkUniverseState ")

content = content.replace(" maxelMap ", " Math.Core.maxelMap ")
content = content.replace("(maxelMap ", "(Math.Core.maxelMap ")

with open(file_path, "w") as f:
    f.write(content)
