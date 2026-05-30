import os
import glob

def refactor():
    src_dir = "/var/home/justin/Projects/Linear-Physi../idris2-Universe/src"
    
    # 1. Replace FiberBundle and Substrate in all files
    for root, _, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".idr"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # We do simple replacements. We need to be careful about imports.
                # Remove `import Math.FiberBundle`
                content = content.replace("import Math.FiberBundle\n", "")
                # Replace the alias
                content = content.replace("FiberBundle", "DenseAMSet (PixelNL Integer, IntPolynumber)")
                content = content.replace("Substrate", "MaxelNL (PixelNL Integer)")
                
                with open(path, 'w') as f:
                    f.write(content)

if __name__ == "__main__":
    refactor()
