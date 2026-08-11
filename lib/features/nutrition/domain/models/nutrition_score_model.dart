// lib/features/nutrition/domain/models/nutrition_score_model.dart

/// Computed daily nutrition score (0–100) based on macro and hydration adherence.
class NutritionScore {
  final double calorieAdherence; // 0.0 – 1.0
  final double proteinAdherence;
  final double hydrationAdherence;
  final int score; // 0 – 100
  final String? customGrade;
  final String? customMessage;

  NutritionScore({
    required this.calorieAdherence,
    required this.proteinAdherence,
    required this.hydrationAdherence,
    required this.score,
    this.customGrade,
    this.customMessage,
  });

  /// Compute score from current intake vs targets.
  /// Weights: Calories 40%, Protein 35%, Hydration 25%.
  factory NutritionScore.compute({
    required double caloriesConsumed,
    required double caloriesTarget,
    required double proteinConsumed,
    required double proteinTarget,
    required int waterConsumed,
    required int waterTarget,
  }) {
    double calAdh = caloriesTarget > 0
        ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.2)
        : 0.0;
    // Penalise overconsumption (going over 100% reduces score)
    if (calAdh > 1.0) calAdh = 1.0 - (calAdh - 1.0) * 2;
    calAdh = calAdh.clamp(0.0, 1.0);

    final proAdh = proteinTarget > 0
        ? (proteinConsumed / proteinTarget).clamp(0.0, 1.0)
        : 0.0;
    final hydAdh = waterTarget > 0
        ? (waterConsumed / waterTarget).clamp(0.0, 1.0)
        : 0.0;

    final raw = calAdh * 0.40 + proAdh * 0.35 + hydAdh * 0.25;
    final score = (raw * 100).round().clamp(0, 100);

    return NutritionScore(
      calorieAdherence: calAdh,
      proteinAdherence: proAdh,
      hydrationAdherence: hydAdh,
      score: score,
    );
  }

  String get grade {
    if (customGrade != null) return customGrade!;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  String get message {
    if (customMessage != null) return customMessage!;
    if (score >= 90) return 'Outstanding nutrition today.';
    if (score >= 80) return 'Solid day. Keep pushing.';
    if (score >= 70) return 'Good progress. Room to improve.';
    if (score >= 60) return 'Moderate. Focus on protein.';
    if (score >= 50) return 'Below target. Log more meals.';
    return 'Off track. Time to eat right.';
  }
}
