// lib/features/daily_planner/presentation/widgets/planner_day_card.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../../../core/theme/app_colors.dart';

class PlannerDayCard extends StatelessWidget {
  final DateTime date;
  final PlannerItem? item;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PlannerDayCard({
    super.key,
    required this.date,
    this.item,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = item?.status ?? PlannerStatus.planned;
    final hasWorkout = item?.workoutId != null;
    final isCompleted = item?.completed == true;
    final isMissed = !isCompleted &&
        date.isBefore(DateTime.now()) &&
        !isToday &&
        hasWorkout;

    // ─── Derive accent color & icon ───
    Color accentColor;
    IconData displayIcon;
    String displayLabel;

    if (status == PlannerStatus.recovery) {
      accentColor = Color(0xFF8B5CF6); // Purple
      displayIcon = Icons.spa_rounded;
      displayLabel = 'RECOVERY';
    } else if (isCompleted) {
      accentColor = context.colors.primary;
      displayIcon = Icons.check_rounded;
      displayLabel = 'DONE';
    } else if (isMissed) {
      accentColor = Color(0xFF6B2020); // Dim red
      displayIcon = Icons.close_rounded;
      displayLabel = 'MISSED';
    } else if (hasWorkout) {
      final name = (item?.workoutName ?? '').toLowerCase();
      if (name.contains('push')) {
        accentColor = context.colors.primary;
        displayIcon = Icons.fitness_center_rounded;
        displayLabel = 'PUSH';
      } else if (name.contains('pull')) {
        accentColor = Color(0xFFFFB852);
        displayIcon = Icons.bolt_rounded;
        displayLabel = 'PULL';
      } else if (name.contains('leg')) {
        accentColor = Color(0xFFFF5288);
        displayIcon = Icons.directions_walk_rounded;
        displayLabel = 'LEGS';
      } else if (name.contains('upper')) {
        accentColor = Color(0xFF52FFB8);
        displayIcon = Icons.accessibility_new_rounded;
        displayLabel = 'UPPER';
      } else if (name.contains('cardio')) {
        accentColor = Color(0xFF52D8FF);
        displayIcon = Icons.directions_run_rounded;
        displayLabel = 'CARDIO';
      } else if (name.contains('core')) {
        accentColor = Color(0xFFFF9F43);
        displayIcon = Icons.straighten_rounded;
        displayLabel = 'CORE';
      } else {
        accentColor = context.colors.primary;
        displayIcon = Icons.fitness_center_rounded;
        displayLabel = 'TRAIN';
      }
    } else {
      accentColor = Color(0xFF4A4A4A);
      displayIcon = Icons.remove_rounded;
      displayLabel = 'REST';
    }

    // ─── Border color logic ───
    Color borderColor;
    double borderWidth;
    if (isSelected) {
      borderColor = context.colors.primary.withOpacity(0.8);
      borderWidth = 1.5;
    } else if (isToday) {
      borderColor = context.colors.primary.withOpacity(0.3);
      borderWidth = 1.0;
    } else {
      borderColor = context.colors.onSurface.withValues(alpha: 0.04);
      borderWidth = 0.5;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 72,
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.onSurface.withValues(alpha: 0.04)
              : context.colors.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day name
            Text(
              PlannerHelpers.getDayNameShort(date),
              style: TextStyle(
                color: isToday
                    ? context.colors.primary
                    : context.colors.onSurface.withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 6),

            // Date number
            Text(
              '${date.day}',
              style: TextStyle(
                color: isToday ? context.colors.onSurface : context.colors.onSurface.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 10),

            // Status icon ring
            AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? accentColor.withOpacity(0.15)
                    : accentColor.withOpacity(0.06),
                border: Border.all(
                  color: isCompleted
                      ? accentColor.withOpacity(0.6)
                      : accentColor.withOpacity(0.15),
                  width: isCompleted ? 1.5 : 0.8,
                ),
              ),
              child: Center(
                child: Icon(
                  displayIcon,
                  color: accentColor,
                  size: 14,
                ),
              ),
            ),
            SizedBox(height: 8),

            // Label
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayLabel,
                style: TextStyle(
                  color: isSelected
                      ? context.colors.onSurface.withValues(alpha: 0.7)
                      : context.colors.onSurface.withValues(alpha: 0.35),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
