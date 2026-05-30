import os
import re

directory = '/var/home/justin/Projects/Linear-Physi../idris2-Universe/src/Physics/Particles'

for file in os.listdir(directory):
    if file.endswith('.idr'):
        path = os.path.join(directory, file)
        with open(path, 'r') as f:
            content = f.read()
            
        # Clean Baryon t1 t2 t3
        new_content = re.sub(r'record Baryon t1 t2 t3 where', 'record Baryon where', content)
        # Clean Meson t1 t2
        new_content = re.sub(r'record Meson t1 t2 where', 'record Meson where', content)
        # Clean Quark t1
        new_content = re.sub(r'Quark t[123]', 'Quark', new_content)
        # Clean _ is already defined (by removing dummy proofs if they use t1, t2)
        # e.g., 0 isColorless : (getGeometry t1) <+> (getGeometry t2) = ...
        new_content = re.sub(r'\s*0\s+is[A-Za-z0-9_]+\s*:\s*[^\n]*getGeometry[^\n]*\n', '\n', new_content)
        
        if new_content != content:
            with open(path, 'w') as f:
                f.write(new_content)
            print(f"Cleaned composite {path}")
