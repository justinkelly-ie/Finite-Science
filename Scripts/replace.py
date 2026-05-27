import os

replacements = {
    "LMath.Core.Geometry": "Math.Core.Geometry",
    "LMath.Core.Amplitude": "Math.Core.Amplitude",
    "LMath.Core.Substrate": "Math.Core.Substrate",
    "LMath.Core.emptyAmplitude": "Math.Core.emptyAmplitude",
    "LMath.Core.emptySubstrate": "Math.Core.emptySubstrate",
    "LMath.Core.substrateNodes": "Math.Core.substrateNodes",
    "LMath.Core.mergeSubstrate": "Math.Core.mergeSubstrate",
    "LMath.Core.singleEdge": "Math.Core.singleEdge",
    "LMath.Core.substrateLag": "Math.Core.substrateLag"
}

for root, dirs, files in os.walk("/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src"):
    for file in files:
        if file.endswith(".idr"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            original = content
            for old, new in replacements.items():
                content = content.replace(old, new)
            if content != original:
                with open(path, "w") as f:
                    f.write(content)
                print(f"Updated {path}")
