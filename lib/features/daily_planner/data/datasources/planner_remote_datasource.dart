// lib/features/daily_planner/data/datasources/planner_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/models/planner_item_model.dart';

abstract class PlannerRemoteDataSource {
  Stream<List<PlannerItem>> streamPlannerItems(String uid);
  Future<List<PlannerItem>> getPlannerItems(String uid);
  Future<void> savePlannerItem(String uid, PlannerItem item);
  Future<void> deletePlannerItem(String uid, String itemId);
  Future<void> saveWeeklyPlan(String uid, List<PlannerItem> items);
}

class PlannerRemoteDataSourceImpl implements PlannerRemoteDataSource {
  final FirebaseFirestore _firestore;

  PlannerRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('planner');
  }

  @override
  Stream<List<PlannerItem>> streamPlannerItems(String uid) {
    return _collection(uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PlannerItem.fromJson(doc.data())).toList();
    });
  }

  @override
  Future<List<PlannerItem>> getPlannerItems(String uid) async {
    final snapshot = await _collection(uid).get();
    return snapshot.docs.map((doc) => PlannerItem.fromJson(doc.data())).toList();
  }

  @override
  Future<void> savePlannerItem(String uid, PlannerItem item) async {
    await _collection(uid).doc(item.id).set(item.toJson());
  }

  @override
  Future<void> deletePlannerItem(String uid, String itemId) async {
    await _collection(uid).doc(itemId).delete();
  }

  @override
  Future<void> saveWeeklyPlan(String uid, List<PlannerItem> items) async {
    final batch = _firestore.batch();
    for (var item in items) {
      final docRef = _collection(uid).doc(item.id);
      batch.set(docRef, item.toJson());
    }
    await batch.commit();
  }
}

final plannerRemoteDataSourceProvider = Provider<PlannerRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PlannerRemoteDataSourceImpl(firestore);
});
