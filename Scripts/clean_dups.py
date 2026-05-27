import os

src_dir = "/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src"
for root, _, files in os.walk(src_dir):
    for file in files:
        if file.endswith(".idr") and file != "Cycle.idr":
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            if "-- LINEAR DEFS --" in content:
                content = content.split("-- LINEAR DEFS --")[0]
                with open(path, "w") as f:
                    f.write(content)
                print(f"Stripped {file}")
