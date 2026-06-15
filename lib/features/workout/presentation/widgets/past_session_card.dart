import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_model.dart';

class PastSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final bool showRoutineName;

  const PastSessionCard({
    super.key,
    required this.session,
    this.showRoutineName = false,
  });

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat timeFormat = DateFormat('hh:mm a');
    final String startTime = timeFormat.format(session.startedAt);
    final String endTime = timeFormat.format(session.completedAt);
    final String dateStr = DateFormat('EEEE, MMM d, yyyy').format(session.completedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.glassmorphism.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.glassmorphism.borderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Soft subtle gradient wash
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Date and Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr.toUpperCase(),
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.glassmorphism.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: context.colors.primary, size: 10),
                            SizedBox(width: 4),
                            Text(
                              _formatDuration(session.totalDurationSeconds),
                              style: TextStyle(
                                color: context.colors.onSurface,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Routine Name (if required)
                  if (showRoutineName) ...[
                    Text(
                      session.workoutName.toUpperCase(),
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],

                  // Time Range
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: context.colors.onSurface.withValues(alpha: 0.6), size: 14),
                      SizedBox(width: 6),
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  Divider(color: context.glassmorphism.borderColor, height: 1),
                  SizedBox(height: 16),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(context, 'VOLUME', '${session.totalVolumeKg.toInt()} kg'),
                      _buildStatColumn(context, 'EXERCISES', '${session.completedExercises.length}'),
                      _buildStatColumn(context, 'CALORIES', '${session.caloriesBurned} kcal'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.colors.onSurface.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
