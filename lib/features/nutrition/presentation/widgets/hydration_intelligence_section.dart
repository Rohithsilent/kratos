// lib/features/nutrition/presentation/widgets/hydration_intelligence_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../daily_planner/presentation/controllers/hydration_controller.dart';

class HydrationIntelligenceSection extends ConsumerWidget {
  const HydrationIntelligenceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(todayHydrationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hydrationPercent = (hydration.progress * 100).round();
    final remaining =
        ((hydration.waterTarget - hydration.waterConsumed) / 1000.0)
            .clamp(0.0, 10.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1A2E).withValues(alpha: 0.6)
            : const Color(0xFF3B82F6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.15 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF60A5FA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HYDRATION INTELLIGENCE',
                      style: AppTypography.labelBold.copyWith(
                        color: context.colors.onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hydration Score',
                      style: TextStyle(
                        color: context.colors.onSurface
                            .withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      const Color(0xFF60A5FA).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$hydrationPercent%',
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: hydration.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.colors.onSurface
                            .withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF60A5FA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${hydration.litersConsumed.toStringAsFixed(1)} L consumed',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Target: ${hydration.litersTarget.toStringAsFixed(1)} L',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Insight cards
          Row(
            children: [
              _InsightPill(
                icon: Icons.trending_up_rounded,
                text: remaining > 0
                    ? 'Drink ${remaining.toStringAsFixed(1)}L more'
                    : 'Goal reached!',
                color: remaining > 0
                    ? const Color(0xFFFFB852)
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              _InsightPill(
                icon: Icons.local_drink_rounded,
                text:
                    '${hydration.glassesConsumed}/${hydration.glassesTarget} glasses',
                color: const Color(0xFF60A5FA),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick add row
          Row(
            children: [
              Expanded(
                child: _QuickAddButton(
                  label: '+250ml',
                  onTap: () {
                    ref
                        .read(hydrationLogProvider.notifier)
                        .addWater(250);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAddButton(
                  label: '+500ml',
                  onTap: () {
                    ref
                        .read(hydrationLogProvider.notifier)
                        .addWater(500);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAddButton(
                  label: '+1L',
                  onTap: () {
                    ref
                        .read(hydrationLogProvider.notifier)
                        .addWater(1000);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Insight Pill ─────────────────────────────────────────────────────────────

class _InsightPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InsightPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Add Button ─────────────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
