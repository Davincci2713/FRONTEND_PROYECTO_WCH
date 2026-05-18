import os
import re

filepath = 'FRONTEND_PROYECTO_WCH/lib/screens/login.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

if 'import \'package:frontend_proyecto/utils/theme.dart\';' not in content and 'import \'../utils/theme.dart\';' not in content:
    content = "import '../utils/theme.dart';\n" + content

lines = content.split('\n')
new_lines = []
for line in lines:
    if line.startswith('const Color kWhite') or line.startswith('const Color kNeonLime') or line.startswith('const Color kBgDark') or line.startswith('const Color kPrimaryGreen'):
        continue
    new_lines.append(line)
    
content = '\n'.join(new_lines)

# Strip const keywords if they wrap AppColors
content = re.sub(r'const\s+([A-Za-z0-9_]+\([^;]*?AppColors\.[a-zA-Z]+)', r'\1', content, flags=re.DOTALL)
# One more pass for specific cases that might be nested
content = re.sub(r'const\s+(Scaffold|Text|Icon|SizedBox|CircularProgressIndicator|BoxDecoration|BorderSide|Border|OutlineInputBorder|RoundedRectangleBorder|ResponsiveLayout)\(', r'\1(', content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done fixing login.dart.")