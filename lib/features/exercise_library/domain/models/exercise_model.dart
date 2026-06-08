// lib/features/exercise_library/domain/models/exercise_model.dart

class Exercise {
  final String id;
  final String name;
  final String category;
  final String bodyPart;
  final String equipment;
  final Map<String, String> instructions;
  final Map<String, List<String>> instructionSteps;
  final String muscleGroup;
  final List<String> secondaryMuscles;
  final String target;
  final String image;
  final String gifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.equipment,
    required this.instructions,
    required this.instructionSteps,
    required this.muscleGroup,
    required this.secondaryMuscles,
    required this.target,
    required this.image,
    required this.gifUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      bodyPart: json['body_part'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      instructions: (json['instructions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ?? {},
      instructionSteps: (json['instruction_steps'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>).map((e) => e.toString()).toList(),
            ),
          ) ?? {},
      muscleGroup: json['muscle_group'] as String? ?? '',
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      target: json['target'] as String? ?? '',
      image: json['image'] as String? ?? '',
      gifUrl: json['gif_url'] as String? ?? '',
    );
  }

  // Helper getters to resolve asset paths correctly
  String get localImagePath => 'assets/exercises/$image';
  String get localGifPath => 'assets/exercises/$gifUrl';
  
  // Translation Fallbacks
  String get englishInstruction => instructions['en'] ?? '';
  List<String> get englishInstructionSteps => instructionSteps['en'] ?? [];

  // Deterministic difficulty mapping to align with screenshots
  String get difficulty {
    final idVal = int.tryParse(id) ?? 0;
    if (equipment.toLowerCase() == 'body weight') {
      if (idVal % 3 == 0) return 'Beginner';
      if (idVal % 3 == 1) return 'Intermediate';
      return 'Advanced';
    } else if (equipment.toLowerCase().contains('barbell') || equipment.toLowerCase().contains('dumbbell')) {
      if (idVal % 2 == 0) return 'Intermediate';
      return 'Advanced';
    } else {
      if (idVal % 3 == 0) return 'Beginner';
      if (idVal % 3 == 1) return 'Intermediate';
      return 'Advanced';
    }
  }
}
