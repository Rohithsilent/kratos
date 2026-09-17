// lib/features/daily_planner/data/repositories/planner_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../datasources/planner_remote_datasource.dart';
import '../../domain/models/planner_item_model.dart';

abstract class PlannerRepository {
  Stream<List<PlannerItem>> watchPlannerItems();
  Future<List<PlannerItem>> fetchPlannerItems();
  Future<void> savePlannerItem(PlannerItem item);
  Future<void> deletePlannerItem(String itemId);
  Future<void> saveWeeklyPlan(List<PlannerItem> items);
  void clearCache({String? uid});
}

class PlannerRepositoryImpl implements PlannerRepository {
  final Ref _ref;

  PlannerRepositoryImpl(this._ref);

  String? get _currentUserId => _ref.read(firebaseAuthProvider).currentUser?.uid;

  // In-memory fallback database isolated per user ID
  final Map<String, Map<String, PlannerItem>> _userCache = {};

  Map<String, PlannerItem> _getUserCache(String uid) {
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
  Stream<List<PlannerItem>> watchPlannerItems() {
    final uid = _currentUserId;
    if (uid == null) {
      return Stream.value([]);
    }
    return _ref.read(plannerRemoteDataSourceProvider).streamPlannerItems(uid);
  }

  @override
  Future<List<PlannerItem>> fetchPlannerItems() async {
    final uid = _currentUserId;
    if (uid == null) {
      return [];
    }
    final cache = _getUserCache(uid);
    try {
      final items = await _ref.read(plannerRemoteDataSourceProvider).getPlannerItems(uid);
      // Keep fallback up to date for this user
      for (var item in items) {
        cache[item.id] = item;
      }
      return items;
    } catch (e) {
      // Gracefully fall back to local offline cache for this user
      return cache.values.toList();
    }
  }

  @override
  Future<void> savePlannerItem(PlannerItem item) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final cache = _getUserCache(uid);
    cache[item.id] = item;
    await _ref.read(plannerRemoteDataSourceProvider).savePlannerItem(uid, item);
  }

  @override
  Future<void> deletePlannerItem(String itemId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final cache = _getUserCache(uid);
    cache.remove(itemId);
    await _ref.read(plannerRemoteDataSourceProvider).deletePlannerItem(uid, itemId);
  }

  @override
  Future<void> saveWeeklyPlan(List<PlannerItem> items) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final cache = _getUserCache(uid);
    for (var item in items) {
      cache[item.id] = item;
    }
    await _ref.read(plannerRemoteDataSourceProvider).saveWeeklyPlan(uid, items);
  }
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  ref.watch(authStateProvider);
  return PlannerRepositoryImpl(ref);
});
