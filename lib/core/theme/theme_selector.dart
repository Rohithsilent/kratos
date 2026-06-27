import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_type.dart';
import 'theme_controller.dart';

/// A small settings widget that lists all available themes and lets the
/// user pick one. Drop this into any settings page to allow explicit
/// selection instead of toggling.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  String _labelFor(AppThemeType t) {
    switch (t) {
      case AppThemeType.light:
        return 'Light';
      case AppThemeType.dark:
        return 'Dark';
      case AppThemeType.superSaiyan:
        return 'Super Saiyan Orange';
      case AppThemeType.cyberpunk:
        return 'Cyberpunk Iron';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('App Theme', style: Theme.of(context).textTheme.titleMedium),
        ),
        ...AppThemeType.values.map((type) {
          final label = _labelFor(type);
          return RadioListTile<AppThemeType>(
            value: type,
            groupValue: current,
            onChanged: (v) {
              if (v != null) ref.read(themeControllerProvider.notifier).setTheme(v);
            },
            title: Text(label),
            secondary: _buildPreviewIcon(type, context),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPreviewIcon(AppThemeType type, BuildContext context) {
    switch (type) {
      case AppThemeType.light:
        return Icon(Icons.wb_sunny, color: Theme.of(context).colorScheme.primary);
      case AppThemeType.dark:
        return Icon(Icons.nights_stay, color: Theme.of(context).colorScheme.primary);
      case AppThemeType.superSaiyan:
        return CircleAvatar(backgroundColor: const Color(0xFFFF5722));
      case AppThemeType.cyberpunk:
        return CircleAvatar(backgroundColor: const Color(0xFFCCFF00));
    }
  }
}
