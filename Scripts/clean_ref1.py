import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    new_lines = [line for line in lines if line.strip() != 'import public Data.Linear.Ref1']
    
    if len(lines) != len(new_lines):
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f"Cleaned {filepath}")

for root, _, files in os.walk('/var/home/justin/Projects/Linear-Physi../idris2-Universe/src'):
    for file in files:
        if file.endswith('.idr'):
            process_file(os.path.join(root, file))
