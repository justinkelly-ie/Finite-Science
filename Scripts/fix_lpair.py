import os

def refactor():
    src_dir = "/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src"
    for root, _, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".idr"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                content = content.replace("LPair Bool DenseAMSet (PixelNL Integer, IntPolynumber)", "LPair Bool (DenseAMSet (PixelNL Integer, IntPolynumber))")
                
                with open(path, 'w') as f:
                    f.write(content)

if __name__ == "__main__":
    refactor()
