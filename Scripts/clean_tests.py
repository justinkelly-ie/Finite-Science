import os
import re

directories = [
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/tests'
]

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.md') or file.endswith('.idr'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Replace SpacetimeManifold with Substrate
                new_content = content.replace('SpacetimeManifold', 'Substrate')
                
                # Remove phantom type parameters from FiberBundle and others
                new_content = re.sub(r'FiberBundle\s+[a-zA-Z0-9_]+', 'FiberBundle', new_content)
                new_content = re.sub(r'\{tree\s*:\s*Substrate\}\s*->\s*', '', new_content)
                new_content = re.sub(r'Baryon\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+', 'Baryon', new_content)
                new_content = re.sub(r'Meson\s+[a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+', 'Meson', new_content)
                
                # MkDense wrapper removal might be tricky, let's just do SpacetimeManifold and `{tree...}`
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Cleaned {path}")
