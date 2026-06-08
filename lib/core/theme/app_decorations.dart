import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'app_theme_extensions.dart';
import 'app_colors.dart';

class AppDecorations {
  AppDecorations._();

  // ─── Glassmorphism ───
  static BoxDecoration glassCard(
    BuildContext context, {
    double borderRadius = 24,
  }) {
    final glassExt = Theme.of(context).extension<GlassmorphismExtension>();
    return BoxDecoration(
      color: glassExt?.cardColor ?? context.glassmorphism.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glassExt?.borderColor ?? context.glassmorphism.borderColor,
        width: 1,
      ),
    );
  }

  static BoxDecoration glassInput(BuildContext context) {
    final glassExt = Theme.of(context).extension<GlassmorphismExtension>();
    return BoxDecoration(
      color: glassExt?.inputColor ?? Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glassExt?.inputBorderColor ?? Colors.white.withOpacity(0.08),
        width: 1,
      ),
    );
  }

  static BoxDecoration glassInputFocused(BuildContext context) {
    final glassExt = Theme.of(context).extension<GlassmorphismExtension>();
    final glowExt = Theme.of(context).extension<GlowExtension>();
    return BoxDecoration(
      color: glassExt?.inputFocusedColor ?? Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glassExt?.inputFocusedBorderColor ?? context.colors.primary.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowExt?.redGlowSubtle ?? context.glow.redGlowSubtle,
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // ─── Glow Button ───
  static BoxDecoration primaryButton(
    BuildContext context, {
    double borderRadius = 16,
  }) {
    final glowExt = Theme.of(context).extension<GlowExtension>();
    return BoxDecoration(
      gradient: context.customColors.primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: glowExt?.redGlow ?? context.glow.redGlow,
          blurRadius: 24,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
      ],
    );
  }

  static BoxDecoration outlineButton(
    BuildContext context, {
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.12),
        width: 1.5,
      ),
    );
  }

  // ─── Red Glow ───
  static BoxShadow redGlowShadow(
    BuildContext context, {
    double blur = 40,
    double opacity = 0.3,
  }) {
    return BoxShadow(
      color: context.colors.primary.withOpacity(opacity),
      blurRadius: blur,
      spreadRadius: 0,
    );
  }

  // ─── Blur Filter ───
  static ImageFilter get glassBlur => ImageFilter.blur(sigmaX: 24, sigmaY: 24);
  static ImageFilter get heavyBlur => ImageFilter.blur(sigmaX: 40, sigmaY: 40);
}
