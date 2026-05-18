import os
import re

def strip_consts(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    wrappers = ['Scaffold', 'Text', 'Icon', 'SizedBox', 'CircularProgressIndicator', 'BoxDecoration', 'BorderSide', 'Border', 'OutlineInputBorder', 'RoundedRectangleBorder', 'ResponsiveLayout', 'SnackBar', 'Divider', 'TextStyle', 'Center', 'Padding', 'Row', 'Column']
    for w in wrappers:
        content = re.sub(r'const\s+' + w + r'\(', w + r'(', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('FRONTEND_PROYECTO_WCH/lib'):
    for file in files:
        if file.endswith('.dart'):
            strip_consts(os.path.join(root, file))

print("Done fixing all.")