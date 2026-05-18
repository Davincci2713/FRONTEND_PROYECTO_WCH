import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if filepath.endswith('login.dart'):
        content = content.replace('const Color kWhite = AppColors.text;', '')
        content = content.replace('const Color kNeonLime = AppColors.primary;', '')
        content = content.replace('const Color kBgDark = AppColors.background;', '')
        content = content.replace('const Color kPrimaryGreen = AppColors.primaryDark;', '')

        # And replace their usages
        content = content.replace('kWhite', 'AppColors.text')
        content = content.replace('kNeonLime', 'AppColors.primary')
        content = content.replace('kBgDark', 'AppColors.background')
        content = content.replace('kPrimaryGreen', 'AppColors.primaryDark')
        
    if filepath.endswith('news_detail.dart'):
        if 'import \'../utils/theme.dart\';' not in content:
             content = "import '../utils/theme.dart';\n" + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file('FRONTEND_PROYECTO_WCH/lib/screens/login.dart')
fix_file('FRONTEND_PROYECTO_WCH/lib/screens/news_detail.dart')

print("Done fixing login imports.")