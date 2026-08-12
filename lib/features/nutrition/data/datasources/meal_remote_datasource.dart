// lib/features/nutrition/data/datasources/meal_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/models/meal_entry_model.dart';

abstract class MealRemoteDataSource {
  Future<List<MealEntry>> getMeals(String uid, {String? date});
  Future<void> saveMeal(String uid, MealEntry meal);
  Future<void> deleteMeal(String uid, String mealId);
  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String startDate, String endDate);
}

class MealRemoteDataSourceImpl implements MealRemoteDataSource {
  final FirebaseFirestore _firestore;

  MealRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('meals');
  }

  @override
  Future<List<MealEntry>> getMeals(String uid, {String? date}) async {
    try {
      Query<Map<String, dynamic>> query = _collection(uid);
      if (date != null) {
        query = query.where('date', isEqualTo: date);
      }
      // Avoid composite index requirement: only orderBy when NOT filtering by date
      if (date == null) {
        query = query.orderBy('loggedAt', descending: true);
      }
      final snapshot = await query.get();
      debugPrint('[MealDataSource] getMeals uid=$uid date=$date → ${snapshot.docs.length} docs');
      return snapshot.docs
          .map((doc) => MealEntry.fromJson(doc.data()))
          .toList();
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR getMeals: $e\n$st');
      // Rethrow so the repository layer can handle it properly
      rethrow;
    }
  }

  @override
  Future<void> saveMeal(String uid, MealEntry meal) async {
    try {
      await _collection(uid).doc(meal.id).set(meal.toJson());
      debugPrint('[MealDataSource] saveMeal OK: ${meal.foodName} → ${meal.id}');
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR saveMeal: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> deleteMeal(String uid, String mealId) async {
    try {
      await _collection(uid).doc(mealId).delete();
      debugPrint('[MealDataSource] deleteMeal OK: $mealId');
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR deleteMeal: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String startDate, String endDate) async {
    try {
      final snapshot = await _collection(uid)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
      debugPrint('[MealDataSource] getMealsForDateRange $startDate→$endDate: ${snapshot.docs.length} docs');
      return snapshot.docs
          .map((doc) => MealEntry.fromJson(doc.data()))
          .toList();
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR getMealsForDateRange: $e\n$st');
      rethrow;
    }
  }
}

final mealRemoteDataSourceProvider = Provider<MealRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MealRemoteDataSourceImpl(firestore);
});
