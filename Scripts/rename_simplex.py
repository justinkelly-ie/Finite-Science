import os
import sys

def replace_in_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception as e:
        return

    replacements = [
        ("Math.Composition", "Simplex.Composition"),
        ("Math.Core", "Simplex.Core"),
        ("Math.DiscreteCalculus", "Simplex.DiscreteCalculus"),
        ("Math.SigmaLinear", "Simplex.SigmaLinear"),
        ("Math.Twist", "Simplex.Twist"),
        ("src/Math/Core", "src/Simplex/Core"),
        ("src/Math/Composition", "src/Simplex/Composition"),
        ("src/Math/DiscreteCalculus", "src/Simplex/DiscreteCalculus"),
        ("src/Math/SigmaLinear", "src/Simplex/SigmaLinear"),
        ("src/Math/Twist", "src/Simplex/Twist")
    ]
    
    new_content = content
    for old, new in replacements:
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.idr') or file.endswith('.md'):
                replace_in_file(os.path.join(root, file))

process_dir("idris2-LUniverse/src")
process_dir("Library/Wiki")
process_dir("idris2-QuickCheck/idris2-QuickCheck-tests")
process_dir("idris2-LUniverse/idris2-LUniverse.ipkg")
