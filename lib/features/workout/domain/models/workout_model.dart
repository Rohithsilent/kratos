// lib/features/workout/domain/models/workout_model.dart

class WorkoutSet {
  final String id;
  final int setNumber;
  final int reps;
  final double weight;
  final bool isCompleted;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'isCompleted': isCompleted,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as String,
        setNumber: json['setNumber'] as int,
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final String category;
  final String image;
  final String gifUrl;
  final int restSeconds;
  final List<WorkoutSet> sets;
  final String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.image,
    required this.gifUrl,
    required this.restSeconds,
    required this.sets,
    this.notes,
  });

  WorkoutExercise copyWith({
    int? restSeconds,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId,
      name: name,
      category: category,
      image: image,
      gifUrl: gifUrl,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'category': category,
        'image': image,
        'gifUrl': gifUrl,
        'restSeconds': restSeconds,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
        exerciseId: json['exerciseId'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        image: json['image'] as String,
        gifUrl: json['gifUrl'] as String,
        restSeconds: json['restSeconds'] as int? ?? 90,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'] as String?,
      );
}

class Workout {
  final String id;
  final String userId;
  final String name;
  final String split;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises;
  final String? playlistUri;
  final String? playlistName;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.split,
    required this.createdAt,
    required this.exercises,
    this.playlistUri,
    this.playlistName,
  });

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? split,
    DateTime? createdAt,
    List<WorkoutExercise>? exercises,
    String? playlistUri,
    String? playlistName,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      split: split ?? this.split,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
      playlistUri: playlistUri ?? this.playlistUri,
      playlistName: playlistName ?? this.playlistName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'split': split,
        'createdAt': createdAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'playlistUri': playlistUri,
        'playlistName': playlistName,
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        split: json['split'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        playlistUri: json['playlistUri'] as String?,
        playlistName: json['playlistName'] as String?,
      );
}

class WorkoutSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalDurationSeconds;
  final double totalVolumeKg;
  final int caloriesBurned;
  final List<WorkoutExercise> completedExercises;

  WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.totalDurationSeconds,
    required this.totalVolumeKg,
    required this.caloriesBurned,
    required this.completedExercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutId': workoutId,
        'workoutName': workoutName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
        'totalVolumeKg': totalVolumeKg,
        'caloriesBurned': caloriesBurned,
        'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        workoutId: json['workoutId'] as String,
        workoutName: json['workoutName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        totalDurationSeconds: json['totalDurationSeconds'] as int,
        totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
        caloriesBurned: json['caloriesBurned'] as int,
        completedExercises: (json['completedExercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
