import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements mapping hardcoded colors to dynamic AppColors getters
    replacements = {
        'Colors.white54': 'AppColors.textMuted',
        'Colors.white70': 'AppColors.textMuted',
        'Colors.white24': 'AppColors.border',
        'Colors.white12': 'AppColors.borderLight',
        'Colors.black87': 'AppColors.text',
        'Colors.white,': 'AppColors.text,',
        'Colors.white)': 'AppColors.text)',
        'Colors.white;': 'AppColors.text;',
        'color: Colors.white': 'color: AppColors.text',
        'color: Colors.black': 'color: AppColors.onPrimary', # Usually on buttons/neon
        'color: Colors.transparent': 'color: Colors.transparent',
        'Colors.black,': 'AppColors.inverseSurface,', # For dark backgrounds
    }

    # Manual context-aware fixes
    # AppBar and solid blocks that used to be black in dark mode
    content = content.replace('backgroundColor: Colors.black', 'backgroundColor: AppColors.inverseSurface')
    content = content.replace('color: Colors.black', 'color: AppColors.inverseSurface')
    
    # Restore specific button texts/icons on Neon Lime to be strictly onPrimary (black)
    content = content.replace('color: AppColors.inverseSurface', 'color: AppColors.onPrimary')
    content = content.replace('backgroundColor: AppColors.inverseSurface', 'backgroundColor: AppColors.inverseSurface')

    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk('FRONTEND_PROYECTO_WCH/lib/screens'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

process_file('FRONTEND_PROYECTO_WCH/lib/utils/app_scaffold.dart')
print("Done refactoring colors.")
