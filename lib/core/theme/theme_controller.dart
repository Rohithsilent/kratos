import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palettes.dart';
import 'app_theme.dart';
import 'app_theme_type.dart';

const String _themeKey = 'kratos_theme_type';

class ThemeController extends Notifier<AppThemeType> {
  @override
  AppThemeType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMode = prefs.getString(_themeKey);
    
    // Parse saved string to enum
    for (var type in AppThemeType.values) {
      if (type.name == savedMode) {
        return type;
      }
    }
    
    return AppThemeType.dark; // Default
  }

  void toggleTheme() {
    // Cycle through all available theme types in order.
    final values = AppThemeType.values;
    final currentIndex = values.indexOf(state);
    final nextIndex = (currentIndex + 1) % values.length;
    setTheme(values[nextIndex]);
  }

  void setTheme(AppThemeType type) {
    state = type;
    ref.read(sharedPreferencesProvider).setString(_themeKey, type.name);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeType>(() {
  return ThemeController();
});

// A provider that computes the actual ThemeData based on the current AppThemeType
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeType = ref.watch(themeControllerProvider);
  
  switch (themeType) {
    case AppThemeType.light:
      return AppThemeFactory.buildTheme(LightPalette(), Brightness.light);
    case AppThemeType.dark:
      return AppThemeFactory.buildTheme(DarkPalette(), Brightness.dark);
    case AppThemeType.superSaiyan:
      // Super Saiyan uses a light-style background (orange/white) with blue accents.
      return AppThemeFactory.buildTheme(SuperSaiyanPalette(), Brightness.light);
    case AppThemeType.cyberpunk:
      return AppThemeFactory.buildTheme(CyberpunkPalette(), Brightness.dark);
    default:
      return AppThemeFactory.buildTheme(DarkPalette(), Brightness.dark);
  }
});
