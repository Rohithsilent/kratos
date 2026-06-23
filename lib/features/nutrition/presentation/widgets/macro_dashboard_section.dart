// lib/features/nutrition/presentation/widgets/macro_dashboard_section.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_intelligence_controller.dart';

class MacroDashboardSection extends ConsumerWidget {
  const MacroDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macros = ref.watch(dailyMacroTotalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'TODAY\'S MACROS',
            style: AppTypography.labelBold.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 14),

          // 4 Macro rings
          Row(
            children: [
              _MacroRing(
                label: 'CALORIES',
                consumed: macros.calories,
                target: macros.targetCalories,
                unit: 'kcal',
                progress: macros.caloriePercent,
                color: context.colors.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _MacroRing(
                label: 'PROTEIN',
                consumed: macros.protein,
                target: macros.targetProtein,
                unit: 'g',
                progress: macros.proteinPercent,
                color: const Color(0xFFFF6B6B),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _MacroRing(
                label: 'CARBS',
                consumed: macros.carbs,
                target: macros.targetCarbs,
                unit: 'g',
                progress: macros.carbsPercent,
                color: const Color(0xFFFFB852),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _MacroRing(
                label: 'FATS',
                consumed: macros.fats,
                target: macros.targetFats,
                unit: 'g',
                progress: macros.fatsPercent,
                color: const Color(0xFF52D8FF),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Individual Macro Ring ─────────────────────────────────────────────────────

class _MacroRing extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final double progress;
  final Color color;
  final bool isDark;

  const _MacroRing({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (target - consumed).clamp(0, double.infinity);
    final isOver = consumed > target;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.colors.onSurface.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated ring
            SizedBox(
              width: 52,
              height: 52,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0, 1.0)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(52, 52),
                        painter: _RingPainter(
                          progress: value,
                          color: isOver
                              ? const Color(0xFFEF4444)
                              : color,
                          bgColor: context.colors.onSurface
                              .withValues(alpha: 0.04),
                        ),
                      ),
                      Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          color: isOver
                              ? const Color(0xFFEF4444)
                              : color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Consumed value
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                consumed.round().toString(),
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),

            // Target
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '/ ${target.round()} $unit',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Remaining or Over
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isOver
                        ? const Color(0xFFEF4444)
                        : color)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOver
                    ? '+${(consumed - target).round()}'
                    : '-${remaining.round()}',
                style: TextStyle(
                  color: isOver ? const Color(0xFFEF4444) : color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Label
            Text(
              label,
              style: TextStyle(
                color: context.colors.onSurface.withValues(alpha: 0.25),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
