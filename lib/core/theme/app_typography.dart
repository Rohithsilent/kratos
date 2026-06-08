import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // ─── Display (Hero headlines) ───
  static TextStyle get display => GoogleFonts.barlowCondensed(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -1.5,
      );

  static TextStyle get displaySmall => GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -1.0,
      );

  // ─── Headlines ───
  static TextStyle get headlineLarge => GoogleFonts.barlowCondensed(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  // ─── Body ───
  static TextStyle get bodyLarge => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ─── Labels ───
  static TextStyle get labelBold => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 1.5,
      );

  static TextStyle get labelMedium => GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get labelSmall => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
      );

  // ─── Special ───
  static TextStyle get button => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.8,
      );

  static TextStyle get caption => GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle get metric => GoogleFonts.barlowCondensed(
        fontSize: 64,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -2.0,
      );

  static TextStyle get metricUnit => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.0,
      );
}
