// lib/features/workout/data/repositories/workout_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/models/workout_model.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return WorkoutRepository(firestore: firestore, auth: auth);
});

class WorkoutRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorkoutRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _workoutsCollection {
    final uid = _currentUserId;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('workouts');
  }

  CollectionReference<Map<String, dynamic>> get _sessionsCollection {
    final uid = _currentUserId;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(uid).collection('sessions');
  }

  Future<List<Workout>> getWorkouts() async {
    try {
      final snapshot = await _workoutsCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => Workout.fromJson(doc.data())).toList();
    } catch (e) {
      // Return empty list if user collection does not exist yet (offline fallback)
      return [];
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    await _workoutsCollection.doc(workout.id).set(workout.toJson());
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutsCollection.doc(workoutId).delete();
  }

  Future<List<WorkoutSession>> getSessions() async {
    try {
      final snapshot = await _sessionsCollection.orderBy('completedAt', descending: true).get();
      return snapshot.docs.map((doc) => WorkoutSession.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _sessionsCollection.doc(session.id).set(session.toJson());
  }
}
