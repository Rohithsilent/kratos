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
  static const Color lightBg = Color(0xFFF8EBE1); // warmer off-white with a soft orange tint
  static const Color lightSurface = Color(0xFFFFF8F2);
  static const Color lightSurfaceVariant = Color(0xFFF3E4D8);
  static const Color lightCard = Color(0xFFFFF8F2);

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
  static Color get glassBlue => const Color(0xFF5FA8FF).withOpacity(0.24);
  static Color get glassBlueBorder => const Color(0xFF8EC5FF).withOpacity(0.34);

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

  // Super Saiyan gradient (orange → white) for warm background accents
  static const LinearGradient ssPrimaryGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cyberpunk gradient (neon volt green → charcoal)
  static const LinearGradient cpPrimaryGradient = LinearGradient(
    colors: [Color(0xFFCCFF00), Color(0xFF0F0F12)],
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

  // ─── Super Saiyan Orange (Dragon Ball inspired)
  // Background tuned to warm orange/white; primary (icons/accents) are blue.
  static const Color ssScaffold = Color(0xFFFFF8F0); // light cream background for light theme
  static const Color ssPrimary = Color(0xFF0D47A1); // deep blue for icons/accents
  static const Color ssSecondary = Color(0xFFFF5722); // energetic orange
  static const Color ssSurface = Color(0xFFFFF8F0); // light cream surface for cards

  // ─── Cyberpunk Iron (Neon / Charcoal) ───
  static const Color cpScaffold = Color(0xFF0F0F12);
  static const Color cpPrimary = Color(0xFFCCFF00);
  static const Color cpSecondary = Color(0xFF1E1E24);
  static const Color cpSurface = Color(0xFF16161A);
  static const Color cpOnPrimary = Color(0xFF000000);
}
