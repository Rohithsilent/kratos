# KRATOS Workout System Implementation Plan

**Goal:** Build a complete, production-grade, immersive, and cinematic Workout System for the KRATOS fitness application, seamlessly integrated with GoRouter, Riverpod, and Cloud Firestore.

**Architecture:** Clean architecture feature structure under `lib/features/workout/` with:
- **Domain:** Data models (`WorkoutSet`, `WorkoutExercise`, `Workout`, `WorkoutSession`).
- **Data:** Firebase Firestore integration with offline cache enabled for templates and completed sessions.
- **Presentation Controllers:** Notifiers for Builder state and Session live tracking state.
- **Presentation Screens:** UI screens (Builder, Detail, Active Session, Rest Timer Overlay, Completion).
- **Presentation Widgets:** Segmented rep range pickers, sets wheels, active trackers.

---

### Task 1: Core Models & JSON Serialization

**Files:**
- Create: `lib/features/workout/domain/models/workout_model.dart`

**Step 1: Write minimal implementation**
We define standard Dart representation of `WorkoutSet`, `WorkoutExercise`, `Workout`, and `WorkoutSession` with `fromJson` and `toJson` methods.

```dart
// lib/features/workout/domain/models/workout_model.dart

class WorkoutSet {
  final String id;
  final int setNumber;
  final int reps;
  final double weight;
  final bool isCompleted;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'isCompleted': isCompleted,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: json['id'] as String,
        setNumber: json['setNumber'] as int,
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final String category;
  final String image;
  final String gifUrl;
  final int restSeconds;
  final List<WorkoutSet> sets;
  final String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.image,
    required this.gifUrl,
    required this.restSeconds,
    required this.sets,
    this.notes,
  });

  WorkoutExercise copyWith({
    int? restSeconds,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId,
      name: name,
      category: category,
      image: image,
      gifUrl: gifUrl,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'category': category,
        'image': image,
        'gifUrl': gifUrl,
        'restSeconds': restSeconds,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
        exerciseId: json['exerciseId'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        image: json['image'] as String,
        gifUrl: json['gifUrl'] as String,
        restSeconds: json['restSeconds'] as int? ?? 90,
        sets: (json['sets'] as List<dynamic>?)
                ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: json['notes'] as String?,
      );
}

class Workout {
  final String id;
  final String userId;
  final String name;
  final String split;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.split,
    required this.createdAt,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'split': split,
        'createdAt': createdAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        split: json['split'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class WorkoutSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalDurationSeconds;
  final double totalVolumeKg;
  final int caloriesBurned;
  final List<WorkoutExercise> completedExercises;

  WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.totalDurationSeconds,
    required this.totalVolumeKg,
    required this.caloriesBurned,
    required this.completedExercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutId': workoutId,
        'workoutName': workoutName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
        'totalVolumeKg': totalVolumeKg,
        'caloriesBurned': caloriesBurned,
        'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        workoutId: json['workoutId'] as String,
        workoutName: json['workoutName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        totalDurationSeconds: json['totalDurationSeconds'] as int,
        totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
        caloriesBurned: json['caloriesBurned'] as int,
        completedExercises: (json['completedExercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
```

---

### Task 2: Firestore Storage Repository Layer

**Files:**
- Create: `lib/features/workout/data/repositories/workout_repository.dart`

**Step 1: Write minimal implementation**
Firestore offline persistence is enabled out of the box in standard Flutter. We write `WorkoutRepository` to load custom routines, create workouts, and save completed workout sessions.

```dart
// lib/features/workout/data/repositories/workout_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
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
```

---

### Task 3: Riverpod State Controllers (Builder & Active Session)

**Files:**
- Create: `lib/features/workout/presentation/controllers/workout_controller.dart`

**Step 1: Write minimal implementation**
We construct the notifier providers that manage state cleanly.

```dart
// lib/features/workout/presentation/controllers/workout_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/workout_model.dart';
import '../../data/repositories/workout_repository.dart';

// --- WORKOUT LIST CONTROLLER ---
class WorkoutListNotifier extends AsyncNotifier<List<Workout>> {
  @override
  FutureOr<List<Workout>> build() async {
    return ref.read(workoutRepositoryProvider).getWorkouts();
  }

  Future<void> addOrUpdateWorkout(Workout workout) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(workoutRepositoryProvider).saveWorkout(workout);
      return ref.read(workoutRepositoryProvider).getWorkouts();
    });
  }

  Future<void> removeWorkout(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(workoutRepositoryProvider).deleteWorkout(id);
      return ref.read(workoutRepositoryProvider).getWorkouts();
    });
  }
}

final workoutListProvider = AsyncNotifierProvider<WorkoutListNotifier, List<Workout>>(
  WorkoutListNotifier.new,
);


// --- WORKOUT BUILDER CONTROLLER ---
class WorkoutBuilderState {
  final String name;
  final String split;
  final List<WorkoutExercise> exercises;

  WorkoutBuilderState({
    this.name = 'New Workout',
    this.split = 'Push',
    this.exercises = const [],
  });

  WorkoutBuilderState copyWith({
    String? name,
    String? split,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutBuilderState(
      name: name ?? this.name,
      split: split ?? this.split,
      exercises: exercises ?? this.exercises,
    );
  }
}

class WorkoutBuilderNotifier extends Notifier<WorkoutBuilderState> {
  @override
  WorkoutBuilderState build() => WorkoutBuilderState();

  void initFromWorkout(Workout workout) {
    state = WorkoutBuilderState(
      name: workout.name,
      split: workout.split,
      exercises: workout.exercises,
    );
  }

  void reset() {
    state = WorkoutBuilderState();
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateSplit(String split) {
    state = state.copyWith(split: split);
  }

  void addExercise(WorkoutExercise exercise) {
    // Check if exercise already exists, otherwise append
    final index = state.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
    if (index >= 0) {
      // Update existing target configurations
      final updated = List<WorkoutExercise>.from(state.exercises);
      updated[index] = exercise;
      state = state.copyWith(exercises: updated);
    } else {
      state = state.copyWith(exercises: [...state.exercises, exercise]);
    }
  }

  void removeExercise(String exerciseId) {
    state = state.copyWith(
      exercises: state.exercises.where((e) => e.exerciseId != exerciseId).toList(),
    );
  }

  void reorderExercises(int oldIndex, int newIndex) {
    final list = List<WorkoutExercise>.from(state.exercises);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(exercises: list);
  }

  void updateExerciseSets(String exerciseId, List<WorkoutSet> sets) {
    final list = state.exercises.map((e) {
      if (e.exerciseId == exerciseId) {
        return e.copyWith(sets: sets);
      }
      return e;
    }).toList();
    state = state.copyWith(exercises: list);
  }
}

final workoutBuilderProvider = NotifierProvider<WorkoutBuilderNotifier, WorkoutBuilderState>(
  WorkoutBuilderNotifier.new,
);


// --- LIVE WORKOUT SESSION STATE ---
class WorkoutSessionState {
  final Workout workout;
  final List<WorkoutExercise> exercises;
  final DateTime startedAt;
  final int activeExerciseIndex;
  final int activeSetIndex;
  final bool isResting;
  final int restTimerSeconds; // Target timer duration
  final int restTimeRemaining; // Countdown
  final bool isRestPaused;
  final int elapsedSeconds;

  WorkoutSessionState({
    required this.workout,
    required this.exercises,
    required this.startedAt,
    this.activeExerciseIndex = 0,
    this.activeSetIndex = 0,
    this.isResting = false,
    this.restTimerSeconds = 90,
    this.restTimeRemaining = 0,
    this.isRestPaused = false,
    this.elapsedSeconds = 0,
  });

  WorkoutSessionState copyWith({
    List<WorkoutExercise>? exercises,
    int? activeExerciseIndex,
    int? activeSetIndex,
    bool? isResting,
    int? restTimerSeconds,
    int? restTimeRemaining,
    bool? isRestPaused,
    int? elapsedSeconds,
  }) {
    return WorkoutSessionState(
      workout: workout,
      exercises: exercises ?? this.exercises,
      startedAt: startedAt,
      activeExerciseIndex: activeExerciseIndex ?? this.activeExerciseIndex,
      activeSetIndex: activeSetIndex ?? this.activeSetIndex,
      isResting: isResting ?? this.isResting,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isRestPaused: isRestPaused ?? this.isRestPaused,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class WorkoutSessionNotifier extends FamilyNotifier<WorkoutSessionState?, Workout> {
  Timer? _globalTimer;
  Timer? _restTimer;

  @override
  WorkoutSessionState? build(Workout arg) {
    ref.onDispose(() {
      _globalTimer?.cancel();
      _restTimer?.cancel();
    });
    return null;
  }

  void startSession() {
    _globalTimer?.cancel();
    _restTimer?.cancel();

    // Map template exercises to full active mutable exercises
    final sessionExercises = arg.exercises.map((e) {
      return WorkoutExercise(
        exerciseId: e.exerciseId,
        name: e.name,
        category: e.category,
        image: e.image,
        gifUrl: e.gifUrl,
        restSeconds: e.restSeconds,
        notes: e.notes,
        sets: e.sets.map((s) => s.copyWith(isCompleted: false)).toList(),
      );
    }).toList();

    state = WorkoutSessionState(
      workout: arg,
      exercises: sessionExercises,
      startedAt: DateTime.now(),
      activeExerciseIndex: 0,
      activeSetIndex = 0,
    );

    // Global stopwatch timer (tick every second)
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null) {
        state = state!.copyWith(elapsedSeconds: state!.elapsedSeconds + 1);
      }
    });
  }

  void toggleSetComplete(int exerciseIndex, int setIndex) {
    if (state == null) return;
    
    final currentExercise = state!.exercises[exerciseIndex];
    final targetSet = currentExercise.sets[setIndex];
    final newCompleted = !targetSet.isCompleted;

    final updatedSets = List<WorkoutSet>.from(currentExercise.sets);
    updatedSets[setIndex] = targetSet.copyWith(isCompleted: newCompleted);

    final updatedExercises = List<WorkoutExercise>.from(state!.exercises);
    updatedExercises[exerciseIndex] = currentExercise.copyWith(sets: updatedSets);

    state = state!.copyWith(exercises: updatedExercises);

    // Trigger REST TIMER on complete (only if marked completed, not uncompleted)
    if (newCompleted) {
      startRest(currentExercise.restSeconds);
    }
  }

  void skipSet(int exerciseIndex, int setIndex) {
    // Jump forward to next set
    if (state == null) return;
    final maxSets = state!.exercises[exerciseIndex].sets.length;
    if (setIndex < maxSets - 1) {
      state = state!.copyWith(activeSetIndex: setIndex + 1);
    } else {
      nextExercise();
    }
  }

  // Timer controls
  void startRest(int duration) {
    _restTimer?.cancel();
    state = state!.copyWith(
      isResting: true,
      restTimerSeconds: duration,
      restTimeRemaining: duration,
      isRestPaused: false,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || !state!.isResting) {
        timer.cancel();
        return;
      }
      if (state!.isRestPaused) return;

      if (state!.restTimeRemaining > 1) {
        state = state!.copyWith(restTimeRemaining: state!.restTimeRemaining - 1);
      } else {
        timer.cancel();
        endRest();
      }
    });
  }

  void pauseRest() {
    if (state == null) return;
    state = state!.copyWith(isRestPaused: !state!.isRestPaused);
  }

  void extendRest(int seconds) {
    if (state == null) return;
    state = state!.copyWith(
      restTimeRemaining: state!.restTimeRemaining + seconds,
      restTimerSeconds: state!.restTimerSeconds + seconds,
    );
  }

  void endRest() {
    _restTimer?.cancel();
    if (state == null) return;

    // Advance set pointer
    final currentExerciseIndex = state!.activeExerciseIndex;
    final currentSetIndex = state!.activeSetIndex;
    final currentExercise = state!.exercises[currentExerciseIndex];

    state = state!.copyWith(isResting: false, restTimeRemaining: 0);

    if (currentSetIndex < currentExercise.sets.length - 1) {
      state = state!.copyWith(activeSetIndex: currentSetIndex + 1);
    } else {
      nextExercise();
    }
  }

  void nextExercise() {
    if (state == null) return;
    if (state!.activeExerciseIndex < state!.exercises.length - 1) {
      state = state!.copyWith(
        activeExerciseIndex: state!.activeExerciseIndex + 1,
        activeSetIndex: 0,
      );
    }
  }

  void previousExercise() {
    if (state == null) return;
    if (state!.activeExerciseIndex > 0) {
      state = state!.copyWith(
        activeExerciseIndex: state!.activeExerciseIndex - 1,
        activeSetIndex: 0,
      );
    }
  }

  Future<WorkoutSession> completeSession() async {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    
    if (state == null) throw Exception('No session is active');

    // Calculate aggregated metrics
    double totalVol = 0;
    int setsCompleted = 0;
    for (var ex in state!.exercises) {
      for (var s in ex.sets) {
        if (s.isCompleted) {
          totalVol += s.weight * s.reps;
          setsCompleted++;
        }
      }
    }

    // Dynamic calories estimation based on active sets completed + duration
    final durationMins = state!.elapsedSeconds / 60.0;
    final cal = (setsCompleted * 15 + durationMins * 8).round();

    final session = WorkoutSession(
      id: const Uuid().v4(),
      workoutId: state!.workout.id,
      workoutName: state!.workout.name,
      startedAt: state!.startedAt,
      completedAt: DateTime.now(),
      totalDurationSeconds: state!.elapsedSeconds,
      totalVolumeKg: totalVol,
      caloriesBurned: cal,
      completedExercises: state!.exercises,
    );

    // Save history item in Firestore Repository
    await ref.read(workoutRepositoryProvider).saveSession(session);
    
    // Invalidate main home/dashboard history loaders
    ref.invalidate(workoutHistoryProvider);
    
    return session;
  }
}

final activeSessionProvider = FamilyNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?, Workout>(
  WorkoutSessionNotifier.new,
);

final workoutHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepositoryProvider).getSessions();
});
```

---

### Task 4: Add-To-Workout Bottom Sheet

**Files:**
- Create: `lib/features/workout/presentation/widgets/add_to_workout_bottom_sheet.dart`
- Modify: `lib/features/exercise_library/presentation/screens/exercise_detail_screen.dart`

**Step 1: Minimal Bottom Sheet implementation**
Create a premium glassmorphic bottom sheet using existing selectors:
- Numerical sets stepper.
- Segmented rep range slider chips.
- Horizontal scroll targets for rest timing.
- Rotational kg/lbs circular weights selector and optional notes textbox.

**Step 2: Add Floating action button to Exercise Detail Screen**
Configure a custom floating button at the bottom of the Detail screen to launch this beautiful modal.

---

### Task 5: Workout Builder Screen & Drag-And-Drop List

**Files:**
- Create: `lib/features/workout/presentation/screens/workout_builder_screen.dart`
- Create: `lib/features/workout/presentation/widgets/workout_exercise_card.dart`

**Step 1: Minimal drag-and-drop builder view**
Implements `ReorderableListView.builder` inside the builder layout. Displays matte-black containers styled with neon glow borders (`AppDecorations.glassCard`) incorporating reorder handles, custom exercise icons, and input editing models.

---

### Task 6: Workout Detail Screen (Workout Summary)

**Files:**
- Create: `lib/features/workout/presentation/screens/workout_detail_screen.dart`

**Step 1: Summary information view**
Renders workout split details, estimated tracking times, set tallies, trained muscle stress structures, and starts/edits operations.

---

### Task 7: Live Session Tracking Screen & Trackers

**Files:**
- Create: `lib/features/workout/presentation/screens/workout_session_screen.dart`
- Create: `lib/features/workout/presentation/widgets/set_tracker_widget.dart`

**Step 1: Fully immersive live session dashboard**
Features automatic scroll offsets, sharpness exercise loaders, dynamic progress headers, set logs counters, and tactile set logs toggling.

---

### Task 8: Rest Timer Fullscreen Pulsing Overlay

**Files:**
- Create: `lib/features/workout/presentation/widgets/rest_timer_overlay.dart`

**Step 1: Overlay tracking countdown overlay**
Triggers a fullscreen backdrop whenever `state.isResting` is true inside `WorkoutSessionScreen`. Animated countdown rings, skip controllers, and active timer scaling.

---

### Task 9: Completion / Celebration Screen

**Files:**
- Create: `lib/features/workout/presentation/screens/workout_complete_screen.dart`

**Step 1: Beautiful victory screen**
Shows metrics dashboard, total volumes lifted, dynamic achievements, and return buttons.

---

### Task 10: Routing & Navigation Declarations

**Files:**
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`

**Step 1: Register routes in app_router**
Introduce paths under authorize filters:
- `/workout/builder` (optional queryParam `id`)
- `/workout/detail/:id`
- `/workout/session/:id`
- `/workout/complete`

**Step 2: Connect Home Screen CTA buttons**
Updates the dashboard home stat card dynamically from `workoutListProvider` and loads templates or starts sessions instantly.
