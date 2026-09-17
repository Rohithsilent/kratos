// lib/features/nutrition/data/repositories/meal_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../datasources/meal_remote_datasource.dart';
import '../../domain/models/meal_entry_model.dart';

abstract class MealRepository {
  Future<List<MealEntry>> fetchMeals({String? date});
  Future<void> saveMeal(MealEntry meal);
  Future<void> deleteMeal(String mealId);
  Future<List<MealEntry>> fetchMealsForDateRange(
      String startDate, String endDate);
  void clearCache({String? uid});
}

class MealRepositoryImpl implements MealRepository {
  final Ref _ref;

  MealRepositoryImpl(this._ref);

  String? get _currentUserId =>
      _ref.read(firebaseAuthProvider).currentUser?.uid;

  // In-memory fallback cache isolated per user ID
  final Map<String, Map<String, MealEntry>> _userCache = {};

  Map<String, MealEntry> _getUserCache(String uid) {
    return _userCache.putIfAbsent(uid, () => {});
  }

  @override
  void clearCache({String? uid}) {
    if (uid != null) {
      _userCache.remove(uid);
    } else {
      _userCache.clear();
    }
  }

  @override
  Future<List<MealEntry>> fetchMeals({String? date}) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('[MealRepo] No authenticated user, returning empty list');
      return [];
    }
    final cache = _getUserCache(uid);
    try {
      final meals =
          await _ref.read(mealRemoteDataSourceProvider).getMeals(uid, date: date);
      debugPrint('[MealRepo] Fetched ${meals.length} meals from PostgreSQL (date=$date, uid=$uid)');
      for (var m in meals) {
        cache[m.id] = m;
      }
      return meals;
    } catch (e) {
      debugPrint('[MealRepo] PostgreSQL fetch failed: $e — falling back to user cache');
      final cached = cache.values.toList();
      if (date != null) return cached.where((m) => m.date == date).toList();
      return cached;
    }
  }

  @override
  Future<void> saveMeal(MealEntry meal) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final cache = _getUserCache(uid);
    cache[meal.id] = meal;
    try {
      await _ref.read(mealRemoteDataSourceProvider).saveMeal(uid, meal);
      debugPrint('[MealRepo] Meal saved to PostgreSQL: ${meal.foodName} for uid=$uid');
    } catch (e) {
      debugPrint('[MealRepo] Failed to save meal to PostgreSQL: $e');
      // Meal is still in user local cache, will sync later
    }
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final cache = _getUserCache(uid);
    cache.remove(mealId);
    try {
      await _ref.read(mealRemoteDataSourceProvider).deleteMeal(uid, mealId);
      debugPrint('[MealRepo] Meal deleted from PostgreSQL: $mealId');
    } catch (e) {
      debugPrint('[MealRepo] Failed to delete meal from PostgreSQL: $e');
    }
  }

  @override
  Future<List<MealEntry>> fetchMealsForDateRange(
      String startDate, String endDate) async {
    final uid = _currentUserId;
    if (uid == null) {
      return [];
    }
    final cache = _getUserCache(uid);
    try {
      final meals = await _ref
          .read(mealRemoteDataSourceProvider)
          .getMealsForDateRange(uid, startDate, endDate);
      for (var m in meals) {
        cache[m.id] = m;
      }
      return meals;
    } catch (e) {
      debugPrint('[MealRepo] Date range fetch failed: $e — falling back to user cache');
      return cache.values
          .where((m) =>
              m.date.compareTo(startDate) >= 0 &&
              m.date.compareTo(endDate) <= 0)
          .toList();
    }
  }
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  ref.watch(authStateProvider);
  return MealRepositoryImpl(ref);
});
