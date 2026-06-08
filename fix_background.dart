import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart') || file.path.contains('app_theme.dart')) continue;
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('backgroundColor: AppColors.darkBg')) {
      content = content.replaceAll('backgroundColor: AppColors.darkBg', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
      changed = true;
    }
    
    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
