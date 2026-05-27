import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Replace stateLag with multiplicityAll in Elements directory
    content = content.replace('stateLag o.nucleus', 'multiplicityAll o.nucleus')
    content = content.replace('stateLag o.electrons', 'multiplicityAll o.electrons')
    content = content.replace('stateLag c.nucleus', 'multiplicityAll c.nucleus')
    content = content.replace('stateLag c.electrons', 'multiplicityAll c.electrons')
    content = content.replace('stateLag fe.nucleus', 'multiplicityAll fe.nucleus')
    content = content.replace('stateLag fe.electrons', 'multiplicityAll fe.electrons')
    content = content.replace('stateLag f.nucleus', 'multiplicityAll f.nucleus')
    content = content.replace('stateLag f.electrons', 'multiplicityAll f.electrons')
    
    # Catch any generic ones like `stateLag x.nucleus`
    content = re.sub(r'stateLag (\w+\.nucleus)', r'multiplicityAll \1', content)
    content = re.sub(r'stateLag (\w+\.electrons?)', r'multiplicityAll \1', content)
    content = re.sub(r'stateLag (\w+\.protons?)', r'multiplicityAll \1', content)

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed stateLag in {filepath}")

def main():
    src_dir = 'src/LPhysics/Elements'
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith('.idr'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
