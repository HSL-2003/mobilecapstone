import os
import re

target_dir = 'lib/screens'

# The unified FPT Orange color for strong highlight
fpt_orange_hex = 'Color(0xFFF26F21)'
# The unified FPT Orange color for lighter background / opacity context
fpt_orange_material = 'Colors.orange'

regex_patterns = [
    # Replace other HEX colors (excluding white/black/grey variations)
    (r'Color\(0xFFBA1826\)', fpt_orange_hex),
    (r'Color\(0xFF9D0208\)', fpt_orange_hex),
    (r'Color\(0xFF2B2D42\)', fpt_orange_hex),
    (r'Color\(0xFF8D99AE\)', fpt_orange_hex),
    (r'Color\(0xFF4361EE\)', fpt_orange_hex),
    (r'Color\(0xFFE2EAFB\)', fpt_orange_hex),
    (r'Color\(0xFFFB8500\)', fpt_orange_hex),
    (r'Color\(0xFFFFF3E0\)', 'Colors.orange.withOpacity(0.1)'),

    # Replace Material colors
    (r'Colors.blueAccent', fpt_orange_material),
    (r'Colors.blue', fpt_orange_material),
    (r'Colors.indigo', fpt_orange_material),
    (r'Colors.teal', fpt_orange_material),
    (r'Colors.deepPurple', fpt_orange_material),
    (r'Colors.purple', fpt_orange_material),
    (r'Colors.green', fpt_orange_material),
    (r'Colors.redAccent', fpt_orange_material),
    (r'Colors.red', fpt_orange_material),
    
    # Optional: replace the generic app bar colors if they exist in screens
    (r"backgroundColor: Colors\.(?!white|grey|black|transparent|orange)[a-zA-Z]+,", f"backgroundColor: {fpt_orange_material},"),
    (r"backgroundColor: Color\(0xFF[0-9A-Fa-f]+\),", f"backgroundColor: {fpt_orange_hex},"),
]

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    # We shouldn't change white/grey/black
    for pattern, replacement in regex_patterns:
        content = re.sub(pattern, replacement, content)

    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {file_path}")

for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Color replacement complete.")
