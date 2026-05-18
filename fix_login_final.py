import os
import re

filepath = 'FRONTEND_PROYECTO_WCH/lib/screens/login.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# First, properly inject the import if not there
if 'import \'package:frontend_proyecto/utils/theme.dart\';' not in content and 'import \'../utils/theme.dart\';' not in content:
    content = "import '../utils/theme.dart';\n" + content

# Remove the broken top-level const definitions completely
lines = content.split('\n')
new_lines = []
for line in lines:
    if line.startswith('const Color kWhite') or line.startswith('const Color kNeonLime') or line.startswith('const Color kBgDark') or line.startswith('const Color kPrimaryGreen'):
        continue
    new_lines.append(line)
    
content = '\n'.join(new_lines)

# A more aggressive approach: strip `const ` anywhere it's used on the same line or before something that contains AppColors.
content = re.sub(r'const\s+([A-Za-z0-9_]+\([^;]*?AppColors\.[a-zA-Z]+)', r'\1', content, flags=re.DOTALL)
content = re.sub(r'const\s+(Scaffold|Text|Icon|SizedBox|CircularProgressIndicator|BoxDecoration|BorderSide|Border|OutlineInputBorder|RoundedRectangleBorder|ResponsiveLayout|SnackBar)\(', r'\1(', content)
content = content.replace('const Color AppColors.text = AppColors.text;', '')
content = content.replace('const Color AppColors.primary = AppColors.primary;', '')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done fixing login.dart.")
