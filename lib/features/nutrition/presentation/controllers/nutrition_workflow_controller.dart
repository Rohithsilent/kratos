import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/services/nutrition_api_service.dart';
import '../../domain/enums/meal_type.dart';
import '../../domain/models/meal_entry_model.dart';
import '../../domain/models/nutrition_score_model.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../daily_planner/presentation/controllers/hydration_controller.dart';
import '../../../daily_planner/utils/planner_helpers.dart';

// ── 1. Nutrition Score Provider ───────────────────────────────────────────────

final nutritionScoreProvider = FutureProvider<NutritionScore>((ref) async {
  final nutrition = ref.watch(todayNutritionProvider);
  final hydration = ref.watch(todayHydrationProvider);

  try {
    final result = await ref.read(nutritionApiServiceProvider).getNutritionScore(
      intake: {
        'calories': nutrition.caloriesConsumed,
        'protein_g': nutrition.proteinConsumed,
        'carbs_g': nutrition.carbsConsumed,
        'fats_g': nutrition.fatsConsumed,
        'water_ml': hydration.waterConsumed,
      },
      targets: {
        'calories': nutrition.caloriesTarget,
        'protein_g': nutrition.proteinTarget,
        'carbs_g': nutrition.carbsTarget,
        'fats_g': nutrition.fatsTarget,
        'water_ml': hydration.waterTarget,
      },
    );

    if (result != null) {
      return NutritionScore(
        calorieAdherence: (result['calorie_adherence'] as num).toDouble(),
        proteinAdherence: (result['protein_adherence'] as num).toDouble(),
        hydrationAdherence: (result['hydration_adherence'] as num).toDouble(),
        score: (result['score'] as num).toInt(),
        customGrade: result['grade'],
        customMessage: result['insight'],
      );
    }
  } catch (e) {
    // Fallback
  }

  return NutritionScore.compute(
    caloriesConsumed: nutrition.caloriesConsumed,
    caloriesTarget: nutrition.caloriesTarget,
    proteinConsumed: nutrition.proteinConsumed,
    proteinTarget: nutrition.proteinTarget,
    waterConsumed: hydration.waterConsumed,
    waterTarget: hydration.waterTarget,
  );
});


// ── 2. AI Coach Notifier ─────────────────────────────────────────────────────

class AiCoachState {
  final bool isLoading;
  final String? insight;
  final String? error;

  const AiCoachState({
    this.isLoading = false,
    this.insight,
    this.error,
  });
}

class AiCoachNotifier extends Notifier<AiCoachState> {
  @override
  AiCoachState build() => const AiCoachState();

  Future<void> generateInsight() async {
    state = const AiCoachState(isLoading: true);

    try {
      final nutrition = ref.read(todayNutritionProvider);
      final hydration = ref.read(todayHydrationProvider);

      final insight = await ref.read(nutritionApiServiceProvider).generateCoachInsight(
        intake: {
          'calories': nutrition.caloriesConsumed,
          'protein_g': nutrition.proteinConsumed,
          'carbs_g': nutrition.carbsConsumed,
          'fats_g': nutrition.fatsConsumed,
          'water_ml': hydration.waterConsumed,
        },
        targets: {
          'calories': nutrition.caloriesTarget,
          'protein_g': nutrition.proteinTarget,
          'carbs_g': nutrition.carbsTarget,
          'fats_g': nutrition.fatsTarget,
          'water_ml': hydration.waterTarget,
        },
      );

      if (insight != null) {
        state = AiCoachState(insight: insight);
      } else {
        state = const AiCoachState(error: 'Coach unavailable. Check your connection.');
      }
    } catch (e) {
      state = AiCoachState(error: 'Failed: $e');
    }
  }
}

final aiCoachProvider = NotifierProvider<AiCoachNotifier, AiCoachState>(
  AiCoachNotifier.new,
);


// ── 3. Food Scanner Notifier ──────────────────────────────────────────────────

class MealScanState {
  final bool isScanning;
  final Map<String, dynamic>? scanResult;
  final String? error;

  const MealScanState({this.isScanning = false, this.scanResult, this.error});
}

class MealScanNotifier extends Notifier<MealScanState> {
  @override
  MealScanState build() => const MealScanState();

  Future<void> scanImage(Uint8List imageBytes) async {
    state = const MealScanState(isScanning: true);
    try {
      final result = await ref
          .read(nutritionApiServiceProvider)
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
    );

    try {
      await ref.read(mealRepositoryProvider).saveMeal(meal);
    } catch (e) {
      print('Failed to sync meal to remote: $e');
    }

    // Always update the existing planner nutrition totals, even if meal sync failed
    await ref.read(nutritionLogProvider.notifier).logMacros(
          calories: meal.calories,
          protein: meal.protein,
          carbs: meal.carbs,
          fats: meal.fats,
        );

    // Invalidate the meal list so UI updates immediately from local cache
    ref.invalidate(todayMealsProvider);
    ref.invalidate(weeklyMealsProvider);

    // Reset scanner
    state = const MealScanState();
  }

  void reset() => state = const MealScanState();
}

final mealScanProvider = NotifierProvider<MealScanNotifier, MealScanState>(
  MealScanNotifier.new,
);


// ── 4. Meal History Providers ─────────────────────────────────────────────────

final todayMealsProvider = FutureProvider<List<MealEntry>>((ref) async {
  ref.watch(authStateProvider); // Re-fetch when auth state resolves
  final today = PlannerHelpers.formatDate(DateTime.now());
  return ref.watch(mealRepositoryProvider).fetchMeals(date: today);
});

final groupedMealsProvider = FutureProvider<Map<MealType, List<MealEntry>>>((ref) async {
  final meals = await ref.watch(todayMealsProvider.future);
  final grouped = <MealType, List<MealEntry>>{};
  for (final type in MealType.values) {
    grouped[type] = meals.where((m) => m.mealType == type).toList();
  }
  return grouped;
});

final weeklyMealsProvider = FutureProvider<List<MealEntry>>((ref) async {
  ref.watch(authStateProvider); // Re-fetch when auth state resolves
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  return ref.read(mealRepositoryProvider).fetchMealsForDateRange(
        PlannerHelpers.formatDate(start),
        PlannerHelpers.formatDate(now),
      );
});


// ── 5. Manual Meal Logging ────────────────────────────────────────────────────

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
    ref.invalidate(weeklyMealsProvider);
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
    ref.invalidate(weeklyMealsProvider);
  }
}

final manualMealProvider = NotifierProvider<ManualMealNotifier, void>(
  ManualMealNotifier.new,
);
