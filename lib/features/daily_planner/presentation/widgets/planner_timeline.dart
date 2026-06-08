// lib/features/daily_planner/presentation/widgets/planner_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/planner_controller.dart';
import '../controllers/planner_week_controller.dart';
import '../controllers/planner_completion_controller.dart';
import 'planner_day_card.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';

class PlannerTimeline extends ConsumerWidget {
  const PlannerTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekState = ref.watch(plannerWeekProvider);
    final weekDates = PlannerHelpers.getWeekDates(weekState.referenceDate);
    final weekStr = PlannerHelpers.getWeekString(weekState.referenceDate);
    final plannerItemsAsync = ref.watch(plannerListProvider);
    final stats = ref.watch(plannerStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══ Header ═══
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'WEEKLY PLAN',
                style: AppTypography.labelBold.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(width: 10),
              Text(
                weekStr,
                style: TextStyle(color: Colors.white.withOpacity(0.25),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              // Navigation
              GestureDetector(
                onTap: () => ref.read(plannerWeekProvider.notifier).selectPreviousWeek(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: Colors.white.withOpacity(0.38),
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: 6),
              GestureDetector(
                onTap: () => ref.read(plannerWeekProvider.notifier).selectNextWeek(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.38),
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditWeekBottomSheet(context, ref, weekState.referenceDate),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Text(
                    'EDIT',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: Colors.white.withOpacity(0.38), size: 12),
              SizedBox(width: 4),
              Text(
                'Long-press a day to quick-assign workout',
                style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),

        // ═══ Day Cards Row — Properly scrollable ═══
        SizedBox(
          height: 150,
          child: plannerItemsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
            error: (err, st) => Center(
              child: Text('$err', style: TextStyle(color: Colors.white.withOpacity(0.24), fontSize: 10)),
            ),
            data: (allItems) {
              final nowFormatted = PlannerHelpers.formatDate(DateTime.now());

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = weekDates[index];
                  final dateStr = PlannerHelpers.formatDate(date);

                  final item = allItems.firstWhere(
                    (i) => i.date == dateStr,
                    orElse: () => PlannerItem(
                      id: '',
                      date: dateStr,
                      status: PlannerStatus.planned,
                      createdAt: DateTime.now(),
                    ),
                  );

                  final bool isToday = dateStr == nowFormatted;
                  final bool isSelected = dateStr ==
                      PlannerHelpers.formatDate(weekState.selectedDate);

                  return PlannerDayCard(
                    date: date,
                    item: item.id.isNotEmpty ? item : null,
                    isToday: isToday,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(plannerWeekProvider.notifier).selectDate(date);
                    },
                    onLongPress: () {
                      ref.read(plannerWeekProvider.notifier).selectDate(date);
                      _showQuickAssignSheet(context, ref, date);
                    },
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 8),

        // ═══ Compact week summary ═══
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${stats.totalWorkoutsThisWeek}/${stats.totalScheduledThisWeek} completed',
                    style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${(stats.weeklyCompletionPercentage * 100).round()}% adherence',
                style: TextStyle(
                  color: stats.weeklyCompletionPercentage >= 0.8
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.25),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditWeekBottomSheet(
      BuildContext context, WidgetRef ref, DateTime referenceDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TACTICAL WEEK OPERATIONS',
                  style: TextStyle(color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 18),
                ListTile(
                  leading:
                      Icon(Icons.copy_rounded, color: AppColors.primary),
                  title: Text('Duplicate Plan to Next Week',
                      style: TextStyle(color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Copies this entire week structure into the upcoming week.',
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 10)),
                  onTap: () async {
                    Navigator.pop(context);
                    final nextWeek =
                        referenceDate.add(Duration(days: 7));
                    await ref
                        .read(plannerListProvider.notifier)
                        .duplicateWeek(referenceDate, nextWeek);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Week plan duplicated successfully!',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                  },
                ),
                Divider(color: Colors.white.withOpacity(0.10)),
                ListTile(
                  leading: Icon(Icons.restart_alt_rounded, color: Colors.white.withOpacity(0.60)),
                  title: Text('Clear This Week\'s Schedules',
                      style: TextStyle(color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Deletes all scheduled routines to plan fresh.',
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 10)),
                  onTap: () async {
                    Navigator.pop(context);
                    final weekDates =
                        PlannerHelpers.getWeekDates(referenceDate);
                    final notifier =
                        ref.read(plannerListProvider.notifier);
                    final currentItems =
                        ref.read(plannerListProvider).value ?? [];
                    for (var d in weekDates) {
                      final dStr = PlannerHelpers.formatDate(d);
                      final match = currentItems.firstWhere(
                          (i) => i.date == dStr,
                          orElse: () => PlannerItem(
                              id: '',
                              date: '',
                              status: PlannerStatus.planned,
                              createdAt: DateTime.now()));
                      if (match.id.isNotEmpty) {
                        await notifier.deletePlan(itemId: match.id);
                      }
                    }
                  },
                ),
                Divider(color: Colors.white.withOpacity(0.10)),
                ListTile(
                  leading: Icon(Icons.today_rounded, color: Colors.white.withOpacity(0.60)),
                  title: Text('Jump to Today',
                      style: TextStyle(color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Reset the calendar view to the current week.',
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 10)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(plannerWeekProvider.notifier).resetToToday();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickAssignSheet(BuildContext context, WidgetRef ref, DateTime date) {
    final workoutsAsync = ref.read(workoutListProvider);
    final dateStr = PlannerHelpers.formatDate(date);
    final displayDate = '${PlannerHelpers.getDayNameShort(date)}, ${date.day}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK ASSIGN: $displayDate',
                  style: TextStyle(color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 18),
                workoutsAsync.when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No custom workouts available. Create one first.',
                          style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 13),
                        ),
                      );
                    }
                    return Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: workouts.length + 1,
                        separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.10), height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Recovery option
                            return ListTile(
                              leading: Icon(Icons.spa_rounded, color: Colors.tealAccent),
                              title: Text('Rest / Recovery Day',
                                  style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                Navigator.pop(context);
                                await ref.read(plannerListProvider.notifier).scheduleRecovery(date: dateStr);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.teal,
                                      content: Text('Scheduled Recovery Day', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                }
                              },
                            );
                          }
                          
                          final w = workouts[index - 1];
                          return ListTile(
                            leading: Icon(Icons.fitness_center_rounded, color: AppColors.primary),
                            title: Text(w.name, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(w.split, style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11)),
                            onTap: () async {
                              Navigator.pop(context);
                              await ref.read(plannerListProvider.notifier).scheduleWorkout(
                                date: dateStr,
                                workoutId: w.id,
                                workoutName: w.name,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    content: Text('Workout Assigned', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
