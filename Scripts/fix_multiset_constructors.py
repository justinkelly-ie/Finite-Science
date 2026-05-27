import os
import re

base_dir = "/var/home/justin/Projects/Linear-Physics"
repos = [
    "idris2-LUniverse",
    "idris2-Multiset-Advanced"
]

for repo in repos:
    repo_dir = os.path.join(base_dir, repo)
    for root, dirs, files in os.walk(repo_dir):
        for file in files:
            if file.endswith(".idr"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                if "MkMultiset" not in content:
                    continue
                    
                # Replace MkMultiset [] with ZeroM
                content = content.replace("MkMultiset []", "ZeroM")
                
                # Replace MkMultiset [(x, c)] with AddM x c ZeroM
                # We need to be careful with regex.
                # Pattern: MkMultiset \[\(([^,]+),\s*([^)]+)\)\]
                content = re.sub(r'MkMultiset\s*\[\s*\(\s*([^,]+)\s*,\s*([^)]+)\s*\)\s*\]', r'AddM \1 \2 ZeroM', content)
                
                # Any other MkMultiset usage?
                
                with open(path, 'w') as f:
                    f.write(content)
