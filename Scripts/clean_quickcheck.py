import os
import re

directories = [
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/src',
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/idris2-QuickCheck-tests'
]

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.idr'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Replace SpacetimeManifold with Substrate
                new_content = content.replace('SpacetimeManifold', 'Substrate')
                # Replace (Root "Absolute Vacuum" (MkGeometry 1 Rigid)) with MkMaxelNL []
                new_content = new_content.replace('(Root "Absolute Vacuum" (MkGeometry 1 Rigid))', 'MkMaxelNL []')
                
                # Replace Node constructions, since they changed
                # Instead of trying to parse Node, let's just make it MkMaxelNL [] if they are just dummy universes
                # Wait, Node has human readable strings, maybe we should just change it if we see it?
                new_content = re.sub(r'\(Node [^)]+\)', 'MkMaxelNL []', new_content)
                new_content = re.sub(r'\(Root [^)]+\)', 'MkMaxelNL []', new_content)

                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Cleaned {path}")
