import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Fix broken imports
    content = content.replace('import LMath.SparseMaxel s', 'import LMath.SparseMaxel')
    content = content.replace('module LMath.SparseMaxel s', 'module LMath.SparseMaxel')

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed imports in {filepath}")

def main():
    src_dir = 'src'
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith('.idr'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
