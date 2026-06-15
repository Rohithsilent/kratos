// lib/features/daily_planner/presentation/widgets/consistency_heatmap.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/planner_controller.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';

/// GitHub/LeetCode-style contribution heatmap styled for KRATOS.
/// Shows 12 weeks (84 days) of training consistency in a dark crimson matrix.
class ConsistencyHeatmap extends ConsumerWidget {
  const ConsistencyHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerItemsAsync = ref.watch(plannerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONSISTENCY MATRIX',
                style: AppTypography.labelBold.copyWith(
                  color: context.colors.onSurface,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '12 WEEKS',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),

        // Heatmap grid
        plannerItemsAsync.when(
          loading: () => SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: context.colors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (err, st) => SizedBox.shrink(),
          data: (items) => _HeatmapGrid(items: items),
        ),

        // Legend
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              ...List.generate(5, (i) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(i / 4.0, context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final List items;

  const _HeatmapGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    // Build a map of date -> intensity (0.0 to 1.0)
    final Map<String, double> intensityMap = {};

    for (var item in items) {
      double intensity = 0.0;

      // Workout completion = base 0.6
      if (item.completed) {
        intensity += 0.6;
      } else if (item.status == PlannerStatus.planned && item.workoutId != null) {
        intensity += 0.15; // Planned but not yet done
      }

      // Hydration adherence bonus
      if (item.waterTarget > 0 && item.waterConsumed > 0) {
        intensity += 0.2 * (item.waterConsumed / item.waterTarget).clamp(0.0, 1.0);
      }

      // Nutrition adherence bonus
      if (item.caloriesTarget > 0 && item.caloriesConsumed > 0) {
        intensity += 0.2 * (item.caloriesConsumed / item.caloriesTarget).clamp(0.0, 1.0);
      }

      intensityMap[item.date] = intensity.clamp(0.0, 1.0);
    }

    final today = DateTime.now();
    // Generate 12 weeks of dates ending at this week's Sunday
    final int todayWeekday = today.weekday; // Mon=1
    final DateTime thisSunday = today.add(Duration(days: 7 - todayWeekday));
    final DateTime startMonday = thisSunday.subtract(Duration(days: 12 * 7 - 1));

    // Build column data (each column = 1 week = 7 days, Mon at top)
    int totalWeeks = 12;
    double cellSize = 12;
    double cellSpacing = 3;

    // Day labels
    final dayLabels = ['M', '', 'W', '', 'F', '', 'S'];

    return SizedBox(
      height: 7 * (cellSize + cellSpacing) + 20, // grid + month labels
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day-of-week labels
            Padding(
              padding: EdgeInsets.only(top: 18),
              child: Column(
                children: List.generate(7, (row) {
                  return Container(
                    height: cellSize + cellSpacing,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 6),
                    child: Text(
                      dayLabels[row],
                      style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.2),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                reverse: true, // Most recent on the right
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels
                    SizedBox(
                      height: 16,
                      child: Row(
                        children: _buildMonthLabels(
                          context, startMonday, totalWeeks, cellSize, cellSpacing,
                        ),
                      ),
                    ),
                    SizedBox(height: 2),
                    // Cell grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(totalWeeks, (weekIndex) {
                        return Column(
                          children: List.generate(7, (dayIndex) {
                            final date = startMonday.add(
                              Duration(days: weekIndex * 7 + dayIndex),
                            );
                            final dateStr = PlannerHelpers.formatDate(date);
                            final isFuture = date.isAfter(today);
                            final isToday = dateStr == PlannerHelpers.formatDate(today);
                            final intensity = isFuture ? -1.0 : (intensityMap[dateStr] ?? 0.0);

                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin: EdgeInsets.all(cellSpacing / 2),
                              decoration: BoxDecoration(
                                color: isFuture
                                    ? context.colors.onSurface.withValues(alpha: 0.02)
                                    : _getIntensityColor(intensity, context),
                                borderRadius: BorderRadius.circular(2.5),
                                border: isToday
                                    ? Border.all(
                                        color: context.colors.primary.withOpacity(0.8),
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(
    BuildContext context, DateTime start, int totalWeeks, double cellSize, double cellSpacing,
  ) {
    final List<Widget> labels = [];
    String? lastMonth;
    final colWidth = cellSize + cellSpacing;

    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      final monthStr = _monthName(weekStart.month);

      if (monthStr != lastMonth) {
        labels.add(
          SizedBox(
            width: colWidth,
            child: Text(
              monthStr,
              style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        lastMonth = monthStr;
      } else {
        labels.add(SizedBox(width: colWidth));
      }
    }
    return labels;
  }

  String _monthName(int month) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

Color _getIntensityColor(double intensity, BuildContext context) {
  if (intensity <= 0.0) return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : context.colors.onSurface.withValues(alpha: 0.05);
  if (intensity <= 0.25) return const Color(0xFF3D0A0A);
  if (intensity <= 0.50) return const Color(0xFF6B1515);
  if (intensity <= 0.75) return const Color(0xFF9B1E1E);
  return const Color(0xFFE53535);
}
