// lib/features/daily_planner/presentation/controllers/today_mission_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planner_controller.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../../workout/domain/models/workout_model.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';

class TodayMissionState {
  final PlannerItem? plannerItem;
  final Workout? workout;
  final bool isRecovery;

  TodayMissionState({
    this.plannerItem,
    this.workout,
    this.isRecovery = false,
  });
}

final todayMissionProvider = Provider<TodayMissionState>((ref) {
  final plannerItemsAsync = ref.watch(plannerListProvider);
  final workoutsAsync = ref.watch(workoutListProvider);

  return plannerItemsAsync.maybeWhen(
    data: (plannerItems) {
      return workoutsAsync.maybeWhen(
        data: (workouts) {
          final todayDateStr = PlannerHelpers.formatDate(DateTime.now());
          final todayItem = plannerItems.firstWhere(
            (item) => item.date == todayDateStr,
            orElse: () => PlannerItem(
              id: '',
              date: todayDateStr,
              status: PlannerStatus.recovery, // Default to recovery if not explicitly planned
              completed: false,
              createdAt: DateTime.now(),
            ),
          );

          if (todayItem.status == PlannerStatus.recovery) {
            return TodayMissionState(
              plannerItem: todayItem,
              workout: null,
              isRecovery: true,
            );
          }

          if (todayItem.workoutId != null) {
            final workout = workouts.firstWhere(
              (w) => w.id == todayItem.workoutId,
              orElse: () => Workout(
                id: '',
                userId: '',
                name: todayItem.workoutName ?? 'Scheduled Workout',
                split: 'Push',
                createdAt: DateTime.now(),
                exercises: [],
              ),
            );
            
            if (workout.id.isEmpty) {
              // Workout template was deleted
              return TodayMissionState(
                plannerItem: todayItem,
                workout: null,
                isRecovery: true,
              );
            }

            return TodayMissionState(
              plannerItem: todayItem,
              workout: workout,
              isRecovery: false,
            );
          }

          return TodayMissionState(
            plannerItem: todayItem,
            workout: null,
            isRecovery: true,
          );
        },
        orElse: () => TodayMissionState(isRecovery: true),
      );
    },
    orElse: () => TodayMissionState(isRecovery: true),
  );
});
