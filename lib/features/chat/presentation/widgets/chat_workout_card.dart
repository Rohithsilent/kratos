import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:kratos/core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

class ChatWorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workoutData;
  final VoidCallback onSave;

  const ChatWorkoutCard({
    super.key,
    required this.workoutData,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = workoutData['name'] ?? 'Custom Workout';
    final String split = workoutData['split'] ?? 'Full Body';
    final List<dynamic> exercises = workoutData['exercises'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: context.colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark ? Colors.white : context.customColors.grey900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$split • ${exercises.length} Exercises',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white70 : context.customColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...exercises.map((e) {
              final exName = e['name'] ?? 'Exercise';
              final sets = e['sets'] ?? 3;
              final reps = e['reps'] ?? 10;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exName,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : context.customColors.grey800,
                        ),
                      ),
                    ),
                    Text(
                      '$sets x $reps',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white60 : context.customColors.grey500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save to My Workouts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
