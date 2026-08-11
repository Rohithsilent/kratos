// lib/features/nutrition/presentation/widgets/nutrition_score_section.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_workflow_controller.dart';

class NutritionScoreSection extends ConsumerWidget {
  const NutritionScoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(nutritionScoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return scoreAsync.when(
      data: (score) => _buildScoreCard(context, score, isDark),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading score')),
    );
  }

  Widget _buildScoreCard(BuildContext context, var score, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.onSurface.withValues(alpha: 0.03)
            : context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _scoreColor(score.score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: _scoreColor(score.score),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NUTRITION SCORE',
                style: AppTypography.labelBold.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              // Grade badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(score.score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _scoreColor(score.score).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  score.grade,
                  style: TextStyle(
                    color: _scoreColor(score.score),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Score ring
          SizedBox(
            width: 140,
            height: 140,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score.score / 100.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
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
                            fontSize: 44,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            color: context.colors.onSurface.withValues(alpha: 0.25),
                            fontSize: 12,
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
          const SizedBox(height: 16),

          // Message
          Text(
            score.message,
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Adherence bars
          Row(
            children: [
              _AdherenceChip(
                label: 'CALORIES',
                value: score.calorieAdherence,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              _AdherenceChip(
                label: 'PROTEIN',
                value: score.proteinAdherence,
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 8),
              _AdherenceChip(
                label: 'HYDRATION',
                value: score.hydrationAdherence,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFFFB852);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Adherence Chip ───────────────────────────────────────────────────────────

class _AdherenceChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AdherenceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: context.colors.onSurface.withValues(alpha: 0.3),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
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
    final radius = (size.width - 12) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );

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
