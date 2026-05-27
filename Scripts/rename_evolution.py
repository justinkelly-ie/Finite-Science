import os
import sys

def replace_in_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception as e:
        return

    replacements = [
        ("Physics.Evolution.Gate", "Evolution.Gate"),
        ("Physics.Evolution.Cycle", "Evolution.Cycle"),
        ("Physics.Evolution.Clock", "Evolution.Clock"),
        ("Physics.Evolution.Identity", "Evolution.Identity"),
        ("Physics.Evolution.Init", "Evolution.Init"),
        ("Physics.Evolution.State", "Evolution.State"),
        ("Physics.Evolution.Transform", "Evolution.Transform"),
        ("Physics.Evolution", "Evolution"), # Catch-all for module/import physics.evolution
        ("src/Physics/Evolution", "src/Evolution"),
        ("Physics/Evolution/", "Evolution/") # Architecture diagrams
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
            if file.endswith('.idr') or file.endswith('.md') or file.endswith('.ipkg'):
                replace_in_file(os.path.join(root, file))

process_dir("idris2-LUniverse")
process_dir("Library/Wiki")
process_dir("idris2-QuickCheck/idris2-QuickCheck-tests")
process_dir("Scripts")
