// lib/features/nutrition/presentation/controllers/meal_log_controller.dart

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/services/gemini_nutrition_service.dart';
import '../../domain/enums/meal_type.dart';
import '../../domain/models/meal_entry_model.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../daily_planner/utils/planner_helpers.dart';

// ── State ────────────────────────────────────────────────────────────────────

class MealScanState {
  final bool isScanning;
  final Map<String, dynamic>? scanResult;
  final String? error;

  const MealScanState({this.isScanning = false, this.scanResult, this.error});

  MealScanState copyWith({
    bool? isScanning,
    Map<String, dynamic>? scanResult,
    String? error,
  }) =>
      MealScanState(
        isScanning: isScanning ?? this.isScanning,
        scanResult: scanResult ?? this.scanResult,
        error: error,
      );
}

// ── Scanner Notifier ─────────────────────────────────────────────────────────

class MealScanNotifier extends Notifier<MealScanState> {
  @override
  MealScanState build() => const MealScanState();

  Future<void> scanImage(Uint8List imageBytes) async {
    state = const MealScanState(isScanning: true);
    try {
      final result = await ref
          .read(geminiNutritionServiceProvider)
          .analyzeFoodImage(imageBytes);
      if (result != null) {
        state = MealScanState(scanResult: result);
      } else {
        state = const MealScanState(
            error: 'Could not identify food. Try a clearer photo.');
      }
    } catch (e) {
      state = MealScanState(error: 'Scan failed: $e');
    }
  }

  Future<void> confirmAndLog() async {
    final result = state.scanResult;
    if (result == null) return;

    final now = DateTime.now();
    final meal = MealEntry(
      id: '${now.microsecondsSinceEpoch}_${now.hashCode % 1000}',
      date: PlannerHelpers.formatDate(now),
      foodName: result['foodName'] as String? ?? 'Unknown',
      calories: (result['calories'] as num?)?.toDouble() ?? 0,
      protein: (result['protein'] as num?)?.toDouble() ?? 0,
      carbs: (result['carbs'] as num?)?.toDouble() ?? 0,
      fats: (result['fats'] as num?)?.toDouble() ?? 0,
      mealType: MealType.fromTimeOfDay(now),
      loggedAt: now,
      source: 'ai_scan',
      servingSize: (result['servingSize'] as num?)?.toDouble(),
    );

    await ref.read(mealRepositoryProvider).saveMeal(meal);

    // Also update the existing planner nutrition totals
    ref.read(nutritionLogProvider.notifier).logMacros(
          calories: meal.calories,
          protein: meal.protein,
          carbs: meal.carbs,
          fats: meal.fats,
        );

    // Invalidate the meal list
    ref.invalidate(todayMealsProvider);

    // Reset scanner
    state = const MealScanState();
  }

  void reset() => state = const MealScanState();
}

final mealScanProvider = NotifierProvider<MealScanNotifier, MealScanState>(
  MealScanNotifier.new,
);

// ── Today's Meals Provider ───────────────────────────────────────────────────

final todayMealsProvider = FutureProvider<List<MealEntry>>((ref) async {
  final today = PlannerHelpers.formatDate(DateTime.now());
  return ref.read(mealRepositoryProvider).fetchMeals(date: today);
});

// ── Grouped Meals Provider (by MealType) ─────────────────────────────────────

final groupedMealsProvider =
    FutureProvider<Map<MealType, List<MealEntry>>>((ref) async {
  final meals = await ref.watch(todayMealsProvider.future);
  final grouped = <MealType, List<MealEntry>>{};
  for (final type in MealType.values) {
    grouped[type] = meals.where((m) => m.mealType == type).toList();
  }
  return grouped;
});

// ── Weekly Meals Provider (last 7 days) ──────────────────────────────────────

final weeklyMealsProvider = FutureProvider<List<MealEntry>>((ref) async {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  return ref.read(mealRepositoryProvider).fetchMealsForDateRange(
        PlannerHelpers.formatDate(start),
        PlannerHelpers.formatDate(now),
      );
});

// ── Manual Meal Logging ──────────────────────────────────────────────────────

class ManualMealNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> logMeal({
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    final now = DateTime.now();
    final meal = MealEntry(
      id: '${now.microsecondsSinceEpoch}_${now.hashCode % 1000}',
      date: PlannerHelpers.formatDate(now),
      foodName: foodName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      mealType: MealType.fromTimeOfDay(now),
      loggedAt: now,
      source: 'manual',
    );

    await ref.read(mealRepositoryProvider).saveMeal(meal);

    ref.read(nutritionLogProvider.notifier).logMacros(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        );

    ref.invalidate(todayMealsProvider);
  }

  Future<void> deleteMeal(MealEntry meal) async {
    await ref.read(mealRepositoryProvider).deleteMeal(meal.id);

    // Subtract macros from planner
    ref.read(nutritionLogProvider.notifier).logMacros(
          calories: -meal.calories,
          protein: -meal.protein,
          carbs: -meal.carbs,
          fats: -meal.fats,
        );

    ref.invalidate(todayMealsProvider);
  }
}

final manualMealProvider = NotifierProvider<ManualMealNotifier, void>(
  ManualMealNotifier.new,
);
