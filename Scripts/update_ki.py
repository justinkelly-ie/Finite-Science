import os

def replace_in_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception:
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
        ("src/Math/Twist", "src/Simplex/Twist"),
        ("Linear-Physics", "Finite-Science"),
        ("Substrate", "Multiset (Geometry, Geometry)"),
        ("SparseMaxel", "Multiset (Geometry, Amplitude)")
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
            if file.endswith('.json') or file.endswith('.md'):
                replace_in_file(os.path.join(root, file))

process_dir("/var/home/justin/.gemini/antigravity-ide/knowledge")
