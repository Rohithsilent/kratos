// lib/features/workout/presentation/widgets/rest_timer_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../controllers/workout_controller.dart';
import '../../domain/models/workout_model.dart';

class RestTimerOverlay extends ConsumerWidget {
  final Workout workout;

  const RestTimerOverlay({
    super.key,
    required this.workout,
  });

  String _formatTime(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(activeSessionProvider(workout));
    if (sessionState == null || !sessionState.isResting) {
      return SizedBox.shrink();
    }

    final int remaining = sessionState.restTimeRemaining;
    final int total = sessionState.restTimerSeconds;
    final double progress = total > 0 ? remaining / total : 0;
    final bool isPaused = sessionState.isRestPaused;

    // Get details for upcoming target exercise if available
    final int nextExIdx = sessionState.activeExerciseIndex;
    final nextExercise = sessionState.exercises[nextExIdx];
    final int nextSetNum = sessionState.activeSetIndex + 1;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color: context.colors.surface.withValues(alpha: 0.96),
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rest Title Header
              Text(
                'REST PERIOD',
                style: TextStyle(
                  color: context.colors.primary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'BREATHE & RECOVER',
                style: TextStyle(color: context.colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 50),

              // Circular Countdown Visual
              Stack(
                alignment: Alignment.center,
                children: [
                  // High-tech outer glow rings
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.04),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                  ),

                  // Background track
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4,
                      color: context.colors.onSurface.withValues(alpha: 0.03),
                    ),
                  ),

                  // Active animated colored ring
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: isPaused ? Colors.amber : context.colors.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),

                  // Central Countdown values
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(remaining),
                        style: TextStyle(color: context.colors.onSurface,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        isPaused ? 'PAUSED' : 'REMAINING',
                        style: TextStyle(
                          color: isPaused ? Colors.amber : context.colors.onSurface.withValues(alpha: 0.30),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 50),

              // Upcoming Target Context
              GlassCard(
                borderRadius: 16,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.colors.onSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/exercises/${nextExercise.image}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPCOMING TARGET',
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            nextExercise.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set $nextSetNum of ${nextExercise.sets.length}',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.54),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 60),

              // Timer Controls Row (Add 15s, Pause/Resume, Skip)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Add 15 Seconds
                  GestureDetector(
                    onTap: () {
                      ref.read(activeSessionProvider(workout).notifier).extendRest(15);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.glassmorphism.borderColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.glassmorphism.borderColor),
                          ),
                          child: Icon(Icons.add_rounded, color: context.colors.onSurface.withValues(alpha: 0.70), size: 20),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '+15 SEC',
                          style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.54), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Play / Pause Toggle
                  GestureDetector(
                    onTap: () {
                      ref.read(activeSessionProvider(workout).notifier).pauseRest();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isPaused ? Colors.amber.withOpacity(0.12) : context.colors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPaused ? Colors.amber.withOpacity(0.4) : context.colors.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: isPaused ? Colors.amber : context.colors.primary,
                            size: 28,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          isPaused ? 'RESUME' : 'PAUSE',
                          style: TextStyle(
                            color: isPaused ? Colors.amber : context.colors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skip Rest
                  GestureDetector(
                    onTap: () {
                      ref.read(activeSessionProvider(workout).notifier).endRest();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.glassmorphism.borderColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.glassmorphism.borderColor),
                          ),
                          child: Icon(Icons.skip_next_rounded, color: context.colors.onSurface.withValues(alpha: 0.70), size: 20),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'SKIP',
                          style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.54), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
