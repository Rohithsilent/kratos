// lib/features/daily_planner/presentation/widgets/planner_stat_chip.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class PlannerStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? glowColor;

  const PlannerStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? context.colors.primary;
    return Expanded(
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with subtle ambient glow backing
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: effectiveGlowColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveGlowColor,
                size: 16,
              ),
            ),
            SizedBox(height: 8),
            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(color: context.colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            SizedBox(height: 2),
            // Label
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.toUpperCase(),
                style: TextStyle(color: context.colors.onSurface.withOpacity(0.38),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
