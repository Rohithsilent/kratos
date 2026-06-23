// lib/features/nutrition/presentation/controllers/ai_coach_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/gemini_nutrition_service.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../daily_planner/presentation/controllers/hydration_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class AiCoachState {
  final bool isLoading;
  final String? insight;
  final String? error;
  final List<Map<String, dynamic>>? mealSuggestions;
  final bool isSuggestionsLoading;

  const AiCoachState({
    this.isLoading = false,
    this.insight,
    this.error,
    this.mealSuggestions,
    this.isSuggestionsLoading = false,
  });

  AiCoachState copyWith({
    bool? isLoading,
    String? insight,
    String? error,
    List<Map<String, dynamic>>? mealSuggestions,
    bool? isSuggestionsLoading,
  }) =>
      AiCoachState(
        isLoading: isLoading ?? this.isLoading,
        insight: insight ?? this.insight,
        error: error,
        mealSuggestions: mealSuggestions ?? this.mealSuggestions,
        isSuggestionsLoading: isSuggestionsLoading ?? this.isSuggestionsLoading,
      );
}

class AiCoachNotifier extends Notifier<AiCoachState> {
  @override
  AiCoachState build() => const AiCoachState();

  Future<void> generateInsight() async {
    state = const AiCoachState(isLoading: true);

    try {
      final nutrition = ref.read(todayNutritionProvider);
      final hydration = ref.read(todayHydrationProvider);
      final user = ref.read(profileControllerProvider).value;

      final insight =
          await ref.read(geminiNutritionServiceProvider).generateCoachInsight(
                caloriesConsumed: nutrition.caloriesConsumed,
                caloriesTarget: nutrition.caloriesTarget,
                proteinConsumed: nutrition.proteinConsumed,
                proteinTarget: nutrition.proteinTarget,
                carbsConsumed: nutrition.carbsConsumed,
                carbsTarget: nutrition.carbsTarget,
                fatsConsumed: nutrition.fatsConsumed,
                fatsTarget: nutrition.fatsTarget,
                waterConsumed: hydration.waterConsumed,
                waterTarget: hydration.waterTarget,
                weight: user?.weight,
              );

      if (insight != null) {
        state = AiCoachState(insight: insight);
      } else {
        state = const AiCoachState(
            error: 'Coach unavailable. Check your connection.');
      }
    } catch (e) {
      state = AiCoachState(error: 'Failed: $e');
    }
  }

  Future<void> fetchMealSuggestions() async {
    state = state.copyWith(isSuggestionsLoading: true);

    try {
      final nutrition = ref.read(todayNutritionProvider);
      final remaining = nutrition.caloriesTarget - nutrition.caloriesConsumed;

      final suggestions =
          await ref.read(geminiNutritionServiceProvider).suggestMeals(
                remainingCalories: remaining,
                remainingProtein:
                    nutrition.proteinTarget - nutrition.proteinConsumed,
                remainingCarbs:
                    nutrition.carbsTarget - nutrition.carbsConsumed,
                remainingFats: nutrition.fatsTarget - nutrition.fatsConsumed,
              );

      state = state.copyWith(
        mealSuggestions: suggestions,
        isSuggestionsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isSuggestionsLoading: false);
    }
  }
}

final aiCoachProvider = NotifierProvider<AiCoachNotifier, AiCoachState>(
  AiCoachNotifier.new,
);
