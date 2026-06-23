// lib/features/nutrition/presentation/widgets/weekly_calories_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_intelligence_controller.dart';

class WeeklyCaloriesChart extends ConsumerWidget {
  const WeeklyCaloriesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weeklyCalorieTrendProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WEEKLY CALORIES', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 1.8)),
          const SizedBox(height: 20),
          trendAsync.when(
            data: (days) => SizedBox(
              height: 160,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY(days),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    getTooltipItem: (group, gi, rod, ri) {
                      final day = days[group.x];
                      return BarTooltipItem(
                        '${day.dayLabel}\n${day.calories.round()} kcal',
                        TextStyle(color: context.colors.onSurface, fontSize: 10, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        final isToday = idx == days.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[idx].dayLabel,
                            style: TextStyle(
                              color: isToday ? context.colors.primary : context.colors.onSurface.withValues(alpha: 0.25),
                              fontSize: 9,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: days.asMap().entries.map((e) {
                  final isToday = e.key == days.length - 1;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.calories,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: isToday
                            ? LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [context.colors.primary, context.colors.primary.withValues(alpha: 0.7)])
                            : null,
                        color: isToday ? null : context.colors.onSurface.withValues(alpha: 0.08),
                      ),
                    ],
                  );
                }).toList(),
              )),
            ),
            loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (err, st) => SizedBox(height: 160, child: Center(child: Text('Unable to load', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.2), fontSize: 11)))),
          ),
        ],
      ),
    );
  }

  double _maxY(List<DailyCalorieSummary> days) {
    final maxCal = days.fold<double>(0, (m, d) => d.calories > m ? d.calories : m);
    return maxCal > 0 ? maxCal * 1.2 : 2500;
  }
}
