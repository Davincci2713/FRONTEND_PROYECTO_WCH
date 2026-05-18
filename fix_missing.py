import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements for remaining missing things
    replacements = {
        'kWhite': 'AppColors.text',
        'kNeonLime': 'AppColors.primary',
        'kBgDark': 'AppColors.background',
        'kPrimaryGreen': 'AppColors.primaryDark',
    }

    if filepath.endswith('login.dart'):
        for old, new in replacements.items():
            content = content.replace(old, new)
        content = content.replace('const Color AppColors.text = AppColors.text;', '')
        content = content.replace('const Color AppColors.primary = AppColors.primary;', '')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('FRONTEND_PROYECTO_WCH/lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Done fixing missing errors.")
