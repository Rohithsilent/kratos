// lib/features/nutrition/presentation/widgets/protein_analysis_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_intelligence_controller.dart';

class ProteinAnalysisSection extends ConsumerWidget {
  const ProteinAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(proteinAnalysisProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress =
        analysis.target > 0 ? (analysis.consumed / analysis.target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFFF6B6B).withValues(alpha: 0.04)
            : const Color(0xFFFF6B6B).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: isDark ? 0.12 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROTEIN ANALYSIS',
                      style: AppTypography.labelBold.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${analysis.consumed.round()}g',
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${analysis.target.round()}g',
                            style: TextStyle(
                              color: context.colors.onSurface.withValues(alpha: 0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Remaining badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: analysis.remaining > 0
                      ? const Color(0xFFFFB852).withValues(alpha: 0.12)
                      : const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: analysis.remaining > 0
                        ? const Color(0xFFFFB852).withValues(alpha: 0.25)
                        : const Color(0xFF22C55E).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  analysis.remaining > 0
                      ? '${analysis.remaining.round()}g left'
                      : 'Goal met!',
                  style: TextStyle(
                    color: analysis.remaining > 0
                        ? const Color(0xFFFFB852)
                        : const Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  color: const Color(0xFFFF6B6B),
                  backgroundColor: context.colors.onSurface.withValues(alpha: 0.04),
                  minHeight: 6,
                );
              },
            ),
          ),

          if (analysis.recommendations.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'RECOMMENDED FOODS',
              style: TextStyle(
                color: context.colors.onSurface.withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            ...analysis.recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF22C55E),
                          size: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
