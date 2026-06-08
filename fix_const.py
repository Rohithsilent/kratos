import os
import re

lib_dir = "lib"
files_modified = 0

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Simple replace 'const ' with '' on lines that have 'context.colors' or 'context.customColors'
            lines = content.split('\n')
            new_lines = []
            modified = False
            for line in lines:
                if ('context.colors' in line or 'context.customColors' in line or 'context.glassmorphism' in line or 'context.glow' in line):
                    if 'const ' in line:
                        new_line = line.replace('const ', '')
                        new_lines.append(new_line)
                        modified = True
                        continue
                new_lines.append(line)
            
            if modified:
                with open(filepath, 'w') as f:
                    f.write('\n'.join(new_lines))
                files_modified += 1
                print(f"Modified: {filepath}")

print(f"Total files modified: {files_modified}")
