// lib/features/daily_planner/presentation/controllers/hydration_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planner_controller.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../data/repositories/planner_repository.dart';

class HydrationState {
  final int waterTarget;   // ml
  final int waterConsumed;  // ml

  HydrationState({
    this.waterTarget = 3000,
    this.waterConsumed = 0,
  });

  double get progress => waterTarget > 0
      ? (waterConsumed / waterTarget).clamp(0.0, 1.0)
      : 0.0;

  double get litersConsumed => waterConsumed / 1000.0;
  double get litersTarget => waterTarget / 1000.0;

  int get glassesConsumed => (waterConsumed / 250).floor();
  int get glassesTarget => (waterTarget / 250).ceil();
}

final todayHydrationProvider = Provider<HydrationState>((ref) {
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

      return HydrationState(
        waterTarget: todayItem.waterTarget,
        waterConsumed: todayItem.waterConsumed,
      );
    },
    orElse: () => HydrationState(),
  );
});

class HydrationLogNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addWater(int ml) async {
    final plannerItems = ref.read(plannerListProvider).value ?? [];
    final todayStr = PlannerHelpers.formatDate(DateTime.now());

    final todayItem = plannerItems.firstWhere(
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
      waterConsumed: (todayItem.waterConsumed + ml).clamp(0, todayItem.waterTarget * 2),
    );

    // 1. Optimistic Update (instant UI response)
    ref.read(plannerListProvider.notifier).updateItemOptimistically(updated);

    // 2. Background Save
    try {
      final repository = ref.read(plannerRepositoryProvider);
      await repository.savePlannerItem(updated);
    } catch (e) {
      // If save fails, we should ideally revert the optimistic update,
      // but invalidating will force a fresh fetch to heal the state.
      ref.invalidate(plannerListProvider);
    }
  }
}

final hydrationLogProvider = NotifierProvider<HydrationLogNotifier, void>(
  HydrationLogNotifier.new,
);
