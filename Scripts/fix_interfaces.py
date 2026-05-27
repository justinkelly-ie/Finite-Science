import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Fix interface implementations:
    # Match something like: InterfaceName SparseMaxel s where
    content = re.sub(r'(\w+)\s+SparseMaxel\s+s\s+where', r'\1 (SparseMaxel s) where', content)
    content = re.sub(r'(\w+)\s+UniverseState\s+s\s+where', r'\1 (UniverseState s) where', content)
    content = re.sub(r'(\w+)\s+UniverseState\s+where', r'\1 (UniverseState s) where', content)

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed interface implementation in {filepath}")

def main():
    src_dir = 'src'
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith('.idr'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
