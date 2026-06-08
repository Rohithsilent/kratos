// lib/features/daily_planner/data/services/planner_sync_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workout/domain/models/workout_model.dart';
import '../repositories/planner_repository.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';

class PlannerSyncService {
  final Ref _ref;

  PlannerSyncService(this._ref);

  /// Synchronizes planner items with completed workout sessions.
  /// If a workout session was completed on a specific day, and there's a planned
  /// item for that workout on that day, we mark it completed.
  /// If there's no planned item, we dynamically auto-create a completed planner item.
  Future<void> syncCompletedSessions(List<WorkoutSession> sessions, List<PlannerItem> plannerItems) async {
    final repository = _ref.read(plannerRepositoryProvider);

    for (var session in sessions) {
      final sessionDateStr = PlannerHelpers.formatDate(session.completedAt);
      
      // Look for a matching planned item for this day
      final matchingItem = plannerItems.firstWhere(
        (item) => item.date == sessionDateStr && item.workoutId == session.workoutId,
        orElse: () => plannerItems.firstWhere(
          (item) => item.date == sessionDateStr,
          orElse: () => PlannerItem(
            id: '',
            date: '',
            status: PlannerStatus.planned,
            createdAt: DateTime.now(),
          ),
        ),
      );

      if (matchingItem.id.isEmpty) {
        // No planned item exists on this day at all, dynamically create a completed workout entry
        final newItem = PlannerItem(
          id: PlannerHelpers.generateId(),
          date: sessionDateStr,
          workoutId: session.workoutId,
          workoutName: session.workoutName,
          status: PlannerStatus.completed,
          completed: true,
          startedAt: session.startedAt,
          completedAt: session.completedAt,
          createdAt: DateTime.now(),
        );
        await repository.savePlannerItem(newItem);
      } else if (!matchingItem.completed) {
        // Update existing item to completed
        final updatedItem = matchingItem.copyWith(
          status: PlannerStatus.completed,
          completed: true,
          workoutId: matchingItem.workoutId ?? session.workoutId,
          workoutName: matchingItem.workoutName ?? session.workoutName,
          startedAt: session.startedAt,
          completedAt: session.completedAt,
        );
        await repository.savePlannerItem(updatedItem);
      }
    }
  }
}

final plannerSyncServiceProvider = Provider<PlannerSyncService>((ref) {
  return PlannerSyncService(ref);
});
