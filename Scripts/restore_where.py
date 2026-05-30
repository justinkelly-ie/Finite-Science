import os
import re

directories = [
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/src',
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/tests',
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/idris2-QuickCheck-tests'
]

pattern = re.compile(r'(implementation\s+[a-zA-Z_]+\s+FiberBundle)\n')

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.idr'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Restore 'where' if it was stripped
                new_content = pattern.sub(r'\1 where\n', content)
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Fixed 'where' in {path}")
