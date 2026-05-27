import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Check if we need to process this file
    if 'SparseMaxel' not in content:
        return

    # Skip the file where it's defined to avoid double-processing its own definitions
    if filepath.endswith('LMath/SparseMaxel.idr'):
        return

    # Replace qualified names first
    content = re.sub(r'\bMath\.Core\.SparseMaxel\b', 'SparseMaxel', content)
    content = re.sub(r'\bLMath\.Core\.SparseMaxel\b', 'SparseMaxel', content)

    # Now replace SparseMaxel with SparseMaxel s, but only if it's not already followed by s
    # and only if it's not preceded by L (i.e. LSparseMaxel)
    content = re.sub(r'(?<!L)\bSparseMaxel\b(?!\s+s\b)', 'SparseMaxel s', content)

    # If we made changes and we need the import
    if content != original_content or 'SparseMaxel s' in content:
        if 'import LMath.SparseMaxel' not in content:
            # Find a good place to insert the import
            # Let's put it after the last import
            lines = content.split('\n')
            last_import_idx = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import_idx = i
            
            if last_import_idx != -1:
                lines.insert(last_import_idx + 1, 'import LMath.SparseMaxel')
            else:
                # If no imports, put it after module declaration
                for i, line in enumerate(lines):
                    if line.startswith('module '):
                        lines.insert(i + 1, '\nimport LMath.SparseMaxel')
                        break
            content = '\n'.join(lines)
            
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    src_dir = 'src'
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith('.idr'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
