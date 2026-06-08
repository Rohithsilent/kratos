// lib/features/daily_planner/presentation/controllers/planner_completion_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planner_controller.dart';
import 'planner_week_controller.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';

class PlannerStats {
  final int currentStreak;
  final double weeklyCompletionPercentage;
  final double totalDurationHoursThisWeek;
  final int totalWorkoutsThisWeek;
  final int totalScheduledThisWeek;
  final double monthlyCompletionPercentage;

  PlannerStats({
    required this.currentStreak,
    required this.weeklyCompletionPercentage,
    required this.totalDurationHoursThisWeek,
    required this.totalWorkoutsThisWeek,
    required this.totalScheduledThisWeek,
    required this.monthlyCompletionPercentage,
  });
}

final plannerStatsProvider = Provider<PlannerStats>((ref) {
  final plannerItemsAsync = ref.watch(plannerListProvider);
  final workoutSessionsAsync = ref.watch(workoutHistoryProvider);
  final weekState = ref.watch(plannerWeekProvider);

  final plannerItems = plannerItemsAsync.value ?? [];
  final sessions = workoutSessionsAsync.value ?? [];

  // ═══ 1. STREAK — fully real, no fallbacks ═══
  int streakCount = 0;
  final todayStr = PlannerHelpers.formatDate(DateTime.now());

  // Build set of all completed dates from planner + sessions
  final completedDates = <String>{};
  for (var item in plannerItems) {
    if (item.completed || item.status == PlannerStatus.active) {
      completedDates.add(item.date);
    }
  }
  for (var s in sessions) {
    completedDates.add(PlannerHelpers.formatDate(s.completedAt));
  }

  // Walk backwards from today (or yesterday if today isn't done yet)
  final yesterdayStr = PlannerHelpers.formatDate(
    DateTime.now().subtract(Duration(days: 1)),
  );
  bool streakActive =
      completedDates.contains(todayStr) || completedDates.contains(yesterdayStr);

  if (streakActive) {
    DateTime checkDate = completedDates.contains(todayStr)
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: 1));

    while (completedDates.contains(PlannerHelpers.formatDate(checkDate))) {
      streakCount++;
      checkDate = checkDate.subtract(Duration(days: 1));
    }
  }

  // ═══ 2. WEEKLY STATS ═══
  final weekDates = PlannerHelpers.getWeekDates(weekState.referenceDate);
  final weekDateStrings =
      weekDates.map((d) => PlannerHelpers.formatDate(d)).toSet();

  final weekItems =
      plannerItems.where((item) => weekDateStrings.contains(item.date)).toList();

  int totalWorkoutsScheduled = 0;
  int completedWorkouts = 0;

  for (var item in weekItems) {
    if (item.status != PlannerStatus.recovery) {
      totalWorkoutsScheduled++;
      if (item.completed || item.status == PlannerStatus.active) {
        completedWorkouts++;
      }
    }
  }

  double weeklyCompletion = 0.0;
  if (totalWorkoutsScheduled > 0) {
    weeklyCompletion = completedWorkouts / totalWorkoutsScheduled;
  }

  // ═══ 3. DURATION — sessions this week ═══
  double totalDurationSeconds = 0;
  for (var s in sessions) {
    final sDateStr = PlannerHelpers.formatDate(s.completedAt);
    if (weekDateStrings.contains(sDateStr)) {
      totalDurationSeconds += s.totalDurationSeconds;
    }
  }
  final double totalDurationHours = totalDurationSeconds / 3600.0;

  // ═══ 4. MONTHLY COMPLETION ═══
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthItems = plannerItems.where((item) {
    final itemDate = PlannerHelpers.parseDate(item.date);
    return itemDate.year == now.year &&
        itemDate.month == now.month &&
        itemDate.isBefore(now.add(Duration(days: 1)));
  }).toList();

  int monthScheduled = 0;
  int monthCompleted = 0;
  for (var item in monthItems) {
    if (item.status != PlannerStatus.recovery) {
      monthScheduled++;
      if (item.completed || item.status == PlannerStatus.active) monthCompleted++;
    }
  }
  double monthlyCompletion =
      monthScheduled > 0 ? monthCompleted / monthScheduled : 0.0;

  return PlannerStats(
    currentStreak: streakCount,
    weeklyCompletionPercentage: weeklyCompletion,
    totalDurationHoursThisWeek: totalDurationHours,
    totalWorkoutsThisWeek: completedWorkouts,
    totalScheduledThisWeek: totalWorkoutsScheduled,
    monthlyCompletionPercentage: monthlyCompletion,
  );
});
