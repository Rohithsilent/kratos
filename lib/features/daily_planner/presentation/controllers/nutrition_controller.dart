// lib/features/daily_planner/presentation/controllers/nutrition_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planner_controller.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../data/repositories/planner_repository.dart';

class NutritionState {
  final double caloriesTarget;
  final double caloriesConsumed;
  final double proteinTarget;
  final double proteinConsumed;
  final double carbsTarget;
  final double carbsConsumed;
  final double fatsTarget;
  final double fatsConsumed;

  NutritionState({
    this.caloriesTarget = 2200,
    this.caloriesConsumed = 0,
    this.proteinTarget = 150,
    this.proteinConsumed = 0,
    this.carbsTarget = 250,
    this.carbsConsumed = 0,
    this.fatsTarget = 70,
    this.fatsConsumed = 0,
  });

  double get caloriesProgress => caloriesTarget > 0
      ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0)
      : 0.0;
  double get proteinProgress => proteinTarget > 0
      ? (proteinConsumed / proteinTarget).clamp(0.0, 1.0)
      : 0.0;
  double get carbsProgress => carbsTarget > 0
      ? (carbsConsumed / carbsTarget).clamp(0.0, 1.0)
      : 0.0;
  double get fatsProgress => fatsTarget > 0
      ? (fatsConsumed / fatsTarget).clamp(0.0, 1.0)
      : 0.0;
}

final todayNutritionProvider = Provider<NutritionState>((ref) {
  final plannerItemsAsync = ref.watch(plannerListProvider);
  final todayStr = PlannerHelpers.formatDate(DateTime.now());

  return plannerItemsAsync.maybeWhen(
    data: (items) {
      final todayItem = items.firstWhere(
        (item) => item.date == todayStr,
        orElse: () => PlannerItem(
          id: '',
          date: todayStr,
          status: PlannerStatus.planned,
          createdAt: DateTime.now(),
        ),
      );

      return NutritionState(
        caloriesTarget: todayItem.caloriesTarget,
        caloriesConsumed: todayItem.caloriesConsumed,
        proteinTarget: todayItem.proteinTarget,
        proteinConsumed: todayItem.proteinConsumed,
        carbsTarget: todayItem.carbsTarget,
        carbsConsumed: todayItem.carbsConsumed,
        fatsTarget: todayItem.fatsTarget,
        fatsConsumed: todayItem.fatsConsumed,
      );
    },
    orElse: () => NutritionState(),
  );
});

/// Utility provider to log a macro entry for today's planner item
class NutritionLogNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> logMacros({
    double calories = 0,
    double protein = 0,
    double carbs = 0,
    double fats = 0,
  }) async {
    final repository = ref.read(plannerRepositoryProvider);
    final items = await repository.fetchPlannerItems();
    final todayStr = PlannerHelpers.formatDate(DateTime.now());

    final todayItem = items.firstWhere(
      (item) => item.date == todayStr,
      orElse: () => PlannerItem(
        id: PlannerHelpers.generateId(),
        date: todayStr,
        status: PlannerStatus.planned,
        createdAt: DateTime.now(),
      ),
    );

    final updated = todayItem.copyWith(
      id: todayItem.id.isEmpty ? PlannerHelpers.generateId() : todayItem.id,
      caloriesConsumed: todayItem.caloriesConsumed + calories,
      proteinConsumed: todayItem.proteinConsumed + protein,
      carbsConsumed: todayItem.carbsConsumed + carbs,
      fatsConsumed: todayItem.fatsConsumed + fats,
    );

    await repository.savePlannerItem(updated);
    ref.invalidate(plannerListProvider);
  }
}

final nutritionLogProvider = NotifierProvider<NutritionLogNotifier, void>(
  NutritionLogNotifier.new,
);
