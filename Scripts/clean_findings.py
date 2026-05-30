import os
import re

directory = '/var/home/justin/Projects/Linear-Physi../idris2-Universe/src/Physics/Findings'

for file in os.listdir(directory):
    if file.endswith('.idr'):
        path = os.path.join(directory, file)
        with open(path, 'r') as f:
            content = f.read()
            
        new_content = re.sub(r'Baryon\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+', 'Baryon', content)
        new_content = re.sub(r'Meson\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+', 'Meson', new_content)
        
        if new_content != content:
            with open(path, 'w') as f:
                f.write(new_content)
            print(f"Cleaned {path}")
