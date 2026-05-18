import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements for getters that were removed from AppColors
    replacements = {
        'AppColors.onPrimary87': 'AppColors.textMuted',
        'AppColors.onPrimary54': 'AppColors.border',
    }

    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('FRONTEND_PROYECTO_WCH/lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Done fixing getter errors.")
