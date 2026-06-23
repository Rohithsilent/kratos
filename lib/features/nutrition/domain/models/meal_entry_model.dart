// lib/features/nutrition/domain/models/meal_entry_model.dart

import '../enums/meal_type.dart';

class MealEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final MealType mealType;
  final DateTime loggedAt;
  final String source; // "ai_scan" | "manual"
  final double? servingSize; // grams

  MealEntry({
    required this.id,
    required this.date,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.mealType,
    required this.loggedAt,
    this.source = 'manual',
    this.servingSize,
  });

  MealEntry copyWith({
    String? id,
    String? date,
    String? foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    MealType? mealType,
    DateTime? loggedAt,
    String? source,
    double? servingSize,
  }) {
    return MealEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
      source: source ?? this.source,
      servingSize: servingSize ?? this.servingSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'mealType': mealType.name,
        'loggedAt': loggedAt.toIso8601String(),
        'source': source,
        'servingSize': servingSize,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        foodName: json['foodName'] as String,
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fats: (json['fats'] as num).toDouble(),
        mealType: MealType.values.firstWhere(
          (e) => e.name == json['mealType'],
          orElse: () => MealType.snack,
        ),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        source: json['source'] as String? ?? 'manual',
        servingSize: (json['servingSize'] as num?)?.toDouble(),
      );
}
