import os

for root, _, files in os.walk("/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src"):
    for file in files:
        if file.endswith(".idr"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            if "-- LINEAR DEFS --" in content:
                parts = content.split("-- LINEAR DEFS --")
                top = parts[0].strip()
                bottom = parts[1].strip()
                
                # strip out %default total and imports from top to compare logic
                import re
                top_logic = re.sub(r"^import.*\n", "", top, flags=re.MULTILINE)
                top_logic = re.sub(r"^%default.*\n", "", top_logic, flags=re.MULTILINE)
                top_logic = re.sub(r"^module.*\n", "", top_logic, flags=re.MULTILINE)
                top_logic = top_logic.strip()
                
                bottom_logic = bottom.strip()
                
                if top_logic == bottom_logic:
                    print(f"Exact Duplicate: {file}")
                    with open(path, "w") as f:
                        f.write(parts[0])
                else:
                    print(f"Differs: {file}")
