import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassmorphismExtension extends ThemeExtension<GlassmorphismExtension> {
  final Color cardColor;
  final Color borderColor;
  final Color inputColor;
  final Color inputBorderColor;
  final Color inputFocusedColor;
  final Color inputFocusedBorderColor;

  const GlassmorphismExtension({
    required this.cardColor,
    required this.borderColor,
    required this.inputColor,
    required this.inputBorderColor,
    required this.inputFocusedColor,
    required this.inputFocusedBorderColor,
  });

  @override
  ThemeExtension<GlassmorphismExtension> copyWith({
    Color? cardColor,
    Color? borderColor,
    Color? inputColor,
    Color? inputBorderColor,
    Color? inputFocusedColor,
    Color? inputFocusedBorderColor,
  }) {
    return GlassmorphismExtension(
      cardColor: cardColor ?? this.cardColor,
      borderColor: borderColor ?? this.borderColor,
      inputColor: inputColor ?? this.inputColor,
      inputBorderColor: inputBorderColor ?? this.inputBorderColor,
      inputFocusedColor: inputFocusedColor ?? this.inputFocusedColor,
      inputFocusedBorderColor: inputFocusedBorderColor ?? this.inputFocusedBorderColor,
    );
  }

  @override
  ThemeExtension<GlassmorphismExtension> lerp(
      ThemeExtension<GlassmorphismExtension>? other, double t) {
    if (other is! GlassmorphismExtension) return this;
    return GlassmorphismExtension(
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      inputColor: Color.lerp(inputColor, other.inputColor, t)!,
      inputBorderColor: Color.lerp(inputBorderColor, other.inputBorderColor, t)!,
      inputFocusedColor: Color.lerp(inputFocusedColor, other.inputFocusedColor, t)!,
      inputFocusedBorderColor: Color.lerp(inputFocusedBorderColor, other.inputFocusedBorderColor, t)!,
    );
  }
}

class GlowExtension extends ThemeExtension<GlowExtension> {
  final Color redGlow;
  final Color redGlowSubtle;
  final Color redGlowIntense;

  const GlowExtension({
    required this.redGlow,
    required this.redGlowSubtle,
    required this.redGlowIntense,
  });

  @override
  ThemeExtension<GlowExtension> copyWith({
    Color? redGlow,
    Color? redGlowSubtle,
    Color? redGlowIntense,
  }) {
    return GlowExtension(
      redGlow: redGlow ?? this.redGlow,
      redGlowSubtle: redGlowSubtle ?? this.redGlowSubtle,
      redGlowIntense: redGlowIntense ?? this.redGlowIntense,
    );
  }

  @override
  ThemeExtension<GlowExtension> lerp(ThemeExtension<GlowExtension>? other, double t) {
    if (other is! GlowExtension) return this;
    return GlowExtension(
      redGlow: Color.lerp(redGlow, other.redGlow, t)!,
      redGlowSubtle: Color.lerp(redGlowSubtle, other.redGlowSubtle, t)!,
      redGlowIntense: Color.lerp(redGlowIntense, other.redGlowIntense, t)!,
    );
  }
}


