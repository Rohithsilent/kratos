// lib/features/nutrition/presentation/widgets/nutrition_score_section.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_workflow_controller.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../../core/widgets/shimmer_effect.dart';

class NutritionScoreSection extends ConsumerWidget {
  const NutritionScoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(nutritionScoreProvider);
    final nutritionState = ref.watch(todayNutritionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return scoreAsync.when(
      data: (score) => _buildScoreCard(context, score, nutritionState, isDark),
      loading: () => _NutritionScoreSkeleton(isDark: isDark),
      error: (err, stack) => const Center(child: Text('Error loading score')),
    );
  }

  Widget _buildScoreCard(BuildContext context, var score, NutritionState nutritionState, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.onSurface.withValues(alpha: 0.03)
            : context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Side: Score
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TODAY\'S NUTRITION',
                    style: AppTypography.labelBold.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.8),
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score.score / 100.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(100, 100),
                              painter: _ScoreRingPainter(
                                progress: value,
                                color: _scoreColor(score.score),
                                bgColor: context.colors.onSurface.withValues(alpha: 0.04),
                                isDark: isDark,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(value * 100).round()}',
                                  style: AppTypography.metric.copyWith(
                                    color: context.colors.onSurface,
                                    fontSize: 32,
                                  ),
                                ),
                                Text(
                                  '/ 100',
                                  style: TextStyle(
                                    color: context.colors.onSurface.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _scoreColor(score.score).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score.grade.toUpperCase(),
                      style: TextStyle(
                        color: _scoreColor(score.score),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: VerticalDivider(
                color: context.colors.onSurface.withValues(alpha: 0.05),
                thickness: 1,
                width: 1,
              ),
            ),

            // Right Side: Macros
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MacroBar(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calories',
                    consumed: nutritionState.caloriesConsumed,
                    target: nutritionState.caloriesTarget,
                    unit: 'kcal',
                    color: const Color(0xFFEF4444), // Red
                  ),
                  _MacroBar(
                    icon: Icons.fitness_center_rounded,
                    label: 'Protein',
                    consumed: nutritionState.proteinConsumed,
                    target: nutritionState.proteinTarget,
                    unit: 'g',
                    color: const Color(0xFF3B82F6), // Blue
                  ),
                  _MacroBar(
                    icon: Icons.eco_rounded,
                    label: 'Carbs',
                    consumed: nutritionState.carbsConsumed,
                    target: nutritionState.carbsTarget,
                    unit: 'g',
                    color: const Color(0xFF10B981), // Green
                  ),
                  _MacroBar(
                    icon: Icons.water_drop_rounded,
                    label: 'Fats',
                    consumed: nutritionState.fatsConsumed,
                    target: nutritionState.fatsTarget,
                    unit: 'g',
                    color: const Color(0xFFF59E0B), // Orange/Amber
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFFEF4444); // Reddish color like image for high score? Or 0xFF22C55E for green? The image shows red for 78 score. I'll use standard colors.
    // Wait, the image shows a red ring for a score of 78, which says "GOOD". Let's match the image's styling by using a standard scale.
    if (score >= 80) return const Color(0xFF22C55E); // Green
    if (score >= 70) return const Color(0xFFEF4444); // Red/Orange like image
    if (score >= 60) return const Color(0xFFFFB852); // Amber
    return const Color(0xFFEF4444); // Red
  }
}

class _MacroBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;

  const _MacroBar({
    required this.icon,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${consumed.round()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / ${target.round()} $unit',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Ring Painter ────────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final bool isDark;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6;

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
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Skeleton Loader ───────────────────────────────────────────────────────────

class _NutritionScoreSkeleton extends StatelessWidget {
  final bool isDark;

  const _NutritionScoreSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Side: Score
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShimmerEffect(width: 80, height: 12),
                  const SizedBox(height: 16),
                  const ShimmerEffect(width: 100, height: 100, shape: BoxShape.circle),
                  const SizedBox(height: 12),
                  const ShimmerEffect(width: 50, height: 16, borderRadius: BorderRadius.all(Radius.circular(12))),
                  const SizedBox(height: 8),
                  const ShimmerEffect(width: 90, height: 10),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: VerticalDivider(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                thickness: 1,
                width: 1,
              ),
            ),

            // Right Side: Macros
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildSkeletonMacroBar()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonMacroBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ShimmerEffect(width: 26, height: 26, borderRadius: BorderRadius.all(Radius.circular(8))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerEffect(width: 40, height: 8),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerEffect(width: 50, height: 12),
                    ShimmerEffect(width: 20, height: 10),
                  ],
                ),
                const SizedBox(height: 6),
                const ShimmerEffect(width: double.infinity, height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

