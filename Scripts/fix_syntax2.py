import os

def refactor():
    src_dir = "/var/home/justin/Projects/Linear-Physi../idris2-Universe/src"
    for root, _, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".idr"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # If the file starts with "import Physics.Evolution.CosmicState\n", move it down
                if content.startswith("import Physics.Evolution.CosmicState\n"):
                    # Remove it from the top
                    content = content[len("import Physics.Evolution.CosmicState\n"):]
                    # Find the module line and insert it right after
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if line.startswith("module "):
                            lines.insert(i + 1, "")
                            lines.insert(i + 2, "import Physics.Evolution.CosmicState")
                            break
                    content = '\n'.join(lines)
                
                with open(path, 'w') as f:
                    f.write(content)

if __name__ == "__main__":
    refactor()
