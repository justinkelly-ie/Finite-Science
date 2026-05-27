import os
import re

src_dir = "src"
modules = []
for root, _, files in os.walk(src_dir):
    for f in files:
        if f.endswith(".idr"):
            rel_path = os.path.relpath(os.path.join(root, f), src_dir)
            mod_name = rel_path.replace("/", ".").replace(".idr", "")
            modules.append(mod_name)

modules_str = ", ".join(sorted(modules))

with open("idris2-LUniverse.ipkg", "r") as f:
    content = f.read()

# Replace modules = ...
content = re.sub(r"^modules =.*$", f"modules = {modules_str}", content, flags=re.MULTILINE)

with open("idris2-LUniverse.ipkg", "w") as f:
    f.write(content)
