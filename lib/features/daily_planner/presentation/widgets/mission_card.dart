// lib/features/daily_planner/presentation/widgets/mission_card.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../workout/domain/models/workout_model.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';
import '../../domain/models/planner_item_model.dart';

class MissionCard extends ConsumerWidget {
  final PlannerItem plannerItem;
  final Workout workout;

  const MissionCard({
    super.key,
    required this.plannerItem,
    required this.workout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int totalExercises = workout.exercises.length;
    int totalSets = 0;
    for (var ex in workout.exercises) {
      totalSets += ex.sets.length;
    }
    final int estDurationMins = (totalSets * 3.5).round();
    final int estCalories = (totalSets * 12 + estDurationMins * 7).round();

    // Dynamically retrieve first exercise image as banner preview
    final String exerciseImage = workout.exercises.isNotEmpty
        ? workout.exercises.first.image
        : 'chest_press.png'; // Fallback asset if empty

    final bool isCompleted = plannerItem.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "TODAY'S MISSION",
            style: AppTypography.labelBold.copyWith(
              color: context.colors.onSurface,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 24,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Core Info Row (Image + Stats)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Preview Image
                    Container(
                      width: 110,
                      height: 125,
                      decoration: BoxDecoration(
                        color: context.colors.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/exercises/$exerciseImage',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Color(0xFF171717),
                            child: Center(
                              child: Icon(Icons.fitness_center_rounded, color: context.colors.onSurface.withValues(alpha: 0.38), size: 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Workout Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${workout.split.toUpperCase()} DAY',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (isCompleted)
                                Icon(Icons.verified_rounded, color: context.customColors.success, size: 16)
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            workout.name,
                            style: TextStyle(color: context.colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            workout.exercises.map((e) => e.name).take(3).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 14),

                          // Mini Info Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniBadge(context, '$totalExercises', 'Exercises', Icons.library_books_rounded),
                              _buildMiniBadge(context, '$totalSets', 'Sets', Icons.layers_rounded),
                              _buildMiniBadge(context, '~$estDurationMins', 'Mins', Icons.timer_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Divider(color: context.colors.onSurface.withValues(alpha: 0.10), height: 1),
                SizedBox(height: 14),

                // 2. Progress Slider Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCompleted ? '100% COMPLETED' : '0% COMPLETED',
                      style: TextStyle(
                        color: isCompleted ? context.customColors.success : context.colors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: context.colors.primary, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '$estCalories kcal est.',
                          style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isCompleted ? 1.0 : 0.0,
                    color: isCompleted ? context.customColors.success : context.colors.primary,
                    backgroundColor: context.colors.onSurface.withValues(alpha: 0.04),
                    minHeight: 4,
                  ),
                ),
                SizedBox(height: 18),

                // 3. CTA Action Button (Start Workout)
                GestureDetector(
                  onTap: () {
                    if (isCompleted) {
                      // Already done, navigate to history or completed view
                      context.push('/dashboard'); // Go home or view summary
                    } else {
                      // Begin active session orchestration
                      ref.read(activeSessionProvider(workout).notifier).startSession();
                      context.push('/workout/session/${workout.id}');
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? LinearGradient(
                              colors: [Color(0xFF142416), Color(0xFF0F1A10)],
                            )
                          : context.customColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCompleted 
                            ? context.customColors.success.withOpacity(0.3) 
                            : context.colors.onSurface.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                      boxShadow: isCompleted
                          ? null
                          : [
                              BoxShadow(
                                color: context.colors.primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                            color: isCompleted ? context.customColors.success : context.colors.onSurface,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isCompleted ? 'MISSION ACCOMPLISHED' : 'START WORKOUT ROUTINE',
                            style: TextStyle(
                              color: isCompleted ? context.customColors.success : context.colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(BuildContext context, String value, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.colors.onSurface.withValues(alpha: 0.30), size: 10),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(color: context.colors.onSurface, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.3), fontSize: 7, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }
}
