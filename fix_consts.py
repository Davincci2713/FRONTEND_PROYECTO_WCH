import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find `const` preceding specific widget constructors that now use dynamic colors
    patterns = [
        r'const\s+(BoxDecoration\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(Border\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(BorderSide\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(OutlineInputBorder\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(Icon\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(SizedBox\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(Divider\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(RoundedRectangleBorder\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(Center\([^)]*AppColors\.[a-zA-Z]+)',
        r'const\s+(TextStyle\([^)]*AppColors\.[a-zA-Z]+)'
    ]
    
    for pattern in patterns:
        content = re.sub(pattern, r'\1', content, flags=re.MULTILINE | re.DOTALL)
        
    # Extra pass for multi-line cases like const RoundedRectangleBorder(...)
    content = re.sub(r'const\s+(RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.zero,\s*side:\s*BorderSide\(color:\s*AppColors\.[a-zA-Z]+)', r'\1', content)
    content = re.sub(r'const\s+(BoxDecoration\(\s*color:\s*AppColors\.[a-zA-Z]+)', r'\1', content)
    content = re.sub(r'const\s+(BoxDecoration\(\s*border:\s*Border\(\w+:\s*BorderSide\(color:\s*AppColors\.[a-zA-Z]+)', r'\1', content)
    content = re.sub(r'const\s+(OutlineInputBorder\(\s*borderRadius:\s*BorderRadius\.zero,\s*borderSide:\s*BorderSide\(color:\s*AppColors\.[a-zA-Z]+)', r'\1', content)
    content = re.sub(r'const\s+(Scaffold\(\s*backgroundColor:\s*AppColors\.[a-zA-Z]+)', r'\1', content)

    # Missing imports
    if 'AppColors' in content and 'import \'package:frontend_proyecto/utils/theme.dart\';' not in content and 'import \'../utils/theme.dart\';' not in content:
        if filepath.endswith('login.dart'):
            content = "import '../utils/theme.dart';\n" + content
        elif filepath.endswith('group_detail.dart'):
            content = "import '../utils/theme.dart';\n" + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('FRONTEND_PROYECTO_WCH/lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Done fixing const errors.")