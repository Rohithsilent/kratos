// lib/features/daily_planner/data/repositories/planner_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../datasources/planner_remote_datasource.dart';
import '../../domain/models/planner_item_model.dart';

abstract class PlannerRepository {
  Stream<List<PlannerItem>> watchPlannerItems();
  Future<List<PlannerItem>> fetchPlannerItems();
  Future<void> savePlannerItem(PlannerItem item);
  Future<void> deletePlannerItem(String itemId);
  Future<void> saveWeeklyPlan(List<PlannerItem> items);
}

class PlannerRepositoryImpl implements PlannerRepository {
  final Ref _ref;

  PlannerRepositoryImpl(this._ref);

  String? get _currentUserId => _ref.read(firebaseAuthProvider).currentUser?.uid;

  // In-memory fallback database for premium guest sessions
  final Map<String, PlannerItem> _localFallbackCache = {};

  @override
  Stream<List<PlannerItem>> watchPlannerItems() {
    final uid = _currentUserId;
    if (uid == null) {
      // Stream local fallback
      return Stream.value(_localFallbackCache.values.toList());
    }
    return _ref.read(plannerRemoteDataSourceProvider).streamPlannerItems(uid);
  }

  @override
  Future<List<PlannerItem>> fetchPlannerItems() async {
    final uid = _currentUserId;
    if (uid == null) {
      return _localFallbackCache.values.toList();
    }
    try {
      final items = await _ref.read(plannerRemoteDataSourceProvider).getPlannerItems(uid);
      // Keep fallback up to date
      for (var item in items) {
        _localFallbackCache[item.id] = item;
      }
      return items;
    } catch (e) {
      // Gracefully fall back to local offline cache
      return _localFallbackCache.values.toList();
    }
  }

  @override
  Future<void> savePlannerItem(PlannerItem item) async {
    _localFallbackCache[item.id] = item;
    final uid = _currentUserId;
    if (uid != null) {
      await _ref.read(plannerRemoteDataSourceProvider).savePlannerItem(uid, item);
    }
  }

  @override
  Future<void> deletePlannerItem(String itemId) async {
    _localFallbackCache.remove(itemId);
    final uid = _currentUserId;
    if (uid != null) {
      await _ref.read(plannerRemoteDataSourceProvider).deletePlannerItem(uid, itemId);
    }
  }

  @override
  Future<void> saveWeeklyPlan(List<PlannerItem> items) async {
    for (var item in items) {
      _localFallbackCache[item.id] = item;
    }
    final uid = _currentUserId;
    if (uid != null) {
      await _ref.read(plannerRemoteDataSourceProvider).saveWeeklyPlan(uid, items);
    }
  }
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepositoryImpl(ref);
});
