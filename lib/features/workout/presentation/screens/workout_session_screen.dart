// lib/features/workout/presentation/screens/workout_session_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../controllers/workout_controller.dart';
import '../../domain/models/workout_model.dart';
import '../widgets/rest_timer_overlay.dart';
import '../widgets/set_tracker_widget.dart';
import '../../../music/music_feature.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutSessionScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _ScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late Workout _workoutTemplate;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final workoutsAsync = ref.watch(workoutListProvider);
      workoutsAsync.whenData((workouts) {
        _workoutTemplate = workouts.firstWhere((w) => w.id == widget.workoutId);
        
        // Auto-start workout playlist
        if (_workoutTemplate.playlistUri != null && _workoutTemplate.playlistUri!.isNotEmpty) {
          Future.microtask(() {
            ref.read(musicControllerProvider.notifier).playPlaylist(_workoutTemplate.playlistUri!);
          });
        }

        setState(() {
          _initialized = true;
        });
      });
    }
  }

  String _formatStopwatch(int seconds) {
    final int hours = seconds ~/ 3600;
    final int mins = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleCancelSession() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: Color(0xFF0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text(
            'ABANDON WORKOUT?',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
          ),
          content: Text(
            'Are you sure you want to quit this active training session? Your current progress stats will not be recorded.',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.60), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('CANCEL', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('ABANDON', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      context.pop(); // Route back to detail summary screen
    }
  }

  Future<void> _handleCompleteSession() async {
    final notifier = ref.read(activeSessionProvider(_workoutTemplate).notifier);
    
    // Aggregate completed sets to verify user did some work
    final sessionState = ref.read(activeSessionProvider(_workoutTemplate));
    int completedCount = 0;
    if (sessionState != null) {
      for (var ex in sessionState.exercises) {
        for (var s in ex.sets) {
          if (s.isCompleted) completedCount++;
        }
      }
    }

    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please log at least 1 completed set to record your workout!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    try {
      final sessionRecord = await notifier.completeSession();
      if (mounted) {
        // Route to success celebration, passing completed session record as extra param
        context.pushReplacement('/workout/complete', extra: sessionRecord);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to save session: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final sessionState = ref.watch(activeSessionProvider(_workoutTemplate));

    // Handle initial state boot safeguard
    if (sessionState == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Initializing workout controller...', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38))),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(activeSessionProvider(_workoutTemplate).notifier).startSession();
                },
                child: Text('Start Now'),
              )
            ],
          ),
        ),
      );
    }

    final int activeExIdx = sessionState.activeExerciseIndex;
    final WorkoutExercise focusedExercise = sessionState.exercises[activeExIdx];

    // Compute progress details
    final double exerciseProgress = (activeExIdx + 1) / sessionState.exercises.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: _ScrollBehavior(),
        child: Stack(
          children: [
            // 1. DYNAMIC HIGH-BLUR IMAGE BACKDROP
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/exercises/${focusedExercise.image}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        AppColors.darkBg.withOpacity(0.95),
                        AppColors.darkBg,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 2. SESSION STOPWATCH HEADER
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _handleCancelSession,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.glassDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorderDark),
                            ),
                            child: Icon(Icons.close_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.70), size: 18),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              sessionState.workout.name.toUpperCase(),
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                            SizedBox(height: 3),
                            Text(
                              _formatStopwatch(sessionState.elapsedSeconds),
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _handleCompleteSession,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Text(
                              'FINISH',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TOP PROGRESS INDICATOR
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EXERCISE ${activeExIdx + 1} OF ${sessionState.exercises.length}',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(exerciseProgress * 100).round()}% COMPLETE',
                              style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: exerciseProgress,
                              color: AppColors.primary,
                              backgroundColor: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),

                  // 3. CENTRAL FOCUS WORKOUT CARD
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Large animated GIF container
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: -2,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/exercises/${focusedExercise.gifUrl}',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/exercises/${focusedExercise.image}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.black38,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Exercise focused header detail
                          Text(
                            focusedExercise.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  focusedExercise.category.toUpperCase(),
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.70), fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'REST: ${focusedExercise.restSeconds}S',
                                  style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // 4. SET TABLE LIST
                          GlassCard(
                            borderRadius: 20,
                            padding: EdgeInsets.all(14),
                            child: SetTrackerWidget(
                              sets: focusedExercise.sets,
                              onToggleComplete: (setIdx) {
                                ref
                                    .read(activeSessionProvider(_workoutTemplate).notifier)
                                    .toggleSetComplete(activeExIdx, setIdx);
                              },
                              onWeightChanged: (setIdx, newWeight) {
                                final currentSets = List<WorkoutSet>.from(focusedExercise.sets);
                                currentSets[setIdx] = currentSets[setIdx].copyWith(weight: newWeight);
                                ref
                                    .read(activeSessionProvider(_workoutTemplate).notifier)
                                    .updateExerciseSets(focusedExercise.exerciseId, currentSets);
                              },
                              onRepsChanged: (setIdx, newReps) {
                                final currentSets = List<WorkoutSet>.from(focusedExercise.sets);
                                currentSets[setIdx] = currentSets[setIdx].copyWith(reps: newReps);
                                ref
                                    .read(activeSessionProvider(_workoutTemplate).notifier)
                                    .updateExerciseSets(focusedExercise.exerciseId, currentSets);
                              },
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // Music Player
                  MiniMusicPlayer(),

                  // 5. STEPPER CONTROL NAVIGATION FOOTER
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF090909),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        // Left Back Exercise button
                        GestureDetector(
                          onTap: activeExIdx > 0
                              ? () => ref.read(activeSessionProvider(_workoutTemplate).notifier).previousExercise()
                              : null,
                          child: Opacity(
                            opacity: activeExIdx > 0 ? 1.0 : 0.25,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900, size: 18),
                            ),
                          ),
                        ),
                        SizedBox(width: 14),

                        // Main Stepper action
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final maxEx = sessionState.exercises.length;
                              if (activeExIdx < maxEx - 1) {
                                ref.read(activeSessionProvider(_workoutTemplate).notifier).nextExercise();
                              } else {
                                _handleCompleteSession();
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: AppDecorations.primaryButton(context, borderRadius: 14),
                              child: Center(
                                child: Text(
                                  activeExIdx < sessionState.exercises.length - 1
                                      ? 'NEXT EXERCISE'
                                      : 'FINISH WORKOUT',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14),

                        // Right Forward Exercise button
                        GestureDetector(
                          onTap: activeExIdx < sessionState.exercises.length - 1
                              ? () => ref.read(activeSessionProvider(_workoutTemplate).notifier).nextExercise()
                              : null,
                          child: Opacity(
                            opacity: activeExIdx < sessionState.exercises.length - 1 ? 1.0 : 0.25,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Icon(Icons.arrow_forward_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6. FULLSCREEN AUTOMATED REST TIMER OVERLAY
            RestTimerOverlay(workout: _workoutTemplate),
          ],
        ),
      ),
    );
  }
}
