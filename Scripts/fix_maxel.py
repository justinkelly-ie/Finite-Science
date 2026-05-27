import os

replacements = {
    "pixelSupport": "pixelProjection",
    "maxelSupport": "maxelProjection",
    "mulPix": "composePix",
    "mulMaxel": "composeMaxel",
    "supportNL": "projectionNL",
    "pT.src": "pT.x",
    "p.tgt": "p.y",
    "pT.tgt": "pT.y",
    "p.src": "p.x"
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
