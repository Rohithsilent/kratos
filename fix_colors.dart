import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart') || file.path.contains('app_theme_extensions.dart')) continue;
    String content = file.readAsStringSync();
    bool changed = false;

    // Replace const TextStyle(...) with TextStyle(...) where Colors.white or AppColors.white is used.
    // Also handle const Text(..., style: const TextStyle(...)) etc.
    final exp = RegExp(r'const\s+TextStyle\s*\(\s*color:\s*(Colors\.white|AppColors\.white)');
    if (exp.hasMatch(content)) {
      content = content.replaceAllMapped(exp, (m) {
        return 'TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900';
      });
      changed = true;
    }
    
    // Sometimes it's style: const TextStyle(..., color: Colors.white)
    final exp2 = RegExp(r'const\s+TextStyle\s*\(([^)]*?)color:\s*(Colors\.white|AppColors\.white)');
    if (exp2.hasMatch(content)) {
      content = content.replaceAllMapped(exp2, (m) {
        return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900';
      });
      changed = true;
    }

    // Now remove remaining non-const TextStyles
    final exp3 = RegExp(r'TextStyle\s*\(\s*color:\s*(Colors\.white|AppColors\.white)');
    if (exp3.hasMatch(content)) {
      content = content.replaceAllMapped(exp3, (m) {
        return 'TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900';
      });
      changed = true;
    }

    final exp4 = RegExp(r'TextStyle\s*\(([^)]*?)color:\s*(Colors\.white|AppColors\.white)');
    if (exp4.hasMatch(content)) {
      content = content.replaceAllMapped(exp4, (m) {
        return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900';
      });
      changed = true;
    }

    // Also replace `Icon(..., color: Colors.white)`
    final iconExp = RegExp(r'Icon\s*\(\s*([^,]+),\s*color:\s*(Colors\.white|AppColors\.white)');
    if (iconExp.hasMatch(content)) {
      content = content.replaceAllMapped(iconExp, (m) {
        return 'Icon(${m.group(1)}, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900';
      });
      changed = true;
    }

    // Remove `const ` before `Text(` if its style contains Theme.of
    final constTextExp = RegExp(r'const\s+Text\s*\(([^)]*?)Theme\.of');
    if (constTextExp.hasMatch(content)) {
        content = content.replaceAllMapped(constTextExp, (m) => 'Text(${m.group(1)}Theme.of');
        changed = true;
    }
    
    // Also `const Icon(...)`
    final constIconExp = RegExp(r'const\s+Icon\s*\(([^)]*?)Theme\.of');
    if (constIconExp.hasMatch(content)) {
        content = content.replaceAllMapped(constIconExp, (m) => 'Icon(${m.group(1)}Theme.of');
        changed = true;
    }

    // Replace color: Colors.white70 -> Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.grey700
    final textWhite70 = RegExp(r'TextStyle\s*\(([^)]*?)color:\s*Colors\.white70');
    if (textWhite70.hasMatch(content)) {
        content = content.replaceAllMapped(textWhite70, (m) {
            return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.grey700';
        });
        changed = true;
    }
    final textWhite60 = RegExp(r'TextStyle\s*\(([^)]*?)color:\s*Colors\.white60');
    if (textWhite60.hasMatch(content)) {
        content = content.replaceAllMapped(textWhite60, (m) {
            return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : AppColors.grey600';
        });
        changed = true;
    }
    final textWhite54 = RegExp(r'TextStyle\s*\(([^)]*?)color:\s*Colors\.white54');
    if (textWhite54.hasMatch(content)) {
        content = content.replaceAllMapped(textWhite54, (m) {
            return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppColors.grey500';
        });
        changed = true;
    }
    final textWhite38 = RegExp(r'TextStyle\s*\(([^)]*?)color:\s*Colors\.white38');
    if (textWhite38.hasMatch(content)) {
        content = content.replaceAllMapped(textWhite38, (m) {
            return 'TextStyle(${m.group(1)}color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : AppColors.grey400';
        });
        changed = true;
    }

    // Fix remaining const Text / const Row that contain Theme.of
    while(content.contains('const Row') || content.contains('const Column')) {
        String prev = content;
        content = content.replaceAllMapped(RegExp(r'const\s+(Row|Column|Container|Padding|Align|Center|SizedBox|Expanded)\s*\(([^}]*?)Theme\.of'), (m) => '${m.group(1)}(${m.group(2)}Theme.of');
        if (prev == content) break;
    }
    
    // We'll run flutter format and dart fix later to fix residual errors.
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
