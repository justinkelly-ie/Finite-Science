import os
import re

directory = '/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src/Physics/Particles'

record_pattern = re.compile(r'record\s+([A-Za-z0-9_]+)\s+tree\s+where')
proof_pattern = re.compile(r'\s*0\s+is[A-Za-z0-9_]+\s*:\s*dimensions\s*\([^)]*\)\s*=\s*\d+\n')

for file in os.listdir(directory):
    if file.endswith('.idr'):
        path = os.path.join(directory, file)
        with open(path, 'r') as f:
            content = f.read()
            
        new_content = record_pattern.sub(r'record \1 where', content)
        new_content = proof_pattern.sub('\n', new_content)
        
        if new_content != content:
            with open(path, 'w') as f:
                f.write(new_content)
            print(f"Cleaned {path}")
