// lib/features/nutrition/data/repositories/meal_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../datasources/meal_remote_datasource.dart';
import '../../domain/models/meal_entry_model.dart';

abstract class MealRepository {
  Future<List<MealEntry>> fetchMeals({String? date});
  Future<void> saveMeal(MealEntry meal);
  Future<void> deleteMeal(String mealId);
  Future<List<MealEntry>> fetchMealsForDateRange(
      String startDate, String endDate);
}

class MealRepositoryImpl implements MealRepository {
  final Ref _ref;

  MealRepositoryImpl(this._ref);

  String? get _currentUserId =>
      _ref.read(firebaseAuthProvider).currentUser?.uid;

  // In-memory fallback cache
  final Map<String, MealEntry> _localCache = {};

  @override
  Future<List<MealEntry>> fetchMeals({String? date}) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[MealRepo] No authenticated user, returning local cache');
      final cached = _localCache.values.toList();
      if (date != null) return cached.where((m) => m.date == date).toList();
      return cached;
    }
    try {
      final meals =
          await _ref.read(mealRemoteDataSourceProvider).getMeals(uid, date: date);
      debugPrint('[MealRepo] Fetched ${meals.length} meals from Firestore (date=$date)');
      for (var m in meals) {
        _localCache[m.id] = m;
      }
      return meals;
    } catch (e) {
      debugPrint('[MealRepo] Firestore fetch failed: $e — falling back to cache');
      final cached = _localCache.values.toList();
      if (date != null) return cached.where((m) => m.date == date).toList();
      return cached;
    }
  }

  @override
  Future<void> saveMeal(MealEntry meal) async {
    _localCache[meal.id] = meal;
    final uid = _currentUserId;
    if (uid != null) {
      try {
        await _ref.read(mealRemoteDataSourceProvider).saveMeal(uid, meal);
        debugPrint('[MealRepo] Meal saved to Firestore: ${meal.foodName}');
      } catch (e) {
        debugPrint('[MealRepo] Failed to save meal to Firestore: $e');
        // Meal is still in local cache, will sync later
      }
    }
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    _localCache.remove(mealId);
    final uid = _currentUserId;
    if (uid != null) {
      try {
        await _ref.read(mealRemoteDataSourceProvider).deleteMeal(uid, mealId);
        debugPrint('[MealRepo] Meal deleted from Firestore: $mealId');
      } catch (e) {
        debugPrint('[MealRepo] Failed to delete meal from Firestore: $e');
      }
    }
  }

  @override
  Future<List<MealEntry>> fetchMealsForDateRange(
      String startDate, String endDate) async {
    final uid = _currentUserId;
    if (uid == null) {
      return _localCache.values
          .where((m) =>
              m.date.compareTo(startDate) >= 0 &&
              m.date.compareTo(endDate) <= 0)
          .toList();
    }
    try {
      return await _ref
          .read(mealRemoteDataSourceProvider)
          .getMealsForDateRange(uid, startDate, endDate);
    } catch (e) {
      debugPrint('[MealRepo] Date range fetch failed: $e — falling back to cache');
      return _localCache.values
          .where((m) =>
              m.date.compareTo(startDate) >= 0 &&
              m.date.compareTo(endDate) <= 0)
          .toList();
    }
  }
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(ref);
});
