import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors_palette.dart';
import 'app_custom_colors.dart';
import 'app_theme_extensions.dart';

class AppThemeFactory {
  static ThemeData buildTheme(AppColorsPalette palette, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.white,
        secondary: palette.primaryLight,
        onSecondary: palette.white,
        surface: palette.surface,
        onSurface: brightness == Brightness.dark ? palette.white : palette.grey900,
        error: palette.error,
        onError: palette.white,
      ),
      textTheme: _buildTextTheme(palette, brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: brightness == Brightness.dark ? palette.white : palette.grey900),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glassInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.glassInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.glassInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.glassInputFocusedBorder, width: 1.5),
        ),
        hintStyle: GoogleFonts.montserrat(
          color: palette.grey400,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.montserrat(
          color: palette.grey400,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightness == Brightness.dark ? palette.primaryContainer : palette.primaryDark,
          foregroundColor: palette.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: brightness == Brightness.dark ? palette.white : palette.grey900, size: 24),
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[
        GlassmorphismExtension(
          cardColor: palette.glassCard,
          borderColor: palette.glassBorder,
          inputColor: palette.glassInput,
          inputBorderColor: palette.glassInputBorder,
          inputFocusedColor: palette.glassInputFocused,
          inputFocusedBorderColor: palette.glassInputFocusedBorder,
        ),
        GlowExtension(
          redGlow: palette.redGlow,
          redGlowSubtle: palette.redGlowSubtle,
          redGlowIntense: palette.redGlowIntense,
        ),
        AppCustomColors(
          success: palette.success,
          warning: palette.warning,
          info: palette.info,
          grey50: palette.grey50,
          grey100: palette.grey100,
          grey200: palette.grey200,
          grey300: palette.grey300,
          grey400: palette.grey400,
          grey500: palette.grey500,
          grey600: palette.grey600,
          grey700: palette.grey700,
          grey800: palette.grey800,
          grey900: palette.grey900,
          primaryGradient: palette.primaryGradient,
          darkOverlay: palette.darkOverlay,
          redFade: palette.redFade,
        ),
      ],
    );
  }

  static TextTheme _buildTextTheme(AppColorsPalette palette, Brightness brightness) {
    final color = brightness == Brightness.dark ? palette.white : palette.grey900;
    return TextTheme(
      displayLarge: GoogleFonts.barlowCondensed(fontSize: 48, fontWeight: FontWeight.w900, color: color, height: 1.1),
      displayMedium: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w800, color: color, height: 1.15),
      headlineLarge: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w800, color: color, height: 1.2),
      headlineMedium: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.3),
      headlineSmall: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.3),
      bodyLarge: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500, color: color, height: 1.6),
      bodyMedium: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.6),
      bodySmall: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5),
      labelLarge: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5),
      labelMedium: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: color),
      labelSmall: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5),
    );
  }
}
