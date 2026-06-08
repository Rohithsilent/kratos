import 'package:flutter/material.dart';

class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color success;
  final Color warning;
  final Color info;

  final Color grey50;
  final Color grey100;
  final Color grey200;
  final Color grey300;
  final Color grey400;
  final Color grey500;
  final Color grey600;
  final Color grey700;
  final Color grey800;
  final Color grey900;

  final LinearGradient primaryGradient;
  final LinearGradient darkOverlay;
  final LinearGradient redFade;

  const AppCustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.grey50,
    required this.grey100,
    required this.grey200,
    required this.grey300,
    required this.grey400,
    required this.grey500,
    required this.grey600,
    required this.grey700,
    required this.grey800,
    required this.grey900,
    required this.primaryGradient,
    required this.darkOverlay,
    required this.redFade,
  });

  @override
  ThemeExtension<AppCustomColors> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? grey50,
    Color? grey100,
    Color? grey200,
    Color? grey300,
    Color? grey400,
    Color? grey500,
    Color? grey600,
    Color? grey700,
    Color? grey800,
    Color? grey900,
    LinearGradient? primaryGradient,
    LinearGradient? darkOverlay,
    LinearGradient? redFade,
  }) {
    return AppCustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      grey50: grey50 ?? this.grey50,
      grey100: grey100 ?? this.grey100,
      grey200: grey200 ?? this.grey200,
      grey300: grey300 ?? this.grey300,
      grey400: grey400 ?? this.grey400,
      grey500: grey500 ?? this.grey500,
      grey600: grey600 ?? this.grey600,
      grey700: grey700 ?? this.grey700,
      grey800: grey800 ?? this.grey800,
      grey900: grey900 ?? this.grey900,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      darkOverlay: darkOverlay ?? this.darkOverlay,
      redFade: redFade ?? this.redFade,
    );
  }

  @override
  ThemeExtension<AppCustomColors> lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      grey50: Color.lerp(grey50, other.grey50, t)!,
      grey100: Color.lerp(grey100, other.grey100, t)!,
      grey200: Color.lerp(grey200, other.grey200, t)!,
      grey300: Color.lerp(grey300, other.grey300, t)!,
      grey400: Color.lerp(grey400, other.grey400, t)!,
      grey500: Color.lerp(grey500, other.grey500, t)!,
      grey600: Color.lerp(grey600, other.grey600, t)!,
      grey700: Color.lerp(grey700, other.grey700, t)!,
      grey800: Color.lerp(grey800, other.grey800, t)!,
      grey900: Color.lerp(grey900, other.grey900, t)!,
      // LinearGradient doesn't have a simple lerp in this basic form without a custom function,
      // but typically gradients aren't lerped perfectly in themes, so we just switch them.
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      darkOverlay: t < 0.5 ? darkOverlay : other.darkOverlay,
      redFade: t < 0.5 ? redFade : other.redFade,
    );
  }
}
