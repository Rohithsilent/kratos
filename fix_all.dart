import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart') || file.path.contains('app_theme_extensions.dart')) continue;
    String content = file.readAsStringSync();
    bool changed = false;

    // 1. Fix AppColors.grey900xx
    final exp = RegExp(r'AppColors\.grey900(\d+)');
    if (exp.hasMatch(content)) {
      content = content.replaceAllMapped(exp, (m) => 'AppColors.grey900.withOpacity(0.${m.group(1)})');
      changed = true;
    }
    
    // Fix AppColors.grey700xx etc.
    for (int i = 4; i <= 8; i++) {
        final ex2 = RegExp('AppColors\\.grey${i}00(\\d+)');
        if (ex2.hasMatch(content)) {
          content = content.replaceAllMapped(ex2, (m) => 'AppColors.grey${i}00.withOpacity(0.${m.group(1)})');
          changed = true;
        }
    }
    final exwhite = RegExp(r'Colors\.white(\d+)');
    if (exwhite.hasMatch(content)) {
        content = content.replaceAllMapped(exwhite, (m) => 'Colors.white.withOpacity(0.${m.group(1)})');
        changed = true;
    }

    // 2. Remove all `const ` keywords to clear up const_eval_method_invocation. dart fix will put back valid consts.
    if (content.contains('const ') && !content.contains('const String _themeKey')) {
        // We only replace `const ` before widgets or TextStyles, etc.
        content = content.replaceAll('const ', '');
        changed = true;
    }

    // 3. Fix missing imports in hydration_tracker_card.dart
    if (file.path.endsWith('hydration_tracker_card.dart')) {
        if (!content.contains('app_colors.dart')) {
            content = "import '../../../core/theme/app_colors.dart';\n$content";
            changed = true;
        }
    }

    // 4. Fix undefined context in specific files by reverting the dynamic text color back to Colors.white
    // The specific files are: consistency_heatmap.dart, mission_card.dart, nutrition_tracker_card.dart, recovery_day_card.dart
    if (file.path.endsWith('consistency_heatmap.dart') || 
        file.path.endsWith('mission_card.dart') || 
        file.path.endsWith('nutrition_tracker_card.dart') || 
        file.path.endsWith('recovery_day_card.dart') ||
        file.path.endsWith('planner_timeline.dart')) {
        
        // Let's just revert Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900 -> Colors.white
        content = content.replaceAll(r'Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900', 'Colors.white');
        
        // Also the withOpacity variants
        content = content.replaceAllMapped(RegExp(r'Theme\.of\(context\)\.brightness == Brightness\.dark \? Colors\.white\.withOpacity\(([^)]+)\) : AppColors\.grey[4-7]00\.withOpacity\([^)]+\)'), (m) => 'Colors.white.withOpacity(${m.group(1)})');
        changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
