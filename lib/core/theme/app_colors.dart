import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Reds ───
  static const Color primary = Color(0xFFFF3B3B);
  static const Color primaryDark = Color(0xFFD90429);
  static const Color primaryContainer = Color(0xFFE50914);
  static const Color primaryLight = Color(0xFFFF6B6B);
  static const Color primaryDeep = Color(0xFFB00020);

  // ─── Dark Theme ───
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkElevated = Color(0xFF242424);

  // ─── Light Theme ───
  static const Color lightBg = Color(0xFFF2F2F7); // Premium iOS-style off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEAEAEA);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ─── Neutrals ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFBDBDBD);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey500 = Color(0xFF757575);
  static const Color grey600 = Color(0xFF616161);
  static const Color grey700 = Color(0xFF424242);
  static const Color grey800 = Color(0xFF303030);
  static const Color grey900 = Color(0xFF212121);

  // ─── Glassmorphism (Dark) ───
  static Color get glassDark => Colors.white.withOpacity(0.06);
  static Color get glassBorderDark => Colors.white.withOpacity(0.12);
  static Color get glassHighDark => Colors.white.withOpacity(0.10);

  // ─── Glassmorphism (Light) ───
  static Color get glassLight => Colors.white.withOpacity(0.85);
  static Color get glassBorderLight => Colors.black.withOpacity(0.08);

  // ─── Glow Effects ───
  static Color get redGlow => primaryContainer.withOpacity(0.35);
  static Color get redGlowSubtle => primaryContainer.withOpacity(0.15);
  static Color get redGlowIntense => primaryContainer.withOpacity(0.6);

  // ─── Functional ───
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF3B3B), Color(0xFFD90429)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Color(0x00000000), Color(0xE6000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient redFade = LinearGradient(
    colors: [Color(0x80FF3B3B), Color(0x00FF3B3B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
