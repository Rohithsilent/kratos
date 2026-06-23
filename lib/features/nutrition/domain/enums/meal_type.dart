// lib/features/nutrition/domain/enums/meal_type.dart

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  /// Auto-detect meal type based on current time of day.
  static MealType fromTimeOfDay([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 11) return MealType.breakfast;
    if (hour >= 11 && hour < 15) return MealType.lunch;
    if (hour >= 15 && hour < 18) return MealType.snack;
    return MealType.dinner; // 18-4
  }
}
