// lib/features/daily_planner/presentation/controllers/planner_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../data/repositories/planner_repository.dart';
import '../../utils/planner_helpers.dart';
import '../../data/services/planner_sync_service.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../../../core/notifications/notification_service.dart';

class PlannerNotifier extends AsyncNotifier<List<PlannerItem>> {
  @override
  FutureOr<List<PlannerItem>> build() async {
    // 1. Listen to repository stream and keep state synchronized
    final repository = ref.watch(plannerRepositoryProvider);
    
    // Auto-sync completed sessions whenever workoutHistory changes
    ref.listen(workoutHistoryProvider, (previous, next) {
      next.whenData((sessions) async {
        final currentItems = state.value ?? [];
        if (currentItems.isNotEmpty && sessions.isNotEmpty) {
          await ref.read(plannerSyncServiceProvider).syncCompletedSessions(sessions, currentItems);
        }
      });
    });

    final items = await repository.fetchPlannerItems();
    unawaited(NotificationService.instance.syncScheduledWorkouts(items));
    final sessions = await ref.read(workoutRepositoryProvider).getSessions();
    unawaited(NotificationService.instance.syncStreakWarning(sessions));
    return items;
  }

  Future<void> scheduleWorkout({
    required String date,
    required String workoutId,
    required String workoutName,
  }) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      
      // Check if item already exists on this date to replace/update
      final existingItems = await repository.fetchPlannerItems();
      final existing = existingItems.firstWhere(
        (item) => item.date == date,
        orElse: () => PlannerItem(
          id: '',
          date: '',
          status: PlannerStatus.planned,
          createdAt: DateTime.now(),
        ),
      );

      final newItem = existing.id.isNotEmpty
          ? existing.copyWith(
              workoutId: workoutId,
              workoutName: workoutName,
              status: PlannerStatus.planned,
              completed: false,
              clearWorkout: false,
            )
          : PlannerItem(
              id: PlannerHelpers.generateId(),
              date: date,
              workoutId: workoutId,
              workoutName: workoutName,
              status: PlannerStatus.planned,
              completed: false,
              createdAt: DateTime.now(),
            );

      await repository.savePlannerItem(newItem);
      await NotificationService.instance.scheduleWorkoutReminder(
        date: date,
        workoutName: workoutName,
      );
      return repository.fetchPlannerItems();
    });
  }

  Future<void> scheduleRecovery({required String date}) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      
      // Check if item already exists on this date to replace/update
      final existingItems = await repository.fetchPlannerItems();
      final existing = existingItems.firstWhere(
        (item) => item.date == date,
        orElse: () => PlannerItem(
          id: '',
          date: '',
          status: PlannerStatus.planned,
          createdAt: DateTime.now(),
        ),
      );

      final newItem = existing.id.isNotEmpty
          ? existing.copyWith(
              status: PlannerStatus.recovery,
              completed: false,
              clearWorkout: true,
            )
          : PlannerItem(
              id: PlannerHelpers.generateId(),
              date: date,
              status: PlannerStatus.recovery,
              completed: false,
              createdAt: DateTime.now(),
            );

      await repository.savePlannerItem(newItem);
      await NotificationService.instance.cancelWorkoutReminder(date);
      return repository.fetchPlannerItems();
    });
  }

  Future<void> startWorkoutInPlanner({
    required String date,
    required String workoutId,
    required String workoutName,
  }) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      
      final existingItems = await repository.fetchPlannerItems();
      final existing = existingItems.firstWhere(
        (item) => item.date == date,
        orElse: () => PlannerItem(
          id: '',
          date: '',
          status: PlannerStatus.planned,
          createdAt: DateTime.now(),
        ),
      );

      final newItem = existing.id.isNotEmpty
          ? existing.copyWith(
              workoutId: workoutId,
              workoutName: workoutName,
              status: PlannerStatus.active,
              startedAt: DateTime.now(),
            )
          : PlannerItem(
              id: PlannerHelpers.generateId(),
              date: date,
              workoutId: workoutId,
              workoutName: workoutName,
              status: PlannerStatus.active,
              startedAt: DateTime.now(),
              completed: false,
              createdAt: DateTime.now(),
            );

      await repository.savePlannerItem(newItem);
      await NotificationService.instance.cancelWorkoutReminder(date);
      return repository.fetchPlannerItems();
    });
  }

  Future<void> markCompleted({required String itemId}) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      final items = await repository.fetchPlannerItems();
      final index = items.indexWhere((i) => i.id == itemId);
      
      if (index >= 0) {
        final updated = items[index].copyWith(
          status: PlannerStatus.completed,
          completed: true,
          completedAt: DateTime.now(),
        );
        await repository.savePlannerItem(updated);
        await NotificationService.instance.cancelWorkoutReminder(updated.date);
      }
      return repository.fetchPlannerItems();
    });
  }

  Future<void> markSkipped({required String itemId}) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      final items = await repository.fetchPlannerItems();
      final index = items.indexWhere((i) => i.id == itemId);
      
      if (index >= 0) {
        final updated = items[index].copyWith(
          status: PlannerStatus.skipped,
          completed: false,
        );
        await repository.savePlannerItem(updated);
        await NotificationService.instance.cancelWorkoutReminder(updated.date);
      }
      return repository.fetchPlannerItems();
    });
  }

  Future<void> deletePlan({required String itemId}) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      final items = await repository.fetchPlannerItems();
      PlannerItem? item;
      for (final entry in items) {
        if (entry.id == itemId) {
          item = entry;
          break;
        }
      }
      await repository.deletePlannerItem(itemId);
      if (item != null) {
        await NotificationService.instance.cancelWorkoutReminder(item.date);
      }
      return repository.fetchPlannerItems();
    });
  }

  Future<void> duplicateWeek(DateTime sourceWeekRef, DateTime destWeekRef) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(plannerRepositoryProvider);
      final allItems = await repository.fetchPlannerItems();
      
      final sourceDates = PlannerHelpers.getWeekDates(sourceWeekRef);
      final destDates = PlannerHelpers.getWeekDates(destWeekRef);

      final List<PlannerItem> duplicatedItems = [];

      for (int i = 0; i < 7; i++) {
        final srcDateStr = PlannerHelpers.formatDate(sourceDates[i]);
        final destDateStr = PlannerHelpers.formatDate(destDates[i]);

        final matchingSrc = allItems.firstWhere(
          (item) => item.date == srcDateStr,
          orElse: () => PlannerItem(
            id: '',
            date: '',
            status: PlannerStatus.planned,
            createdAt: DateTime.now(),
          ),
        );

        if (matchingSrc.id.isNotEmpty) {
          duplicatedItems.add(
            matchingSrc.copyWith(
              id: PlannerHelpers.generateId(),
              date: destDateStr,
              status: matchingSrc.status == PlannerStatus.completed 
                  ? PlannerStatus.planned 
                  : matchingSrc.status,
              completed: false,
              // Reset daily tracking metrics for the new week
              caloriesConsumed: 0,
              proteinConsumed: 0,
              carbsConsumed: 0,
              fatsConsumed: 0,
              waterConsumed: 0,
            ),
          );
        }
      }

      if (duplicatedItems.isNotEmpty) {
        await repository.saveWeeklyPlan(duplicatedItems);
        await NotificationService.instance.syncScheduledWorkouts(
          duplicatedItems,
        );
      }

      return repository.fetchPlannerItems();
    });
  }

  void updateItemOptimistically(PlannerItem updatedItem) {
    if (state.value != null) {
      final currentList = List<PlannerItem>.from(state.value!);
      final index = currentList.indexWhere((item) => 
          item.id == updatedItem.id || item.date == updatedItem.date);
      
      if (index >= 0) {
        currentList[index] = updatedItem;
      } else {
        currentList.add(updatedItem);
      }
      
      // Update the state immediately
      state = AsyncValue.data(currentList);
    }
  }
}

final plannerListProvider = AsyncNotifierProvider<PlannerNotifier, List<PlannerItem>>(
  PlannerNotifier.new,
);
