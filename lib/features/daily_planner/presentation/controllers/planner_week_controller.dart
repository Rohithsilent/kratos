// lib/features/daily_planner/presentation/controllers/planner_week_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlannerWeekState {
  final DateTime referenceDate; // Determines which week is shown
  final DateTime selectedDate;  // Current focused date for details

  PlannerWeekState({
    required this.referenceDate,
    required this.selectedDate,
  });

  PlannerWeekState copyWith({
    DateTime? referenceDate,
    DateTime? selectedDate,
  }) {
    return PlannerWeekState(
      referenceDate: referenceDate ?? this.referenceDate,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class PlannerWeekNotifier extends Notifier<PlannerWeekState> {
  @override
  PlannerWeekState build() {
    final now = DateTime.now();
    return PlannerWeekState(
      referenceDate: now,
      selectedDate: now,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void selectPreviousWeek() {
    final prevWeek = state.referenceDate.subtract(Duration(days: 7));
    state = state.copyWith(
      referenceDate: prevWeek,
      selectedDate: prevWeek, // Auto-focus first day of previous week
    );
  }

  void selectNextWeek() {
    final nextWeek = state.referenceDate.add(Duration(days: 7));
    state = state.copyWith(
      referenceDate: nextWeek,
      selectedDate: nextWeek, // Auto-focus first day of next week
    );
  }

  void resetToToday() {
    final now = DateTime.now();
    state = PlannerWeekState(
      referenceDate: now,
      selectedDate: now,
    );
  }
}

final plannerWeekProvider = NotifierProvider<PlannerWeekNotifier, PlannerWeekState>(
  PlannerWeekNotifier.new,
);
