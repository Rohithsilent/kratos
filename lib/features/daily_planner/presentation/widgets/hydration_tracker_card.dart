import '../../../../core/theme/app_colors.dart';
// lib/features/daily_planner/presentation/widgets/hydration_tracker_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/hydration_controller.dart';

class HydrationTrackerCard extends ConsumerWidget {
  const HydrationTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(todayHydrationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'HYDRATION',
            style: AppTypography.labelBold.copyWith(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                // Top Row: Water stats + quick add
                Row(
                  children: [
                    // Water drop icon with glow
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF0A1A2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3B82F6).withOpacity(0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.water_drop_rounded,
                          color: Color(0xFF60A5FA),
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: hydration.litersConsumed.toStringAsFixed(1),
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${hydration.litersTarget.toStringAsFixed(1)} L',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.3),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${hydration.glassesConsumed} of ${hydration.glassesTarget} glasses',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.2),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick add button
                    GestureDetector(
                      onTap: () {
                        ref.read(hydrationLogProvider.notifier).addWater(250);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF0A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF3B82F6).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Color(0xFF60A5FA),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '250ml',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: hydration.progress),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        color: Color(0xFF3B82F6),
                        backgroundColor: Colors.white.withOpacity(0.04),
                        minHeight: 5,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),

                // Glass indicators row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(hydration.glassesTarget.clamp(1, 12), (i) {
                    final isFilled = i < hydration.glassesConsumed;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isFilled) {
                            ref.read(hydrationLogProvider.notifier).addWater(250);
                          }
                        },
                        child: Container(
                          height: 18,
                          margin: EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? Color(0xFF3B82F6).withOpacity(0.3)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isFilled
                                  ? Color(0xFF3B82F6).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.04),
                              width: 0.5,
                            ),
                          ),
                          child: isFilled
                              ? Center(
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    color: Color(0xFF60A5FA),
                                    size: 8,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
