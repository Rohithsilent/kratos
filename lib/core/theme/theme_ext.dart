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
}
