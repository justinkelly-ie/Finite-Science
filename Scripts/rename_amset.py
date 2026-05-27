import os

replacements = {
    "Math.AMSet": "Math.SignedUnaryMultiset",
    "AMSet": "SignedUnaryMultiset",
    "MkAMSet": "MkSignedUnaryMultiset",
    "addA": "addSigned",
    "subA": "subSigned",
    "negateA": "negateSigned"
}

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for k, v in replacements.items():
        new_content = new_content.replace(k, v)
        
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed up {path}")

root_dir = '/var/home/justin/Projects/Linear-Physics'
for dirpath, dirnames, filenames in os.walk(root_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.')]
    for f in filenames:
        if f.endswith('.idr') or f.endswith('.md') or f.endswith('.ipkg'):
            filepath = os.path.join(dirpath, f)
            fix_file(filepath)

# Rename the file AMSet.idr -> SignedUnaryMultiset.idr
old_file = os.path.join(root_dir, 'idris2-Multiset-Advanced/src/Math/AMSet.idr')
new_file = os.path.join(root_dir, 'idris2-Multiset-Advanced/src/Math/SignedUnaryMultiset.idr')
if os.path.exists(old_file):
    os.rename(old_file, new_file)
    print(f"Renamed {old_file} to {new_file}")

# Rename test directory
old_test_dir = os.path.join(root_dir, 'idris2-Multiset-Advanced/tests/properties/amset-properties')
new_test_dir = os.path.join(root_dir, 'idris2-Multiset-Advanced/tests/properties/signedunarymultiset-properties')
if os.path.exists(old_test_dir):
    os.rename(old_test_dir, new_test_dir)
    print(f"Renamed {old_test_dir} to {new_test_dir}")
