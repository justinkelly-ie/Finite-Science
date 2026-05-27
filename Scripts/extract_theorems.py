import os
import re

SRC_DIR = "/var/home/justin/Projects/Linear-Physics/idris2-LUniverse/src/Physics/"
OUTPUT_FILE = "/var/home/justin/Projects/Linear-Physics/Library/Wiki/Physics/Theorems.md"

def extract():
    theorems = []
    
    for root, _, files in os.walk(SRC_DIR):
        for file in files:
            if not file.endswith(".idr"): continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                lines = f.readlines()
                
            doc_buffer = []
            i = 0
            while i < len(lines):
                line = lines[i].strip()
                if line.startswith("|||"):
                    doc_buffer.append(line[3:].strip())
                    i += 1
                    continue
                
                if line.startswith("public export"):
                    # Next line should be signature
                    if i + 1 < len(lines):
                        sig_line = lines[i+1].strip()
                        # Next line should be implementation
                        if i + 2 < len(lines):
                            impl_line = lines[i+2].strip()
                            if "Refl" in impl_line and ":" in sig_line:
                                name, typ = sig_line.split(":", 1)
                                name = name.strip()
                                typ = typ.strip()
                                
                                theorems.append({
                                    "module": os.path.relpath(filepath, SRC_DIR).replace("/", ".").replace(".idr", ""),
                                    "name": name,
                                    "type": typ,
                                    "doc": "\n".join(doc_buffer)
                                })
                    doc_buffer = []
                elif line != "":
                    doc_buffer = []
                i += 1
                
    # Generate Markdown
    with open(OUTPUT_FILE, "w") as out:
        out.write("# Verified Theorems\n\n")
        out.write("This document aggregates all formal mathematical physics theorems proven entirely at compile-time by the Idris 2 typechecker. These are absolute structural guarantees, requiring no runtime execution.\n\n")
        
        for t in theorems:
            out.write(f"### {t['name']}\n")
            out.write(f"**Module**: `Physics.{t['module']}`\n\n")
            if t['doc']:
                out.write(f"{t['doc']}\n\n")
            out.write("```idris\n")
            out.write(f"{t['name']} : {t['type']}\n")
            out.write("```\n\n")
            out.write("---\n\n")
        
        print(f"Extracted {len(theorems)} compile-time theorems to {OUTPUT_FILE}")

if __name__ == "__main__":
    extract()
