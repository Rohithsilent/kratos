// lib/features/nutrition/presentation/controllers/nutrition_intelligence_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/nutrition_score_model.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../daily_planner/presentation/controllers/hydration_controller.dart';
import 'meal_log_controller.dart';

// ── Nutrition Score Provider ─────────────────────────────────────────────────

final nutritionScoreProvider = Provider<NutritionScore>((ref) {
  final nutrition = ref.watch(todayNutritionProvider);
  final hydration = ref.watch(todayHydrationProvider);

  return NutritionScore.compute(
    caloriesConsumed: nutrition.caloriesConsumed,
    caloriesTarget: nutrition.caloriesTarget,
    proteinConsumed: nutrition.proteinConsumed,
    proteinTarget: nutrition.proteinTarget,
    waterConsumed: hydration.waterConsumed,
    waterTarget: hydration.waterTarget,
  );
});

// ── Daily Macro Totals Provider ──────────────────────────────────────────────

class DailyMacroTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFats;

  const DailyMacroTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
  });

  double get remainingCalories =>
      (targetCalories - calories).clamp(0, double.infinity);
  double get remainingProtein =>
      (targetProtein - protein).clamp(0, double.infinity);
  double get remainingCarbs =>
      (targetCarbs - carbs).clamp(0, double.infinity);
  double get remainingFats =>
      (targetFats - fats).clamp(0, double.infinity);

  double get caloriePercent =>
      targetCalories > 0 ? (calories / targetCalories).clamp(0, 1.5) : 0;
  double get proteinPercent =>
      targetProtein > 0 ? (protein / targetProtein).clamp(0, 1.5) : 0;
  double get carbsPercent =>
      targetCarbs > 0 ? (carbs / targetCarbs).clamp(0, 1.5) : 0;
  double get fatsPercent =>
      targetFats > 0 ? (fats / targetFats).clamp(0, 1.5) : 0;
}

final dailyMacroTotalsProvider = Provider<DailyMacroTotals>((ref) {
  final s = ref.watch(todayNutritionProvider);
  return DailyMacroTotals(
    calories: s.caloriesConsumed,
    protein: s.proteinConsumed,
    carbs: s.carbsConsumed,
    fats: s.fatsConsumed,
    targetCalories: s.caloriesTarget,
    targetProtein: s.proteinTarget,
    targetCarbs: s.carbsTarget,
    targetFats: s.fatsTarget,
  );
});

// ── Weekly Calorie Trend Provider ────────────────────────────────────────────

class DailyCalorieSummary {
  final String date;
  final String dayLabel;
  final double calories;

  DailyCalorieSummary({
    required this.date,
    required this.dayLabel,
    required this.calories,
  });
}

final weeklyCalorieTrendProvider =
    FutureProvider<List<DailyCalorieSummary>>((ref) async {
  final meals = await ref.watch(weeklyMealsProvider.future);
  final now = DateTime.now();
  final dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  final result = <DailyCalorieSummary>[];
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final dayCals = meals
        .where((m) => m.date == dateStr)
        .fold<double>(0, (s, m) => s + m.calories);
    result.add(DailyCalorieSummary(
      date: dateStr,
      dayLabel: dayLabels[day.weekday - 1],
      calories: dayCals,
    ));
  }
  return result;
});

// ── Protein Analysis Provider ────────────────────────────────────────────────

class ProteinAnalysis {
  final double consumed;
  final double target;
  final double remaining;
  final List<String> recommendations;

  ProteinAnalysis({
    required this.consumed,
    required this.target,
    required this.remaining,
    required this.recommendations,
  });
}

final proteinAnalysisProvider = Provider<ProteinAnalysis>((ref) {
  final macros = ref.watch(dailyMacroTotalsProvider);
  final remaining = macros.remainingProtein;

  final recs = <String>[];
  if (remaining > 40) {
    recs.add('200g Chicken Breast (62g protein)');
    recs.add('3 Whole Eggs (18g protein)');
    recs.add('Greek Yogurt Bowl (20g protein)');
  } else if (remaining > 20) {
    recs.add('150g Paneer Tikka (27g protein)');
    recs.add('Whey Protein Shake (25g protein)');
  } else if (remaining > 0) {
    recs.add('2 Boiled Eggs (12g protein)');
    recs.add('Cup of Dal (9g protein)');
  }

  return ProteinAnalysis(
    consumed: macros.protein,
    target: macros.targetProtein,
    remaining: remaining,
    recommendations: recs,
  );
});
