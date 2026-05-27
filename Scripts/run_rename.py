import os
import glob

def refactor():
    repos = [
        "idris2-Multiset-Advanced",
        "idris2-LUniverse",
        "idris2-LUniverse-Tests",
        "idris2-Maxel",
        "idris2-chromogeometry"
    ]
    
    # We also need to rename the files!
    # Math.Multiset.idr -> Math.SparseMultiset.idr
    # Math.DenseAMSet.idr -> Math.Multiset.idr
    base_dir = "/var/home/justin/Projects/Linear-Physics"
    
    old_multiset_path = os.path.join(base_dir, "idris2-Multiset-Advanced/src/Math/Multiset.idr")
    sparse_multiset_path = os.path.join(base_dir, "idris2-Multiset-Advanced/src/Math/SparseMultiset.idr")
    
    if os.path.exists(old_multiset_path):
        os.rename(old_multiset_path, sparse_multiset_path)
        
    old_dense_path = os.path.join(base_dir, "idris2-Multiset-Advanced/src/Math/DenseAMSet.idr")
    new_multiset_path = os.path.join(base_dir, "idris2-Multiset-Advanced/src/Math/Multiset.idr")
    
    if os.path.exists(old_dense_path):
        os.rename(old_dense_path, new_multiset_path)

    for repo in repos:
        repo_dir = os.path.join(base_dir, repo)
        for root, dirs, files in os.walk(repo_dir):
            for file in files:
                if file.endswith(".idr") or file.endswith(".ipkg") or file.endswith(".md"):
                    path = os.path.join(root, file)
                    with open(path, 'r') as f:
                        content = f.read()
                    
                    # 1. Math.Multiset -> Math.SparseMultiset
                    # Wait! "Math.Multiset" could be inside "import Math.Multiset".
                    content = content.replace("Math.Multiset", "Math.SparseMultiset")
                    
                    # 2. Math.DenseAMSet -> Math.Multiset
                    content = content.replace("Math.DenseAMSet", "Math.Multiset")
                    
                    # 3. DenseAMSet -> Multiset
                    # Also things like MkDense -> MkMultiset, addDense -> addMultiset, etc.
                    content = content.replace("DenseAMSet", "Multiset")
                    content = content.replace("MkDense", "MkMultiset")
                    content = content.replace("addDense", "addMultiset")
                    content = content.replace("subDense", "subMultiset")
                    content = content.replace("negateDense", "negateMultiset")
                    content = content.replace("scaleDense", "scaleMultiset")
                    content = content.replace("annihilateDense", "annihilateMultiset")
                    content = content.replace("posDense", "posMultiset")
                    content = content.replace("negDense", "negMultiset")
                    
                    # 4. MSet -> SparseMultiset
                    # We have to be careful with word boundaries for MSet so we don't break AMSet
                    import re
                    content = re.sub(r'\bMSet\b', 'SparseMultiset', content)
                    content = re.sub(r'\bMath\.SparseMultiset\b', 'Math.SparseMultiset', content) # redudant
                    
                    with open(path, 'w') as f:
                        f.write(content)

if __name__ == "__main__":
    refactor()
