import os

directories = [
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/src',
    '/var/home/justin/Projects/Linear-Physi../idris2-Universe/tests',
    '/var/home/justin/Projects/Linear-Physics/idris2-QuickCheck/idris2-QuickCheck-tests'
]

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.idr'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                # Fix stripped newlines
                new_content = content.replace('import Math.FiberBundle import', 'import Math.FiberBundle\nimport')
                new_content = new_content.replace('import Math.FiberBundle Math.', 'import Math.FiberBundle\nimport Math.')
                new_content = new_content.replace('import Math.FiberBundle Physics.', 'import Math.FiberBundle\nimport Physics.')
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Fixed newlines in {path}")
