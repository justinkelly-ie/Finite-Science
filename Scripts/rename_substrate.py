import os

directories = [
    '/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src',
    '/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/tests',
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/idris2-QuickCheck-tests'
]

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.idr') or file.endswith('.md'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Replace exact name
                new_content = content.replace('SpacetimeManifold', 'Substrate')
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Renamed SpacetimeManifold to Substrate in {path}")
