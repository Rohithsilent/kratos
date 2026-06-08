// lib/features/daily_planner/utils/planner_helpers.dart

import 'package:flutter/material.dart';
import '../domain/enums/planner_status.dart';

class PlannerHelpers {
  PlannerHelpers._();

  static String generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 1000)}';
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Gets the full dates (Monday to Sunday) for the week containing the [referenceDate].
  static List<DateTime> getWeekDates(DateTime referenceDate) {
    // Find the Monday of the current week (DateTime.monday is 1)
    final int currentWeekday = referenceDate.weekday;
    final DateTime monday = referenceDate.subtract(Duration(days: currentWeekday - 1));
    
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// Returns a clean title like "May 19 – May 25" for a week containing the [referenceDate].
  static String getWeekString(DateTime referenceDate) {
    final dates = getWeekDates(referenceDate);
    final first = dates.first;
    final last = dates.last;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final startMonth = months[first.month - 1];
    final endMonth = months[last.month - 1];

    if (first.month == last.month) {
      return '$startMonth ${first.day} – ${last.day}';
    }
    return '$startMonth ${first.day} – $endMonth ${last.day}';
  }

  static String getDayNameShort(DateTime date) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }

  /// Returns the corresponding vector icon or IconData matching muscle/movement split tags
  static IconData getSplitIcon(String? splitName) {
    if (splitName == null) return Icons.airline_seat_recline_extra_rounded;
    final name = splitName.toLowerCase();
    if (name.contains('push')) {
      return Icons.fitness_center_rounded; // Represents weights/chest
    } else if (name.contains('pull')) {
      return Icons.bolt_rounded; // Represents lightning/back energy
    } else if (name.contains('legs')) {
      return Icons.directions_walk_rounded; // Represents walking/leg motions
    } else if (name.contains('recovery')) {
      return Icons.spa_rounded; // Represents yoga/lotus
    } else if (name.contains('cardio')) {
      return Icons.directions_run_rounded; // Running
    } else if (name.contains('upper')) {
      return Icons.accessibility_new_rounded; // Full upper body
    } else if (name.contains('rest')) {
      return Icons.nights_stay_rounded; // Night moon
    }
    return Icons.star_border_rounded;
  }

  static String getMotivationalQuote(PlannerStatus status) {
    switch (status) {
      case PlannerStatus.planned:
        return 'PREPARE FOR WAR.';
      case PlannerStatus.active:
        return 'ENGAGED. CRUSH THIS SESSION.';
      case PlannerStatus.completed:
        return 'MISSION ACCOMPLISHED. OUTSTANDING WORK.';
      case PlannerStatus.skipped:
        return 'ADJUST. ADAPT. RECOVER LATER.';
      case PlannerStatus.recovery:
        return 'RECOVERY IS WHERE GROWTH HAPPENS.';
    }
  }
}
