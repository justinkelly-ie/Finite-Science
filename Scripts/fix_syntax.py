import os
import glob

def refactor():
    src_dir = "/var/home/justin/Projects/Linear-Physi../idris2-Universe/src"
    
    for root, _, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".idr"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Fix implementation parens
                content = content.replace(
                    "implementation CalculatesMassRatio DenseAMSet (PixelNL Integer, IntPolynumber)",
                    "implementation CalculatesMassRatio (DenseAMSet (PixelNL Integer, IntPolynumber))"
                )
                content = content.replace(
                    "implementation ConservesInformation DenseAMSet (PixelNL Integer, IntPolynumber)",
                    "implementation ConservesInformation (DenseAMSet (PixelNL Integer, IntPolynumber))"
                )
                content = content.replace(
                    "implementation ConservesEnergy DenseAMSet (PixelNL Integer, IntPolynumber) DenseAMSet (PixelNL Integer, IntPolynumber)",
                    "implementation ConservesEnergy (DenseAMSet (PixelNL Integer, IntPolynumber)) (DenseAMSet (PixelNL Integer, IntPolynumber))"
                )
                content = content.replace(
                    "implementation ObeysPauliExclusion DenseAMSet (PixelNL Integer, IntPolynumber)",
                    "implementation ObeysPauliExclusion (DenseAMSet (PixelNL Integer, IntPolynumber))"
                )

                # Fix missing CosmicState import
                if "DarkPlusMatter" in content or "Flavor" in content or "flavorMetric" in content:
                    if "import Physics.Evolution.CosmicState" not in content and "module Physics.Evolution.CosmicState" not in content:
                        content = content.replace("import Math.DenseAMSet\n", "import Math.DenseAMSet\nimport Physics.Evolution.CosmicState\n")
                        # If Math.DenseAMSet wasn't imported for some reason
                        if "import Math.DenseAMSet" not in content:
                            content = "import Physics.Evolution.CosmicState\n" + content
                
                with open(path, 'w') as f:
                    f.write(content)

if __name__ == "__main__":
    refactor()
