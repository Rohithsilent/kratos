// lib/features/daily_planner/domain/models/planner_template_model.dart

class PlannerTemplate {
  final String id;
  final String name;
  final String description;
  final Map<int, String?> weeklyDistribution; // 1 (Mon) to 7 (Sun) -> workoutId (or null for recovery)
  final DateTime createdAt;

  PlannerTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.weeklyDistribution,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'weeklyDistribution': weeklyDistribution.map((key, value) => MapEntry(key.toString(), value)),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlannerTemplate.fromJson(Map<String, dynamic> json) {
    final distJson = json['weeklyDistribution'] as Map<String, dynamic>;
    final weeklyDist = distJson.map((key, value) => MapEntry(int.parse(key), value as String?));
    
    return PlannerTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      weeklyDistribution: weeklyDist,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
