import os
import re

def process_file(l_path, p_path):
    print(f"Merging {l_path} into {p_path}")
    
    with open(l_path, "r") as f:
        l_content = f.read()
        
    # Extract imports from linear file
    l_imports = set(re.findall(r"^import (?:public )?[\w\.]+", l_content, re.MULTILINE))
    
    # Extract code body (everything after %default total, or just strip module/imports)
    # Safest is to just remove the module declaration and imports.
    body = re.sub(r"^module [\w\.]+\n", "", l_content, flags=re.MULTILINE)
    body = re.sub(r"^import [\w\.]+\n", "", body, flags=re.MULTILINE)
    body = re.sub(r"^import public [\w\.]+\n", "", body, flags=re.MULTILINE)
    body = re.sub(r"^%default total\n", "", body, flags=re.MULTILINE)
    
    if os.path.exists(p_path):
        with open(p_path, "r") as f:
            p_content = f.read()
            
        p_imports = set(re.findall(r"^import (?:public )?[\w\.]+", p_content, re.MULTILINE))
        new_imports = l_imports - p_imports
        new_imports = {i for i in new_imports if not i.endswith(p_path.split("src/")[1].replace("/", ".").replace(".idr", ""))}
        
        # Add Data.Linear.Ref1 if missing
        if "import public Data.Linear.Ref1" not in p_imports and "import Data.Linear.Ref1" not in p_imports:
            new_imports.add("import public Data.Linear.Ref1")
            
        # Insert new imports after module declaration
        mod_decl = re.search(r"^module [\w\.]+\n", p_content, re.MULTILINE)
        if mod_decl:
            insert_pos = mod_decl.end()
            p_content = p_content[:insert_pos] + "\n" + "\n".join(new_imports) + "\n" + p_content[insert_pos:]
            
        # Append body
        p_content += "\n\n-- LINEAR DEFS --\n" + body
        
        with open(p_path, "w") as f:
            f.write(p_content)
            
        os.remove(l_path)
    else:
        # File only exists in linear (like Bridge)
        # Just rename the module inside
        new_mod_name = p_path.split("src/")[1].replace("/", ".").replace(".idr", "")
        body = f"module {new_mod_name}\n\n" + "\n".join(l_imports) + "\n\n%default total\n\n" + body
        os.makedirs(os.path.dirname(p_path), exist_ok=True)
        with open(p_path, "w") as f:
            f.write(body)
        os.remove(l_path)


src_dir = "/var/home/justin/Projects/Linear-Physi../idris2-Universe/src"

for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith(".idr"):
            if "LMath/" in root or "LPhysics/" in root:
                l_path = os.path.join(root, file)
                
                # Special case SparseMaxel -> Core
                if "LMath/SparseMaxel.idr" in l_path:
                    p_path = os.path.join(src_dir, "Math/Core.idr")
                else:
                    p_path = l_path.replace("LMath/", "Math/").replace("LPhysics/", "Physics/")
                    
                process_file(l_path, p_path)

# Cleanup empty dirs
os.system(f"rm -rf {src_dir}/LMath")
os.system(f"rm -rf {src_dir}/LPhysics")

# Global replace of namespaces across ALL files
for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith(".idr"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            content = content.replace("LMath.", "Math.")
            content = content.replace("LPhysics.", "Physics.")
            
            with open(path, "w") as f:
                f.write(content)

