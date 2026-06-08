import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme_extensions.dart';

class AppTheme {
  AppTheme._();

  // ─── Dark Theme ───
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.darkSurface,
          error: AppColors.error,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.white,
          onError: AppColors.white,
        ),
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: IconThemeData(color: AppColors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
          ),
          hintStyle: GoogleFonts.montserrat(
            color: AppColors.grey500,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          labelStyle: GoogleFonts.montserrat(
            color: AppColors.grey400,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white, size: 24),
        useMaterial3: true,
        extensions: <ThemeExtension<dynamic>>[
          darkGlassmorphism,
          darkGlow,
        ],
      );

  // ─── Light Theme ───
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.primary,
          surface: AppColors.lightSurface,
          error: AppColors.error,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.grey900,
          onError: AppColors.white,
        ),
        textTheme: _buildTextTheme(Brightness.light),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: AppColors.grey900),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryDark.withOpacity(0.6), width: 1.5),
          ),
          hintStyle: GoogleFonts.montserrat(
            color: AppColors.grey400,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        useMaterial3: true,
        extensions: <ThemeExtension<dynamic>>[
          lightGlassmorphism,
          lightGlow,
        ],
      );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark ? AppColors.white : AppColors.grey900;
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
