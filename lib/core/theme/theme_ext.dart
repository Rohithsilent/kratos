import 'package:flutter/material.dart';
import 'app_custom_colors.dart';
import 'app_theme_extensions.dart';

extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Custom Extensions
  AppCustomColors get customColors => theme.extension<AppCustomColors>()!;
  GlassmorphismExtension get glassmorphism => theme.extension<GlassmorphismExtension>()!;
  GlowExtension get glow => theme.extension<GlowExtension>()!;

  // Theme-aware helpers
  bool get isDark => theme.brightness == Brightness.dark;
  Color get mutedText => colors.onSurface.withOpacity(isDark ? 0.65 : 0.60);
  Color get subtleBorder => isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
  Color get subtleCard => isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);
  Color get subtleHighlight => isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
}
