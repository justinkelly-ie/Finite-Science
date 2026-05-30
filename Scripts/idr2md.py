import os
import glob

def convert_file(path):
    with open(path, 'r') as f:
        lines = f.readlines()
        
    out = []
    in_code = False
    
    def start_code():
        nonlocal in_code
        if not in_code:
            out.append("```idris\n")
            in_code = True
            
    def end_code():
        nonlocal in_code
        if in_code:
            out.append("```\n")
            in_code = False

    start_code()

    for line in lines:
        if line.startswith('|||'):
            end_code()
            doc_line = line[3:].lstrip()
            # If it's empty, just newline
            if not doc_line.strip():
                out.append("\n")
            else:
                out.append(doc_line)
        else:
            start_code()
            out.append(line)
            
    end_code()
    
    # Save as .md
    new_path = path[:-4] + ".md"
    with open(new_path, 'w') as f:
        f.writelines(out)
        
    # Remove old .idr
    os.remove(path)

files = glob.glob('/var/home/justin/Projects/Linear-Physi../idris2-Universe-Tests/src/Tests/*.idr')
for f in files:
    if f.endswith('.idr'):
        convert_file(f)
        print(f"Converted {os.path.basename(f)}")

