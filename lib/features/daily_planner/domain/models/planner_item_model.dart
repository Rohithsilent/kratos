// lib/features/daily_planner/domain/models/planner_item_model.dart

import '../enums/planner_status.dart';

class PlannerItem {
  final String id;
  final String date; // YYYY-MM-DD format
  final String? workoutId;
  final String? workoutName; // Cached for quick offline view
  final PlannerStatus status;
  final bool completed;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // ─── Nutrition Tracking ───
  final double caloriesTarget;
  final double caloriesConsumed;
  final double proteinTarget;
  final double proteinConsumed;
  final double carbsTarget;
  final double carbsConsumed;
  final double fatsTarget;
  final double fatsConsumed;

  // ─── Hydration Tracking ───
  final int waterTarget;    // in ml
  final int waterConsumed;  // in ml

  PlannerItem({
    required this.id,
    required this.date,
    this.workoutId,
    this.workoutName,
    required this.status,
    this.completed = false,
    this.notes,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.caloriesTarget = 2200,
    this.caloriesConsumed = 0,
    this.proteinTarget = 150,
    this.proteinConsumed = 0,
    this.carbsTarget = 250,
    this.carbsConsumed = 0,
    this.fatsTarget = 70,
    this.fatsConsumed = 0,
    this.waterTarget = 3000,
    this.waterConsumed = 0,
  });

  PlannerItem copyWith({
    String? id,
    String? date,
    String? workoutId,
    bool clearWorkout = false,
    String? workoutName,
    PlannerStatus? status,
    bool? completed,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    double? caloriesTarget,
    double? caloriesConsumed,
    double? proteinTarget,
    double? proteinConsumed,
    double? carbsTarget,
    double? carbsConsumed,
    double? fatsTarget,
    double? fatsConsumed,
    int? waterTarget,
    int? waterConsumed,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      date: date ?? this.date,
      workoutId: clearWorkout ? null : (workoutId ?? this.workoutId),
      workoutName: clearWorkout ? null : (workoutName ?? this.workoutName),
      status: status ?? this.status,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      caloriesTarget: caloriesTarget ?? this.caloriesTarget,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      fatsTarget: fatsTarget ?? this.fatsTarget,
      fatsConsumed: fatsConsumed ?? this.fatsConsumed,
      waterTarget: waterTarget ?? this.waterTarget,
      waterConsumed: waterConsumed ?? this.waterConsumed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'workoutId': workoutId,
        'workoutName': workoutName,
        'status': status.name,
        'completed': completed,
        'notes': notes,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'caloriesTarget': caloriesTarget,
        'caloriesConsumed': caloriesConsumed,
        'proteinTarget': proteinTarget,
        'proteinConsumed': proteinConsumed,
        'carbsTarget': carbsTarget,
        'carbsConsumed': carbsConsumed,
        'fatsTarget': fatsTarget,
        'fatsConsumed': fatsConsumed,
        'waterTarget': waterTarget,
        'waterConsumed': waterConsumed,
      };

  factory PlannerItem.fromJson(Map<String, dynamic> json) => PlannerItem(
        id: json['id'] as String,
        date: json['date'] as String,
        workoutId: json['workoutId'] as String?,
        workoutName: json['workoutName'] as String?,
        status: PlannerStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PlannerStatus.planned,
        ),
        completed: json['completed'] as bool? ?? false,
        notes: json['notes'] as String?,
        startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        caloriesTarget: (json['caloriesTarget'] as num?)?.toDouble() ?? 2200,
        caloriesConsumed: (json['caloriesConsumed'] as num?)?.toDouble() ?? 0,
        proteinTarget: (json['proteinTarget'] as num?)?.toDouble() ?? 150,
        proteinConsumed: (json['proteinConsumed'] as num?)?.toDouble() ?? 0,
        carbsTarget: (json['carbsTarget'] as num?)?.toDouble() ?? 250,
        carbsConsumed: (json['carbsConsumed'] as num?)?.toDouble() ?? 0,
        fatsTarget: (json['fatsTarget'] as num?)?.toDouble() ?? 70,
        fatsConsumed: (json['fatsConsumed'] as num?)?.toDouble() ?? 0,
        waterTarget: (json['waterTarget'] as num?)?.toInt() ?? 3000,
        waterConsumed: (json['waterConsumed'] as num?)?.toInt() ?? 0,
      );
}
