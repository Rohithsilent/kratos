// lib/features/daily_planner/presentation/screens/daily_planner_screen.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/planner_controller.dart';
import '../controllers/planner_week_controller.dart';
import '../controllers/planner_completion_controller.dart';
import '../controllers/today_mission_controller.dart';
import '../widgets/planner_stat_chip.dart';
import '../widgets/planner_timeline.dart';
import '../widgets/mission_card.dart';
import '../widgets/recovery_day_card.dart';
import '../widgets/consistency_heatmap.dart';
import '../widgets/nutrition_tracker_card.dart';
import '../widgets/hydration_tracker_card.dart';
import '../widgets/upcoming_session_card.dart';
import '../widgets/upcoming_sessions_bottom_sheet.dart';
import '../../utils/planner_helpers.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';
import '../../../workout/presentation/widgets/past_session_card.dart';

class DailyPlannerScreen extends ConsumerWidget {
  const DailyPlannerScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Burn the midnight oil.';
    if (hour < 12) return 'Rise and conquer.';
    if (hour < 17) return 'Stay locked in.';
    if (hour < 21) return 'Finish what you started.';
    return 'Rest breeds power.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(plannerStatsProvider);
    final todayMission = ref.watch(todayMissionProvider);
    final plannerItemsAsync = ref.watch(plannerListProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ═══ Ambient Background Glows ═══
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withOpacity(0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ═══ Main Content ═══
          SafeArea(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ──────────────────────────────────────────────
                // SECTION 1: HERO HEADER
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DAILY PLANNER',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : context.customColors.grey900,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final weekState = ref.read(
                                      plannerWeekProvider,
                                    );
                                    context.push(
                                      '/planner/detail',
                                      extra: weekState.selectedDate,
                                    );
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : context.customColors.grey900.withOpacity(0.54),
                                      size: 16,
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : context.customColors.grey900.withOpacity(0.35),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ──────────────────────────────────────────────
                // SECTION 2: FUNCTIONAL ANALYTICS CARDS
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        PlannerStatChip(
                          icon: Icons.local_fire_department_rounded,
                          value: '${stats.currentStreak}',
                          label: 'Day Streak',
                          glowColor: context.colors.primary,
                        ),
                        SizedBox(width: 8),
                        PlannerStatChip(
                          icon: Icons.track_changes_rounded,
                          value:
                              '${(stats.weeklyCompletionPercentage * 100).round()}%',
                          label: 'Weekly Goal',
                          glowColor: Color(0xFFFF6B6B),
                        ),
                        SizedBox(width: 8),
                        PlannerStatChip(
                          icon: Icons.timer_outlined,
                          value: stats.totalDurationHoursThisWeek > 0.0
                              ? '${stats.totalDurationHoursThisWeek.toStringAsFixed(1)}h'
                              : '0h',
                          label: 'Duration',
                          glowColor: Color(0xFFFFB852),
                        ),
                        SizedBox(width: 8),
                        PlannerStatChip(
                          icon: Icons.fitness_center_rounded,
                          value: '${stats.totalWorkoutsThisWeek}',
                          label: 'Workouts',
                          glowColor: Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ──────────────────────────────────────────────
                // SECTION 3: TACTICAL CONSISTENCY MATRIX (HEATMAP)
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(child: ConsistencyHeatmap()),

                SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ──────────────────────────────────────────────
                // SECTION 4: TODAY'S MISSION
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: todayMission.isRecovery || todayMission.workout == null
                      ? RecoveryDayCard()
                      : MissionCard(
                          plannerItem: todayMission.plannerItem!,
                          workout: todayMission.workout!,
                        ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ──────────────────────────────────────────────
                // SECTION 5: NUTRITION & HYDRATION
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(child: NutritionTrackerCard()),

                SliverToBoxAdapter(child: SizedBox(height: 24)),

                SliverToBoxAdapter(child: HydrationTrackerCard()),

                SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ──────────────────────────────────────────────
                // SECTION 6: WEEKLY TIMELINE
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(child: PlannerTimeline()),

                SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ──────────────────────────────────────────────
                // SECTION 7: UPCOMING SESSIONS
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UPCOMING SESSIONS',
                          style: AppTypography.labelBold.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (plannerItemsAsync.hasValue) {
                              final items = plannerItemsAsync.value!;
                              final nowFormatted = PlannerHelpers.formatDate(DateTime.now());
                              final allUpcoming = items.where((item) {
                                return item.workoutId != null && item.date.compareTo(nowFormatted) > 0;
                              }).toList();
                              allUpcoming.sort((a, b) => a.date.compareTo(b.date));
                              
                              if (allUpcoming.isNotEmpty) {
                                UpcomingSessionsBottomSheet.show(context, allUpcoming);
                              }
                            }
                          },
                          child: Text(
                            'VIEW ALL',
                            style: TextStyle(
                              color: context.colors.primary.withOpacity(0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 10)),

                plannerItemsAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (err, st) => SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'Failed to load: $err',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : context.customColors.grey900.withOpacity(0.24),
                        ),
                      ),
                    ),
                  ),
                  data: (items) {
                    final nowFormatted = PlannerHelpers.formatDate(
                      DateTime.now(),
                    );

                    final upcomingItems = items.where((item) {
                      return item.workoutId != null &&
                          item.date.compareTo(nowFormatted) > 0;
                    }).toList();

                    upcomingItems.sort((a, b) => a.date.compareTo(b.date));

                    if (upcomingItems.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : context.customColors.grey900.withOpacity(0.15),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No upcoming sessions scheduled. Use the weekly planner to plan your training.',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : context.customColors.grey900.withOpacity(0.25),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = upcomingItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: UpcomingSessionCard(item: item),
                        );
                      }, childCount: upcomingItems.length.clamp(0, 3)),
                    );
                  },
                ),

                SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ──────────────────────────────────────────────
                // SECTION 8: RECENT HISTORY
                // ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'RECENT HISTORY',
                      style: AppTypography.labelBold.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                historyAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color:
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : context.customColors.grey900.withOpacity(0.15),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No recent sessions. Start a workout to see history here.',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : context.customColors.grey900.withOpacity(0.25),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Show only top 3 recent sessions
                    final topSessions = sessions.take(3).toList();
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          child: PastSessionCard(
                            session: topSessions[index],
                            showRoutineName: true,
                          ),
                        );
                      }, childCount: topSessions.length),
                    );
                  },
                  loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Bottom safe space
                SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
