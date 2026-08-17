import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/meal_entry_model.dart';
import '../controllers/nutrition_workflow_controller.dart';
import '../../../daily_planner/utils/planner_helpers.dart';
import '../../../../core/widgets/shimmer_effect.dart';

class WeeklyMealReportSection extends ConsumerStatefulWidget {
  const WeeklyMealReportSection({super.key});

  @override
  ConsumerState<WeeklyMealReportSection> createState() =>
      _WeeklyMealReportSectionState();
}

class _WeeklyMealReportSectionState
    extends ConsumerState<WeeklyMealReportSection> {
  int _selectedIndex = 6; // Default to today (index 6 out of 0..6)

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyMealsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──
          Row(
            children: [
              Text(
                'WEEKLY NUTRITION HUB',
                style: AppTypography.labelBold.copyWith(
                  color: context.colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF60A5FA),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '7-DAY HISTORY',
                      style: TextStyle(
                        color: const Color(0xFF60A5FA),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Main Content Container ──
          weeklyAsync.when(
            data: (meals) => _buildHubContent(context, meals, isDark),
            loading: () => _buildLoadingShimmer(context, isDark),
            error: (err, st) => _buildErrorCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHubContent(
    BuildContext context,
    List<MealEntry> allMeals,
    bool isDark,
  ) {
    // 1. Generate the last 7 days (ending today)
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );

    // Ensure selectedIndex is within range
    if (_selectedIndex < 0 || _selectedIndex >= 7) {
      _selectedIndex = 6;
    }
    final selectedDate = last7Days[_selectedIndex];
    final selectedDateStr = PlannerHelpers.formatDate(selectedDate);

    // 2. Group meals by date string
    final Map<String, List<MealEntry>> mealsByDate = {};
    for (final meal in allMeals) {
      mealsByDate.putIfAbsent(meal.date, () => []).add(meal);
    }

    // 3. Compute daily metrics
    final List<double> dailyCalories = [];
    double maxCalories = 2000.0;
    double totalWeekCalories = 0.0;
    double totalWeekProtein = 0.0;
    double totalWeekCarbs = 0.0;
    double totalWeekFats = 0.0;
    int daysWithLogs = 0;

    for (final date in last7Days) {
      final dateStr = PlannerHelpers.formatDate(date);
      final dayMeals = mealsByDate[dateStr] ?? [];
      final cals = dayMeals.fold<double>(0, (sum, m) => sum + m.calories);
      final prot = dayMeals.fold<double>(0, (sum, m) => sum + m.protein);
      final carbs = dayMeals.fold<double>(0, (sum, m) => sum + m.carbs);
      final fats = dayMeals.fold<double>(0, (sum, m) => sum + m.fats);

      dailyCalories.add(cals);
      totalWeekCalories += cals;
      totalWeekProtein += prot;
      totalWeekCarbs += carbs;
      totalWeekFats += fats;

      if (cals > maxCalories) maxCalories = cals;
      if (dayMeals.isNotEmpty) daysWithLogs++;
    }

    final activeDaysCount = daysWithLogs > 0 ? daysWithLogs : 1;
    final avgCalories = (totalWeekCalories / 7).round();
    final avgProtein = (totalWeekProtein / activeDaysCount).round();
    final avgCarbs = (totalWeekCarbs / activeDaysCount).round();
    final avgFats = (totalWeekFats / activeDaysCount).round();

    // Selected day's meals
    final selectedDayMeals = mealsByDate[selectedDateStr] ?? [];
    final selectedDayCals = selectedDayMeals
        .fold<double>(0, (s, m) => s + m.calories)
        .round();
    final selectedDayProt = selectedDayMeals
        .fold<double>(0, (s, m) => s + m.protein)
        .round();
    final selectedDayCarbs = selectedDayMeals
        .fold<double>(0, (s, m) => s + m.carbs)
        .round();
    final selectedDayFats = selectedDayMeals
        .fold<double>(0, (s, m) => s + m.fats)
        .round();

    final isSelectedToday = _selectedIndex == 6;

    return Column(
      children: [
        // ── 1. Weekly Overview Card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.onSurface.withValues(alpha: 0.03)
                : context.colors.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.colors.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-DAY AVERAGE',
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$avgCalories',
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kcal/day',
                            style: TextStyle(
                              color: context.colors.onSurface.withValues(
                                alpha: 0.4,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Adherence Badge
                  _buildAdherencePill(context, avgCalories),
                ],
              ),
              const SizedBox(height: 16),

              // Macro Averages Row
              Row(
                children: [
                  _MacroStatBadge(
                    label: 'PROTEIN',
                    value: '${avgProtein}g/d',
                    color: const Color(0xFFFFB852),
                  ),
                  const SizedBox(width: 8),
                  _MacroStatBadge(
                    label: 'CARBS',
                    value: '${avgCarbs}g/d',
                    color: const Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 8),
                  _MacroStatBadge(
                    label: 'FATS',
                    value: '${avgFats}g/d',
                    color: const Color(0xFFEC4899),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Interactive Bar Chart ──
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final isToday = index == 6;
                    final isSelected = index == _selectedIndex;
                    final calories = dailyCalories[index];
                    final heightRatio = (calories / maxCalories).clamp(
                      0.0,
                      1.0,
                    );
                    final dayDate = last7Days[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: _BarChartColumn(
                          dayName: DateFormat('E').format(dayDate),
                          dayNum: DateFormat('d').format(dayDate),
                          heightRatio: heightRatio,
                          isToday: isToday,
                          isSelected: isSelected,
                          calories: calories.round(),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 2. Selected Day Meal History Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? context.colors.onSurface.withValues(alpha: 0.03)
                : context.colors.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelectedToday
                  ? context.colors.primary.withValues(alpha: 0.3)
                  : context.colors.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header for Selected Day
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelectedToday
                          ? context.colors.primary.withValues(alpha: 0.15)
                          : context.colors.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isSelectedToday
                            ? Icons.today_rounded
                            : Icons.calendar_month_rounded,
                        color: isSelectedToday
                            ? context.colors.primary
                            : context.colors.onSurface.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSelectedToday
                              ? 'TODAY\'S MEAL HISTORY'
                              : 'MEALS FOR ${DateFormat('EEEE, MMM d').format(selectedDate).toUpperCase()}',
                          style: TextStyle(
                            color: context.colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${selectedDayMeals.length} logged items • $selectedDayCals kcal',
                          style: TextStyle(
                            color: context.colors.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedDayMeals.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'P:${selectedDayProt}g C:${selectedDayCarbs}g F:${selectedDayFats}g',
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 14),

              // Meal Items List
              if (selectedDayMeals.isEmpty)
                _buildEmptyDayState(context, isSelectedToday)
              else
                Column(
                  children: selectedDayMeals.map((meal) {
                    return _HistoryMealTile(
                      meal: meal,
                      onDelete: () {
                        ref.read(manualMealProvider.notifier).deleteMeal(meal);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${meal.foodName} removed'),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdherencePill(BuildContext context, int avgCals) {
    final String label;
    final Color color;
    final IconData icon;

    if (avgCals == 0) {
      label = 'NO DATA';
      color = Colors.grey;
      icon = Icons.hourglass_empty_rounded;
    } else if (avgCals < 1500) {
      label = 'DEFICIT';
      color = const Color(0xFF3B82F6);
      icon = Icons.trending_down_rounded;
    } else if (avgCals <= 2500) {
      label = 'OPTIMAL';
      color = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else {
      label = 'SURPLUS';
      color = const Color(0xFFF59E0B);
      icon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, bool isToday) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.no_meals_rounded,
            color: context.colors.onSurface.withValues(alpha: 0.2),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToday
                  ? 'No meals logged yet today. Tap LOG MEAL below to get started.'
                  : 'No meal logs recorded for this day.',
              style: TextStyle(
                color: context.colors.onSurface.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.onSurface.withValues(alpha: 0.03)
            : context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerEffect(width: 140, height: 32),
          const SizedBox(height: 20),
          const ShimmerEffect(width: double.infinity, height: 120),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Failed to load weekly report.',
            style: TextStyle(
              color: context.colors.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroStatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartColumn extends StatelessWidget {
  final String dayName;
  final String dayNum;
  final double heightRatio;
  final bool isToday;
  final bool isSelected;
  final int calories;

  const _BarChartColumn({
    required this.dayName,
    required this.dayNum,
    required this.heightRatio,
    required this.isToday,
    required this.isSelected,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isSelected
        ? context.colors.primary
        : (isToday
              ? context.colors.primary.withValues(alpha: 0.5)
              : context.colors.onSurface.withValues(alpha: 0.12));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Calories indicator above bar
        Text(
          calories > 0 ? '$calories' : '',
          style: TextStyle(
            color: isSelected
                ? context.colors.primary
                : context.colors.onSurface.withValues(alpha: 0.3),
            fontSize: 8,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),

        // Bar Track & Animated Fill
        Expanded(
          child: Container(
            width: isSelected ? 28 : 22,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : context.colors.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: context.colors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    )
                  : null,
            ),
            child: FractionallySizedBox(
              heightFactor: heightRatio == 0 ? 0.06 : heightRatio,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutQuad,
                decoration: BoxDecoration(
                  gradient: isSelected || isToday
                      ? context.customColors.primaryGradient
                      : null,
                  color: isSelected || isToday ? null : barColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.colors.primary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Day Name Label
        Text(
          dayName.toUpperCase(),
          style: TextStyle(
            color: isSelected
                ? context.colors.primary
                : (isToday
                      ? context.colors.onSurface
                      : context.colors.onSurface.withValues(alpha: 0.4)),
            fontSize: 10,
            fontWeight: isSelected || isToday
                ? FontWeight.w900
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoryMealTile extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onDelete;

  const _HistoryMealTile({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAiScan = meal.source == 'ai_scan';
    final timeStr = DateFormat('h:mm a').format(meal.loggedAt);

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFEF4444),
          size: 20,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colors.onSurface.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Meal Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isAiScan
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                    : context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  isAiScan
                      ? Icons.camera_alt_rounded
                      : Icons.restaurant_rounded,
                  color: isAiScan
                      ? const Color(0xFF8B5CF6)
                      : context.colors.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Food Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.foodName,
                          style: TextStyle(
                            color: context.colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'P: ${meal.protein.round()}g • C: ${meal.carbs.round()}g • F: ${meal.fats.round()}g',
                    style: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Calories Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${meal.calories.round()} kcal',
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
