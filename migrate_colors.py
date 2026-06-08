import os
import re

# This script replaces AppColors.something with the context-based equivalents.

replacements = {
    # Primary
    r'AppColors\.primary\b': 'context.colors.primary',
    r'AppColors\.primaryDark\b': 'context.colors.primary',
    r'AppColors\.primaryContainer\b': 'context.colors.primary',
    r'AppColors\.primaryLight\b': 'context.colors.secondary',
    r'AppColors\.primaryDeep\b': 'context.colors.primary',

    # Backgrounds & Surfaces -> mapping to standard colorScheme where possible
    r'AppColors\.darkBg\b': 'context.colors.surface',
    r'AppColors\.lightBg\b': 'context.colors.surface',
    r'AppColors\.darkSurface\b': 'context.colors.surface',
    r'AppColors\.lightSurface\b': 'context.colors.surface',
    r'AppColors\.darkSurfaceVariant\b': 'context.colors.surface',
    r'AppColors\.lightSurfaceVariant\b': 'context.colors.surface',
    r'AppColors\.darkCard\b': 'context.colors.surface',
    r'AppColors\.lightCard\b': 'context.colors.surface',
    r'AppColors\.darkElevated\b': 'context.colors.surface',
    
    # Neutrals
    r'AppColors\.white\b': 'Colors.white',
    r'AppColors\.black\b': 'Colors.black',
    r'AppColors\.grey50\b': 'context.customColors.grey50',
    r'AppColors\.grey100\b': 'context.customColors.grey100',
    r'AppColors\.grey200\b': 'context.customColors.grey200',
    r'AppColors\.grey300\b': 'context.customColors.grey300',
    r'AppColors\.grey400\b': 'context.customColors.grey400',
    r'AppColors\.grey500\b': 'context.customColors.grey500',
    r'AppColors\.grey600\b': 'context.customColors.grey600',
    r'AppColors\.grey700\b': 'context.customColors.grey700',
    r'AppColors\.grey800\b': 'context.customColors.grey800',
    r'AppColors\.grey900\b': 'context.customColors.grey900',

    # Functional
    r'AppColors\.success\b': 'context.customColors.success',
    r'AppColors\.warning\b': 'context.customColors.warning',
    r'AppColors\.error\b': 'context.colors.error',
    r'AppColors\.info\b': 'context.customColors.info',

    # Glass & Glow & Gradients (some require extensions)
    r'AppColors\.glassDark\b': 'context.glassmorphism.cardColor',
    r'AppColors\.glassLight\b': 'context.glassmorphism.cardColor',
    r'AppColors\.glassBorderDark\b': 'context.glassmorphism.borderColor',
    r'AppColors\.glassBorderLight\b': 'context.glassmorphism.borderColor',

    r'AppColors\.redGlow\b': 'context.glow.redGlow',
    r'AppColors\.redGlowSubtle\b': 'context.glow.redGlowSubtle',
    r'AppColors\.redGlowIntense\b': 'context.glow.redGlowIntense',

    r'AppColors\.primaryGradient\b': 'context.customColors.primaryGradient',
    r'AppColors\.darkOverlay\b': 'context.customColors.darkOverlay',
    r'AppColors\.redFade\b': 'context.customColors.redFade',
}

lib_dir = "lib"

files_modified = 0

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()

            new_content = content
            made_replacement = False

            # Check if we need to add the import
            needs_import = False
            for old, new in replacements.items():
                if re.search(old, new_content):
                    new_content = re.sub(old, new, new_content)
                    made_replacement = True
                    needs_import = True

            if made_replacement:
                # Add import if missing
                import_stmt = "import 'package:kratos/core/theme/theme_ext.dart';"
                if "import 'package:flutter/material.dart';" in new_content and import_stmt not in new_content:
                    # insert after material.dart
                    new_content = new_content.replace(
                        "import 'package:flutter/material.dart';", 
                        f"import 'package:flutter/material.dart';\n{import_stmt}"
                    )
                elif import_stmt not in new_content:
                    # just prepend it
                    new_content = f"{import_stmt}\n" + new_content

                with open(filepath, 'w') as f:
                    f.write(new_content)
                files_modified += 1
                print(f"Modified: {filepath}")

print(f"Total files modified: {files_modified}")
