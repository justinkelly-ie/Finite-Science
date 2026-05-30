import os
import re

directories = [
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/src',
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/tests',
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/idris2-QuickCheck-tests'
]

replacements = [
    # Replace FiberBundle (Root "..." (MkGeometry ...)) with FiberBundle
    (re.compile(r'FiberBundle\s*\(Root\s*"[^"]+"\s*\([^)]+\)\)'), 'FiberBundle'),
    # Replace FiberBundle tree -> FiberBundle (except when it's just 'FiberBundle' at end of line)
    (re.compile(r'FiberBundle\s+([a-z_][a-zA-Z0-9_]*)(\s|$)'), r'FiberBundle\2'),
    # Replace MkRootSheaf {m = ...} (emptyPoly {geom = ...}) -> MkDense []
    (re.compile(r'MkRootSheaf\s*\{[^\}]+\}\s*\(emptyPoly\s*\{[^\}]+\}\)'), 'MkDense []'),
    # Replace MkRootSheaf {m = ...} poly -> poly
    (re.compile(r'MkRootSheaf\s*\{[^\}]+\}\s*'), 'MkDense '),
    # Replace MkRootSheaf with MkDense
    (re.compile(r'MkRootSheaf'), 'MkDense'),
    # Replace MkNestedSheaf with MkDense
    (re.compile(r'MkNestedSheaf'), 'MkDense'),
]

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.idr'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                new_content = content
                for pattern, repl in replacements:
                    new_content = pattern.sub(repl, new_content)
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Updated {path}")
