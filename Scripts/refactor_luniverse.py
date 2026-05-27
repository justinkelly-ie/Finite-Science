import os
import re

base_dir = "/var/home/justin/Projects/Linear-Physics/idris2-LUniverse"

for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".idr"):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
            
            if "MkMultiset" not in content:
                continue
                
            lines = content.split('\n')
            new_lines = []
            for line in lines:
                # 1. Pattern matching `(MkMultiset xs)` -> `xs_mset`
                if "(MkMultiset xs)" in line:
                    line = line.replace("(MkMultiset xs)", "xs_mset")
                    new_lines.append(line)
                    # We inject `let xs = toList xs_mset` in the next line if it's a function declaration
                    # Actually, if it has `xs_mset`, let's just do an inline replace of `xs` -> `(toList xs_mset)` in the subsequent lines? 
                    # No, let's just inject `let xs = toList xs_mset`
                    continue
                
                if "(MkMultiset rawTerms)" in line:
                    line = line.replace("(MkMultiset rawTerms)", "rawTerms_mset")
                    new_lines.append(line)
                    continue

                if "(MkMultiset items)" in line:
                    line = line.replace("(MkMultiset items)", "items_mset")
                    new_lines.append(line)
                    continue
                
                if "(MkMultiset stateVector)" in line:
                    line = line.replace("(MkMultiset stateVector)", "stateVector_mset")
                    new_lines.append(line)
                    continue

                if "(MkMultiset polyItems)" in line:
                    line = line.replace("(MkMultiset polyItems)", "polyItems_mset")
                    new_lines.append(line)
                    continue
                
                if "(MkMultiset sp1) (MkMultiset sp2)" in line:
                    line = line.replace("(MkMultiset sp1) (MkMultiset sp2)", "sp1_mset sp2_mset")
                    new_lines.append(line)
                    continue
                
                # 2. Construction `MkMultiset` -> `fromList`
                if "MkMultiset" in line:
                    line = line.replace("MkMultiset", "fromList")
                
                new_lines.append(line)
                
            content = '\n'.join(new_lines)
            
            # Now replace occurrences of variables to use `toList`
            content = re.sub(r'\bxs\b(?=.*xs_mset)', '(toList xs_mset)', content, flags=re.DOTALL)
            
            with open(path, 'w') as f:
                f.write(content)
