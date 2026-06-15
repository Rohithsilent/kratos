import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/planner_item_model.dart';
import '../../utils/planner_helpers.dart';

class UpcomingSessionCard extends StatelessWidget {
  final PlannerItem item;

  const UpcomingSessionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final parsedDate = PlannerHelpers.parseDate(item.date);
    final dayNum = parsedDate.day;
    final dayName = PlannerHelpers.getDayNameShort(parsedDate);

    // Derive split info
    final workoutName = item.workoutName ?? 'Scheduled Workout';
    final splitName = workoutName.toLowerCase();
    String splitTag = 'TRAINING';
    Color splitColor = context.colors.primary;
    if (splitName.contains('push')) {
      splitTag = 'PUSH';
      splitColor = context.colors.primary;
    } else if (splitName.contains('pull')) {
      splitTag = 'PULL';
      splitColor = const Color(0xFFFFB852);
    } else if (splitName.contains('leg')) {
      splitTag = 'LEGS';
      splitColor = const Color(0xFFFF5288);
    } else if (splitName.contains('upper')) {
      splitTag = 'UPPER';
      splitColor = const Color(0xFF52FFB8);
    } else if (splitName.contains('cardio')) {
      splitTag = 'CARDIO';
      splitColor = const Color(0xFF52D8FF);
    } else if (splitName.contains('core')) {
      splitTag = 'CORE';
      splitColor = const Color(0xFFFF9F43);
    }

    return GestureDetector(
      onTap: () {
        if (item.workoutId != null) {
          context.push('/workout/detail/${item.workoutId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.onSurface.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Date block
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: splitColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: splitColor.withOpacity(0.12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: splitColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: splitColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          splitTag,
                          style: TextStyle(
                            color: splitColor,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workoutName,
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: context.colors.onSurface.withValues(alpha: 0.15),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
