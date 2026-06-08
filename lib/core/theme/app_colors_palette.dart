import 'package:flutter/material.dart';

/// Defines the semantic colors required for any Kratos theme.
abstract class AppColorsPalette {
  // ─── Core Colors ───
  Color get primary;
  Color get primaryDark;
  Color get primaryContainer;
  Color get primaryLight;
  Color get primaryDeep;

  // ─── Background & Surface ───
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get card;
  Color get elevated;

  // ─── Neutrals ───
  Color get white;
  Color get black;
  Color get grey50;
  Color get grey100;
  Color get grey200;
  Color get grey300;
  Color get grey400;
  Color get grey500;
  Color get grey600;
  Color get grey700;
  Color get grey800;
  Color get grey900;

  // ─── Functional ───
  Color get success;
  Color get warning;
  Color get error;
  Color get info;

  // ─── Gradients ───
  LinearGradient get primaryGradient;
  LinearGradient get darkOverlay;
  LinearGradient get redFade;
  
  // ─── Glassmorphism ───
  Color get glassCard;
  Color get glassBorder;
  Color get glassInput;
  Color get glassInputBorder;
  Color get glassInputFocused;
  Color get glassInputFocusedBorder;
  
  // ─── Glow ───
  Color get redGlow;
  Color get redGlowSubtle;
  Color get redGlowIntense;
}
