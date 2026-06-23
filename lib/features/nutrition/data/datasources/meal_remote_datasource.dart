// lib/features/nutrition/data/datasources/meal_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    Query<Map<String, dynamic>> query = _collection(uid);
    if (date != null) {
      query = query.where('date', isEqualTo: date);
    }
    query = query.orderBy('loggedAt', descending: true);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MealEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> saveMeal(String uid, MealEntry meal) async {
    await _collection(uid).doc(meal.id).set(meal.toJson());
  }

  @override
  Future<void> deleteMeal(String uid, String mealId) async {
    await _collection(uid).doc(mealId).delete();
  }

  @override
  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String startDate, String endDate) async {
    final snapshot = await _collection(uid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => MealEntry.fromJson(doc.data()))
        .toList();
  }
}

final mealRemoteDataSourceProvider = Provider<MealRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MealRemoteDataSourceImpl(firestore);
});
