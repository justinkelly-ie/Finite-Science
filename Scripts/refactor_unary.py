import os

def rename_content_in_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content.replace('SparseMultiset', 'UnaryMultiset')
    new_content = new_content.replace('sparsemultiset', 'unarymultiset') # just in case
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated content in {path}")

def main():
    root_dir = '/var/home/justin/Projects/Linear-Physics'
    
    # First update contents
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # skip hidden dirs
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        for f in filenames:
            if f.endswith('.idr') or f.endswith('.ipkg') or f.endswith('.md') or f.endswith('.toml'):
                filepath = os.path.join(dirpath, f)
                rename_content_in_file(filepath)
                
    # Then rename files and directories from bottom up
    for dirpath, dirnames, filenames in os.walk(root_dir, topdown=False):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        for f in filenames:
            if 'SparseMultiset' in f:
                old_path = os.path.join(dirpath, f)
                new_path = os.path.join(dirpath, f.replace('SparseMultiset', 'UnaryMultiset'))
                os.rename(old_path, new_path)
                print(f"Renamed file {old_path} to {new_path}")
        
        for d in dirnames:
            if 'SparseMultiset' in d:
                old_path = os.path.join(dirpath, d)
                new_path = os.path.join(dirpath, d.replace('SparseMultiset', 'UnaryMultiset'))
                os.rename(old_path, new_path)
                print(f"Renamed directory {old_path} to {new_path}")

if __name__ == '__main__':
    main()
