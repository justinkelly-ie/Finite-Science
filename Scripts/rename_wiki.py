import os

def replace_in_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except Exception:
        return

    replacements = [
        ("Maths.Properties", "Simplex.Properties"),
        ("Maths.Types", "Simplex.Types"),
        ("Physics.Evolution", "Evolution.Evolution"),
        ("Physics.Adaptive_Cycle_Pipeline", "Evolution.Adaptive_Cycle_Pipeline"),
        ("Physics.Adaptive_Cycle_Findings", "Evolution.Adaptive_Cycle_Findings"),
        ("Physics.Adaptive_Cycle_Chemistry", "Evolution.Adaptive_Cycle_Chemistry"),
        ("Physics.Adaptive_Cycle_Scales", "Evolution.Adaptive_Cycle_Scales"),
        ("Wiki/Maths", "Wiki/Simplex"),
        ("Wiki/Physics/Evolution.md", "Wiki/Evolution/Evolution.md"),
        ("Wiki/Physics/Adaptive_Cycle", "Wiki/Evolution/Adaptive_Cycle")
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

process_dir("Library/Wiki")
process_dir("idris2-QuickCheck/idris2-QuickCheck-tests")
replace_in_file("Linear-Physics.ipkg")
