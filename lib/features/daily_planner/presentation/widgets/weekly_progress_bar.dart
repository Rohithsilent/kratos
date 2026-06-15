// lib/features/daily_planner/presentation/widgets/weekly_progress_bar.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';

class WeeklyProgressBar extends StatelessWidget {
  final int activeIndex; // 0 to 6 (Monday to Sunday)
  final double progress; // Overall percentage

  const WeeklyProgressBar({
    super.key,
    required this.activeIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Background track line
              Container(
                height: 2,
                color: context.colors.onSurface.withValues(alpha: 0.08),
              ),
              // Filled track line up to active day
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (activeIndex / 6.0).clamp(0.0, 1.0),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.colors.primary, context.colors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              // Seven dots spaced out perfectly
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final bool isPassed = index < activeIndex;
                  final bool isActive = index == activeIndex;

                  return Container(
                    width: isActive ? 12 : 8,
                    height: isActive ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                          ? context.colors.primary 
                          : (isPassed ? context.colors.primary.withOpacity(0.6) : Color(0xFF2A2A2A)),
                      border: Border.all(
                        color: isActive 
                            ? context.colors.onSurface
                            : (isPassed ? context.colors.primary.withOpacity(0.8) : Colors.transparent),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: context.colors.primary.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
