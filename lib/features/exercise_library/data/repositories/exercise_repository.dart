// lib/features/exercise_library/data/repositories/exercise_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exercise_model.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

class ExerciseRepository {
  List<Exercise>? _cachedExercises;

  Future<List<Exercise>> getExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/exercises/exercises.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _cachedExercises = jsonList.map((json) => Exercise.fromJson(json)).toList();
      return _cachedExercises!;
    } catch (e) {
      throw Exception('Failed to load exercises dataset: $e');
    }
  }

  Future<Exercise> getExerciseById(String id) async {
    final exercises = await getExercises();
    return exercises.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Exercise with id $id not found'),
    );
  }
}
