import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('AppDecorations.glassCard(isDark: true)')) {
      content = content.replaceAll('AppDecorations.glassCard(isDark: true)', 'AppDecorations.glassCard(context)');
      changed = true;
    }
    if (content.contains('AppDecorations.glassCard(isDark: isDark)')) {
      content = content.replaceAll('AppDecorations.glassCard(isDark: isDark)', 'AppDecorations.glassCard(context)');
      changed = true;
    }
    if (content.contains('AppDecorations.glassInput()')) {
      content = content.replaceAll('AppDecorations.glassInput()', 'AppDecorations.glassInput(context)');
      changed = true;
    }
    if (content.contains('AppDecorations.glassInput(isDark: true)')) {
      content = content.replaceAll('AppDecorations.glassInput(isDark: true)', 'AppDecorations.glassInput(context)');
      changed = true;
    }
    if (content.contains('AppDecorations.primaryButton(')) {
      content = content.replaceAll('AppDecorations.primaryButton(', 'AppDecorations.primaryButton(context, ');
      changed = true;
    }
    if (content.contains('AppDecorations.primaryButton()')) {
      content = content.replaceAll('AppDecorations.primaryButton()', 'AppDecorations.primaryButton(context)');
      changed = true;
    }
    if (content.contains('AppDecorations.outlineButton(')) {
      content = content.replaceAll('AppDecorations.outlineButton(', 'AppDecorations.outlineButton(context, ');
      changed = true;
    }
    if (content.contains('AppDecorations.redGlowShadow(')) {
      content = content.replaceAll('AppDecorations.redGlowShadow(', 'AppDecorations.redGlowShadow(context, ');
      changed = true;
    }

    // Fix comma syntax issues if any like context, ) -> context)
    content = content.replaceAll('context, )', 'context)');

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed ${file.path}');
    }
  }
}
