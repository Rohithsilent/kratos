// lib/features/nutrition/presentation/widgets/macro_pie_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_intelligence_controller.dart';

class MacroPieChart extends ConsumerWidget {
  const MacroPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macros = ref.watch(dailyMacroTotalsProvider);
    final total = macros.protein + macros.carbs + macros.fats;

    final proteinPct = total > 0 ? (macros.protein / total * 100).round() : 0;
    final carbsPct = total > 0 ? (macros.carbs / total * 100).round() : 0;
    final fatsPct = total > 0 ? (100 - proteinPct - carbsPct) : 0;

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
          Text('MACRO BREAKDOWN', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 1.8)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120, height: 120,
                child: total > 0
                    ? PieChart(PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 30,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(value: macros.protein, color: const Color(0xFFFF6B6B), radius: 24, showTitle: false),
                          PieChartSectionData(value: macros.carbs, color: const Color(0xFFFFB852), radius: 24, showTitle: false),
                          PieChartSectionData(value: macros.fats, color: const Color(0xFF52D8FF), radius: 24, showTitle: false),
                        ],
                      ))
                    : Center(child: Text('No data', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.2), fontSize: 11))),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(color: const Color(0xFFFF6B6B), label: 'Protein', value: '${macros.protein.round()}g', pct: '$proteinPct%'),
                    const SizedBox(height: 12),
                    _LegendItem(color: const Color(0xFFFFB852), label: 'Carbs', value: '${macros.carbs.round()}g', pct: '$carbsPct%'),
                    const SizedBox(height: 12),
                    _LegendItem(color: const Color(0xFF52D8FF), label: 'Fats', value: '${macros.fats.round()}g', pct: '$fatsPct%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String pct;
  const _LegendItem({required this.color, required this.label, required this.value, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600))),
      Text(value, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w800)),
      const SizedBox(width: 6),
      Text(pct, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    ]);
  }
}
