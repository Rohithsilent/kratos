import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_palette.dart';

class DarkPalette implements AppColorsPalette {
  @override Color get primary => AppColors.primary;
  @override Color get primaryDark => AppColors.primaryDark;
  @override Color get primaryContainer => AppColors.primaryContainer;
  @override Color get primaryLight => AppColors.primaryLight;
  @override Color get primaryDeep => AppColors.primaryDeep;

  @override Color get background => AppColors.darkBg;
  @override Color get surface => AppColors.darkSurface;
  @override Color get surfaceVariant => AppColors.darkSurfaceVariant;
  @override Color get card => AppColors.darkCard;
  @override Color get elevated => AppColors.darkElevated;

  @override Color get white => AppColors.white;
  @override Color get black => AppColors.black;
  @override Color get grey50 => AppColors.grey50;
  @override Color get grey100 => AppColors.grey100;
  @override Color get grey200 => AppColors.grey200;
  @override Color get grey300 => AppColors.grey300;
  @override Color get grey400 => AppColors.grey400;
  @override Color get grey500 => AppColors.grey500;
  @override Color get grey600 => AppColors.grey600;
  @override Color get grey700 => AppColors.grey700;
  @override Color get grey800 => AppColors.grey800;
  @override Color get grey900 => AppColors.grey900;

  @override Color get success => AppColors.success;
  @override Color get warning => AppColors.warning;
  @override Color get error => AppColors.error;
  @override Color get info => AppColors.info;

  @override LinearGradient get primaryGradient => AppColors.primaryGradient;
  @override LinearGradient get darkOverlay => AppColors.darkOverlay;
  @override LinearGradient get redFade => AppColors.redFade;

  @override Color get glassCard => AppColors.glassDark;
  @override Color get glassBorder => AppColors.glassBorderDark;
  @override Color get glassInput => AppColors.white.withOpacity(0.04);
  @override Color get glassInputBorder => AppColors.white.withOpacity(0.08);
  @override Color get glassInputFocused => AppColors.white.withOpacity(0.06);
  @override Color get glassInputFocusedBorder => AppColors.primary.withOpacity(0.6);

  @override Color get redGlow => AppColors.redGlow;
  @override Color get redGlowSubtle => AppColors.redGlowSubtle;
  @override Color get redGlowIntense => AppColors.redGlowIntense;

  @override Color get onPrimary => AppColors.white;
}

class LightPalette implements AppColorsPalette {
  @override Color get primary => AppColors.primary;
  @override Color get primaryDark => AppColors.primaryDark;
  @override Color get primaryContainer => AppColors.primaryContainer;
  @override Color get primaryLight => AppColors.primaryLight;
  @override Color get primaryDeep => AppColors.primaryDeep;

  @override Color get background => AppColors.lightBg;
  @override Color get surface => AppColors.lightSurface;
  @override Color get surfaceVariant => AppColors.lightSurfaceVariant;
  @override Color get card => AppColors.lightCard;
  @override Color get elevated => AppColors.white;

  @override Color get white => AppColors.white;
  @override Color get black => AppColors.black;
  @override Color get grey50 => AppColors.grey50;
  @override Color get grey100 => AppColors.grey100;
  @override Color get grey200 => AppColors.grey200;
  @override Color get grey300 => AppColors.grey300;
  @override Color get grey400 => AppColors.grey400;
  @override Color get grey500 => AppColors.grey500;
  @override Color get grey600 => AppColors.grey600;
  @override Color get grey700 => AppColors.grey700;
  @override Color get grey800 => AppColors.grey800;
  @override Color get grey900 => AppColors.grey900;

  @override Color get success => AppColors.success;
  @override Color get warning => AppColors.warning;
  @override Color get error => AppColors.error;
  @override Color get info => AppColors.info;

  @override LinearGradient get primaryGradient => AppColors.primaryGradient;
  @override LinearGradient get darkOverlay => AppColors.darkOverlay;
  @override LinearGradient get redFade => AppColors.redFade;

  @override Color get glassCard => AppColors.glassLight;
  @override Color get glassBorder => AppColors.glassBorderLight;
  @override Color get glassInput => AppColors.black.withOpacity(0.03);
  @override Color get glassInputBorder => AppColors.black.withOpacity(0.06);
  @override Color get glassInputFocused => AppColors.white;
  @override Color get glassInputFocusedBorder => AppColors.primary.withOpacity(0.6);

  @override Color get redGlow => AppColors.redGlow.withOpacity(0.15);
  @override Color get redGlowSubtle => AppColors.redGlowSubtle.withOpacity(0.05);
  @override Color get redGlowIntense => AppColors.redGlowIntense.withOpacity(0.3);

  @override Color get onPrimary => AppColors.white;
}

class SuperSaiyanPalette implements AppColorsPalette {
  @override Color get primary => AppColors.ssPrimary;
  @override Color get primaryDark => AppColors.ssPrimary;
  @override Color get primaryContainer => AppColors.ssSecondary;
  @override Color get primaryLight => AppColors.ssSecondary;
  @override Color get primaryDeep => AppColors.ssPrimary;

  @override Color get background => AppColors.ssScaffold;
  @override Color get surface => AppColors.ssSurface;
  @override Color get surfaceVariant => AppColors.ssSurface;
  @override Color get card => AppColors.ssSurface;
  @override Color get elevated => AppColors.ssSurface;

  @override Color get white => AppColors.white;
  @override Color get black => AppColors.black;
  @override Color get grey50 => AppColors.grey50;
  @override Color get grey100 => AppColors.grey100;
  @override Color get grey200 => AppColors.grey200;
  @override Color get grey300 => AppColors.grey300;
  @override Color get grey400 => AppColors.grey400;
  @override Color get grey500 => AppColors.grey500;
  @override Color get grey600 => AppColors.grey600;
  @override Color get grey700 => AppColors.grey700;
  @override Color get grey800 => AppColors.grey800;
  @override Color get grey900 => AppColors.grey900;

  @override Color get success => AppColors.success;
  @override Color get warning => AppColors.warning;
  @override Color get error => AppColors.error;
  @override Color get info => AppColors.info;

  @override LinearGradient get primaryGradient => AppColors.ssPrimaryGradient;
  @override LinearGradient get darkOverlay => AppColors.darkOverlay;
  @override LinearGradient get redFade => AppColors.redFade;

  @override Color get glassCard => AppColors.glassBlue;
  @override Color get glassBorder => AppColors.glassBlueBorder;
  @override Color get glassInput => AppColors.white.withOpacity(0.10);
  @override Color get glassInputBorder => AppColors.glassBlueBorder;
  @override Color get glassInputFocused => AppColors.white.withOpacity(0.16);
  @override Color get glassInputFocusedBorder => AppColors.ssPrimary.withOpacity(0.6);

  @override Color get redGlow => AppColors.ssPrimary.withOpacity(0.35);
  @override Color get redGlowSubtle => AppColors.ssPrimary.withOpacity(0.15);
  @override Color get redGlowIntense => AppColors.ssPrimary.withOpacity(0.6);

  @override Color get onPrimary => AppColors.white;
}

class CyberpunkPalette implements AppColorsPalette {
  @override Color get primary => AppColors.cpPrimary;
  @override Color get primaryDark => AppColors.cpPrimary;
  @override Color get primaryContainer => AppColors.cpSecondary;
  @override Color get primaryLight => AppColors.cpPrimary;
  @override Color get primaryDeep => AppColors.cpPrimary;

  @override Color get background => AppColors.cpScaffold;
  @override Color get surface => AppColors.cpSurface;
  @override Color get surfaceVariant => AppColors.cpSurface;
  @override Color get card => AppColors.cpSurface;
  @override Color get elevated => AppColors.cpSurface;

  @override Color get white => AppColors.white;
  @override Color get black => AppColors.black;
  @override Color get grey50 => AppColors.grey50;
  @override Color get grey100 => AppColors.grey100;
  @override Color get grey200 => AppColors.grey200;
  @override Color get grey300 => AppColors.grey300;
  @override Color get grey400 => AppColors.grey400;
  @override Color get grey500 => AppColors.grey500;
  @override Color get grey600 => AppColors.grey600;
  @override Color get grey700 => AppColors.grey700;
  @override Color get grey800 => AppColors.grey800;
  @override Color get grey900 => AppColors.grey900;

  @override Color get success => AppColors.success;
  @override Color get warning => AppColors.warning;
  @override Color get error => AppColors.error;
  @override Color get info => AppColors.info;

  @override LinearGradient get primaryGradient => AppColors.cpPrimaryGradient;
  @override LinearGradient get darkOverlay => AppColors.darkOverlay;
  @override LinearGradient get redFade => AppColors.redFade;

  @override Color get glassCard => AppColors.glassDark;
  @override Color get glassBorder => AppColors.glassBorderDark;
  @override Color get glassInput => AppColors.white.withOpacity(0.04);
  @override Color get glassInputBorder => AppColors.white.withOpacity(0.08);
  @override Color get glassInputFocused => AppColors.white.withOpacity(0.06);
  @override Color get glassInputFocusedBorder => AppColors.cpPrimary.withOpacity(0.6);

  @override Color get redGlow => AppColors.cpPrimary.withOpacity(0.35);
  @override Color get redGlowSubtle => AppColors.cpPrimary.withOpacity(0.15);
  @override Color get redGlowIntense => AppColors.cpPrimary.withOpacity(0.6);

  @override Color get onPrimary => AppColors.cpOnPrimary;
}
