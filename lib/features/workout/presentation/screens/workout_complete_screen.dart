// lib/features/workout/presentation/screens/workout_complete_screen.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/workout_model.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutCompleteScreen({
    super.key,
    required this.session,
  });

  String _formatDuration(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '$mins Min $secs Sec';
  }

  @override
  Widget build(BuildContext context) {
    // Count completed sets and exercises for achievements
    int totalCompletedSets = 0;
    for (var ex in session.completedExercises) {
      totalCompletedSets += ex.sets.where((s) => s.isCompleted).length;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Visual backdrop glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: context.customColors.success.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),

                  // Neon success Checkmark ring
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: context.customColors.success.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.customColors.success.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: context.customColors.success.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: context.customColors.success,
                        size: 48,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Header title
                  Text(
                    session.workoutName.toUpperCase(),
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'SESSION COMPLETE',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'TEMPLE CONQUERED. STATS RECORDED.',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Aggregated grid stats
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          borderRadius: 20,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.timer_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.30), size: 18),
                              SizedBox(height: 6),
                              Text(
                                _formatDuration(session.totalDurationSeconds),
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text('ELAPSED TIME', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          borderRadius: 20,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.30), size: 18),
                              SizedBox(height: 6),
                              Text(
                                '${session.totalVolumeKg.toStringAsFixed(1)} KG',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text('TOTAL VOLUME', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          borderRadius: 20,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.local_fire_department_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.30), size: 18),
                              SizedBox(height: 6),
                              Text(
                                '${session.caloriesBurned} CAL',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text('EST. CALORIES', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          borderRadius: 20,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined, color: context.colors.primary, size: 18),
                              SizedBox(height: 6),
                              Text(
                                '$totalCompletedSets Sets Logged',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text('ACHIEVEMENT SUMMARY', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),

                  // Achievement text box
                  GlassCard(
                    borderRadius: 16,
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.offline_bolt_rounded, color: context.colors.primary, size: 24),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UNSTOPPABLE FORCE',
                                style: TextStyle(color: context.colors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'You conquered ${session.completedExercises.length} tactile splits today. Keep grinding!',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.70), fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // CTA Home route triggers
                  GestureDetector(
                    onTap: () {
                      // Navigate directly to main dashboard home!
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      height: 52,
                      decoration: AppDecorations.primaryButton(context, borderRadius: 16),
                      child: Center(
                        child: Text(
                          'RETURN TO DASHBOARD',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
