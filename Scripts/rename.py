import os

def rename_content(path):
    with open(path, 'r') as f:
        content = f.read()

    # Rename modules
    content = content.replace("Math.DenseAMSet", "Math.Multiset")
    content = content.replace("Math.Multiset", "Math.SparseMultiset") # wait! If we do this after, it replaces Math.Multiset! 
    # Proper order:
    # 1. Math.Multiset -> Math.SparseMultiset
    # 2. Math.DenseAMSet -> Math.Multiset
    # 3. DenseAMSet -> Multiset
    # 4. MSet -> SparseMultiset
    pass

