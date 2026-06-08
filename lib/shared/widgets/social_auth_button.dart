import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SocialAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: context.colors.primary.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ??
                    (isDark ? Colors.white : context.customColors.grey800),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : context.customColors.grey800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
