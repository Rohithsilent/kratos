// lib/features/workout/presentation/controllers/workout_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workout_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../../music/presentation/controllers/music_controller.dart';
import '../../../daily_planner/presentation/controllers/planner_controller.dart';
import '../../../daily_planner/utils/planner_helpers.dart';
import '../../../../core/notifications/notification_service.dart';

// Lightweight unique ID generator to avoid external dependencies
String generateUniqueId() {
  return '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 1000)}';
}

// --- WORKOUT LIST CONTROLLER ---
class WorkoutListNotifier extends AsyncNotifier<List<Workout>> {
  @override
  FutureOr<List<Workout>> build() async {
    return ref.read(workoutRepositoryProvider).getWorkouts();
  }

  Future<void> addOrUpdateWorkout(Workout workout) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(workoutRepositoryProvider).saveWorkout(workout);
      return ref.read(workoutRepositoryProvider).getWorkouts();
    });
  }

  Future<void> removeWorkout(String id) async {
    state = AsyncValue.loading();
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
  final String? playlistUri;
  final String? playlistName;

  WorkoutBuilderState({
    this.name = 'New Workout',
    this.split = 'Push',
    this.exercises = const [],
    this.playlistUri,
    this.playlistName,
  });

  WorkoutBuilderState copyWith({
    String? name,
    String? split,
    List<WorkoutExercise>? exercises,
    String? playlistUri,
    String? playlistName,
  }) {
    return WorkoutBuilderState(
      name: name ?? this.name,
      split: split ?? this.split,
      exercises: exercises ?? this.exercises,
      playlistUri: playlistUri ?? this.playlistUri,
      playlistName: playlistName ?? this.playlistName,
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
      playlistUri: workout.playlistUri,
      playlistName: workout.playlistName,
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

  void updatePlaylist(String uri, String name) {
    state = state.copyWith(playlistUri: uri, playlistName: name);
  }

  void clearPlaylist() {
    // using copyWith to set null isn't directly supported by this copyWith if we just omit,
    // so we override it by creating a new state directly to clear the playlist fields.
    state = WorkoutBuilderState(
      name: state.name,
      split: state.split,
      exercises: state.exercises,
      playlistUri: null,
      playlistName: null,
    );
  }

  void addExercise(WorkoutExercise exercise) {
    final index = state.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
    if (index >= 0) {
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

  void updateExerciseRest(String exerciseId, int restSeconds) {
    final list = state.exercises.map((e) {
      if (e.exerciseId == exerciseId) {
        return e.copyWith(restSeconds: restSeconds);
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
  final int restTimerSeconds;
  final int restTimeRemaining;
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

class WorkoutSessionNotifier extends Notifier<WorkoutSessionState?> {
  final Workout workout;
  Timer? _globalTimer;
  Timer? _restTimer;
  DateTime? _restEndsAt;

  WorkoutSessionNotifier(this.workout);

  @override
  WorkoutSessionState? build() {
    ref.onDispose(() {
      _globalTimer?.cancel();
      _restTimer?.cancel();
    });
    return null;
  }

  void startSession() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;

    final sessionExercises = workout.exercises.map((e) {
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
      workout: workout,
      exercises: sessionExercises,
      startedAt: DateTime.now(),
      activeExerciseIndex: 0,
      activeSetIndex: 0,
    );

    if (sessionExercises.isNotEmpty) {
      final firstExercise = sessionExercises.first;
      unawaited(NotificationService.instance.startWorkout(
        workout: workout,
        startedAt: state!.startedAt,
        exerciseName: firstExercise.name,
        setNumber: 1,
        totalSets: firstExercise.sets.length,
      ));
    }

    // AUTO-START PLAYLIST IF LINKED
    if (workout.playlistUri != null && workout.playlistUri!.isNotEmpty) {
      ref.read(musicControllerProvider.notifier).playPlaylist(workout.playlistUri!);
    }

    // REFLECT IN PLANNER IMMEDIATELY

    final todayStr = PlannerHelpers.formatDate(DateTime.now());
    ref.read(plannerListProvider.notifier).startWorkoutInPlanner(
      date: todayStr,
      workoutId: workout.id,
      workoutName: workout.name,
    );

    _globalTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state != null) {
        state = state!.copyWith(
          elapsedSeconds:
              DateTime.now().difference(state!.startedAt).inSeconds,
        );
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

    if (newCompleted) {
      startRest(focusedExerciseRestSeconds(exerciseIndex));
    }
  }

  int focusedExerciseRestSeconds(int exerciseIndex) {
    if (state == null || exerciseIndex >= state!.exercises.length) return 90;
    return state!.exercises[exerciseIndex].restSeconds;
  }

  void skipSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final maxSets = state!.exercises[exerciseIndex].sets.length;
    if (setIndex < maxSets - 1) {
      state = state!.copyWith(activeSetIndex: setIndex + 1);
    } else {
      nextExercise();
    }
  }

  void startRest(int duration) {
    _restTimer?.cancel();
    _restEndsAt = DateTime.now().add(Duration(seconds: duration));
    state = state!.copyWith(
      isResting: true,
      restTimerSeconds: duration,
      restTimeRemaining: duration,
      isRestPaused: false,
    );

    unawaited(NotificationService.instance.showRest(
      workout: workout,
      nextExerciseName: _nextWorkLabel(
        state!.activeExerciseIndex,
        state!.activeSetIndex,
      ),
      remainingSeconds: duration,
      isPaused: false,
    ));

    _restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state == null || !state!.isResting) {
        timer.cancel();
        return;
      }
      if (state!.isRestPaused) return;

      final milliseconds =
          _restEndsAt?.difference(DateTime.now()).inMilliseconds ?? 0;
      final remaining = (milliseconds + 999) ~/ 1000;
      if (remaining > 0) {
        state = state!.copyWith(restTimeRemaining: remaining);
      } else {
        timer.cancel();
        endRest();
      }
    });
  }

  void pauseRest() {
    if (state == null) return;
    if (state!.isRestPaused) {
      _restEndsAt =
          DateTime.now().add(Duration(seconds: state!.restTimeRemaining));
      state = state!.copyWith(isRestPaused: false);
    } else {
      final milliseconds =
          _restEndsAt?.difference(DateTime.now()).inMilliseconds ?? 0;
      final remaining = ((milliseconds + 999) ~/ 1000).clamp(
        0,
        state!.restTimerSeconds,
      ).toInt();
      _restEndsAt = null;
      state = state!.copyWith(
        isRestPaused: true,
        restTimeRemaining: remaining,
      );
    }
    unawaited(_pushRestNotification());
  }

  void extendRest(int seconds) {
    if (state == null) return;
    state = state!.copyWith(
      restTimeRemaining: state!.restTimeRemaining + seconds,
      restTimerSeconds: state!.restTimerSeconds + seconds,
    );
    if (!state!.isRestPaused && _restEndsAt != null) {
      _restEndsAt = _restEndsAt!.add(Duration(seconds: seconds));
    }
    unawaited(_pushRestNotification());
  }

  void endRest() {
    _restTimer?.cancel();
    _restEndsAt = null;
    if (state == null) return;

    final currentExerciseIndex = state!.activeExerciseIndex;
    final currentSetIndex = state!.activeSetIndex;
    final currentExercise = state!.exercises[currentExerciseIndex];

    state = state!.copyWith(isResting: false, restTimeRemaining: 0);

    if (currentSetIndex < currentExercise.sets.length - 1) {
      state = state!.copyWith(activeSetIndex: currentSetIndex + 1);
    } else {
      nextExercise();
      return;
    }
    unawaited(_pushActiveNotification());
  }

  void nextExercise() {
    if (state == null) return;
    if (state!.activeExerciseIndex < state!.exercises.length - 1) {
      state = state!.copyWith(
        activeExerciseIndex: state!.activeExerciseIndex + 1,
        activeSetIndex: 0,
      );
      unawaited(_pushActiveNotification());
    }
  }

  void previousExercise() {
    if (state == null) return;
    if (state!.activeExerciseIndex > 0) {
      state = state!.copyWith(
        activeExerciseIndex: state!.activeExerciseIndex - 1,
        activeSetIndex: 0,
      );
      unawaited(_pushActiveNotification());
    }
  }

  Future<WorkoutSession> completeSession() async {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;
    
    if (state == null) throw Exception('No session is active');

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

    final totalDurationSeconds =
        DateTime.now().difference(state!.startedAt).inSeconds;
    final durationMins = totalDurationSeconds / 60.0;
    final cal = (setsCompleted * 15 + durationMins * 8).round();

    final session = WorkoutSession(
      id: generateUniqueId(),
      workoutId: state!.workout.id,
      workoutName: state!.workout.name,
      startedAt: state!.startedAt,
      completedAt: DateTime.now(),
      totalDurationSeconds: totalDurationSeconds,
      totalVolumeKg: totalVol,
      caloriesBurned: cal,
      completedExercises: state!.exercises,
    );

    await ref.read(workoutRepositoryProvider).saveSession(session);
    ref.invalidate(workoutHistoryProvider);
    await NotificationService.instance.stopWorkout();

    final sessions = await ref.read(workoutRepositoryProvider).getSessions();
    unawaited(NotificationService.instance.syncStreakWarning(sessions));
    
    return session;
  }

  void abandonSession() {
    _globalTimer?.cancel();
    _restTimer?.cancel();
    _restEndsAt = null;
    state = null;
    unawaited(NotificationService.instance.stopWorkout());
  }

  Future<void> _pushActiveNotification() async {
    final current = state;
    if (current == null || current.exercises.isEmpty) return;
    final exercise = current.exercises[current.activeExerciseIndex];
    await NotificationService.instance.showActiveWorkout(
      workout: workout,
      startedAt: current.startedAt,
      exerciseName: exercise.name,
      setNumber: current.activeSetIndex + 1,
      totalSets: exercise.sets.length,
    );
  }

  Future<void> _pushRestNotification() async {
    final current = state;
    if (current == null || !current.isResting) return;
    await NotificationService.instance.showRest(
      workout: workout,
      nextExerciseName: _nextWorkLabel(
        current.activeExerciseIndex,
        current.activeSetIndex,
      ),
      remainingSeconds: current.restTimeRemaining,
      isPaused: current.isRestPaused,
    );
  }

  String _nextWorkLabel(int exerciseIndex, int setIndex) {
    final current = state;
    if (current == null || current.exercises.isEmpty) return workout.name;
    final exercise = current.exercises[exerciseIndex];
    if (setIndex < exercise.sets.length - 1) {
      return '${exercise.name} • Set ${setIndex + 2}';
    }
    if (exerciseIndex < current.exercises.length - 1) {
      return current.exercises[exerciseIndex + 1].name;
    }
    return 'Finish strong';
  }

  void updateExerciseSets(String exerciseId, List<WorkoutSet> sets) {
    if (state == null) return;
    final list = state!.exercises.map((e) {
      if (e.exerciseId == exerciseId) {
        return e.copyWith(sets: sets);
      }
      return e;
    }).toList();
    state = state!.copyWith(exercises: list);
  }
}

final activeSessionProvider = NotifierProvider.family<WorkoutSessionNotifier, WorkoutSessionState?, Workout>(
  (workout) => WorkoutSessionNotifier(workout),
);

final workoutHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepositoryProvider).getSessions();
});
