// lib/features/daily_planner/domain/models/planner_day_model.dart

import 'planner_item_model.dart';

class PlannerDay {
  final DateTime date;
  final PlannerItem? item;
  final bool isToday;
  final bool isSelected;

  PlannerDay({
    required this.date,
    this.item,
    required this.isToday,
    this.isSelected = false,
  });

  PlannerDay copyWith({
    DateTime? date,
    PlannerItem? item,
    bool? isToday,
    bool? isSelected,
  }) {
    return PlannerDay(
      date: date ?? this.date,
      item: item ?? this.item,
      isToday: isToday ?? this.isToday,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
