// lib/features/exercise_library/presentation/providers/exercise_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';

// Fetch all exercises from repository
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).getExercises();
});

// Search query state managed via Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Selected UI category state (default is 'All') managed via Notifier
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

// Favorite exercises tracker (Set of exercise IDs) managed via Notifier
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggleFavorite(String exerciseId) {
    if (state.contains(exerciseId)) {
      state = Set.from(state)..remove(exerciseId);
    } else {
      state = Set.from(state)..add(exerciseId);
    }
  }

  bool isFavorite(String exerciseId) {
    return state.contains(exerciseId);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

// Reactive filtered exercises list
final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final exercisesAsync = ref.watch(allExercisesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return exercisesAsync.whenData((exercises) {
    return exercises.where((exercise) {
      // 1. Search Query Filter
      final matchesQuery = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.target.toLowerCase().contains(query) ||
          exercise.muscleGroup.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);

      // 2. Category Filter
      bool matchesCategory = true;
      if (category != 'All') {
        final catLower = category.toLowerCase();
        if (catLower == 'chest') {
          matchesCategory = exercise.category == 'chest';
        } else if (catLower == 'back') {
          matchesCategory = exercise.category == 'back';
        } else if (catLower == 'legs') {
          matchesCategory = exercise.category == 'upper legs' || exercise.category == 'lower legs';
        } else if (catLower == 'shoulders') {
          matchesCategory = exercise.category == 'shoulders';
        } else if (catLower == 'arms') {
          matchesCategory = exercise.category == 'upper arms' || exercise.category == 'lower arms';
        } else if (catLower == 'core') {
          matchesCategory = exercise.category == 'waist';
        } else {
          matchesCategory = exercise.category.toLowerCase() == catLower;
        }
      }

      return matchesQuery && matchesCategory;
    }).toList();
  });
});
