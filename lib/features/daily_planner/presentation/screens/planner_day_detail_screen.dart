// lib/features/daily_planner/presentation/screens/planner_day_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../workout/presentation/controllers/workout_controller.dart';
import '../../domain/models/planner_item_model.dart';
import '../../domain/enums/planner_status.dart';
import '../../utils/planner_helpers.dart';
import '../controllers/planner_controller.dart';
import '../../data/repositories/planner_repository.dart';

class PlannerDayDetailScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const PlannerDayDetailScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<PlannerDayDetailScreen> createState() => _PlannerDayDetailScreenState();
}

class _PlannerDayDetailScreenState extends ConsumerState<PlannerDayDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedWorkoutId;
  PlannerStatus _selectedStatus = PlannerStatus.planned;

  @override
  void initState() {
    super.initState();
    // Pre-populate if plan item already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dateStr = PlannerHelpers.formatDate(widget.date);
      final items = ref.read(plannerListProvider).value ?? [];
      final existing = items.firstWhere(
        (i) => i.date == dateStr,
        orElse: () => PlannerItem(id: '', date: '', status: PlannerStatus.planned, createdAt: DateTime.now()),
      );

      if (existing.id.isNotEmpty) {
        _notesController.text = existing.notes ?? '';
        setState(() {
          _selectedWorkoutId = existing.workoutId;
          _selectedStatus = existing.status;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final dateStr = PlannerHelpers.formatDate(widget.date);
    final notifier = ref.read(plannerListProvider.notifier);

    if (_selectedStatus == PlannerStatus.recovery) {
      await notifier.scheduleRecovery(date: dateStr);
    } else if (_selectedWorkoutId != null) {
      final workouts = ref.read(workoutListProvider).value ?? [];
      final matchingWorkout = workouts.firstWhere((w) => w.id == _selectedWorkoutId);
      await notifier.scheduleWorkout(
        date: dateStr,
        workoutId: _selectedWorkoutId!,
        workoutName: matchingWorkout.name,
      );
    }

    // Save notes or status overrides
    final items = ref.read(plannerListProvider).value ?? [];
    final savedItem = items.firstWhere(
      (i) => i.date == dateStr,
      orElse: () => PlannerItem(id: '', date: '', status: PlannerStatus.planned, createdAt: DateTime.now()),
    );

    if (savedItem.id.isNotEmpty) {
      final repository = ref.read(plannerRepositoryProvider);
      var updated = savedItem.copyWith(
        notes: _notesController.text,
        status: _selectedStatus,
        completed: _selectedStatus == PlannerStatus.completed,
      );
      await repository.savePlannerItem(updated);
      // Refresh state
      ref.invalidate(plannerListProvider);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.customColors.success,
          content: Text('Plan updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutListProvider);
    final dateStr = '${widget.date.day} ${PlannerHelpers.getWeekString(widget.date).split(' ').first}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.70), size: 16),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'TACTICAL DAY SCHEDULER',
          style: AppTypography.labelBold.copyWith(
            color: Colors.white,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            // Date Header GlassCard
            GlassCard(
              borderRadius: 20,
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.primary.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: context.colors.primary, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${PlannerHelpers.getDayNameShort(widget.date)}, ${dateStr.toUpperCase()}',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 18, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Define your tactical fitness objectives.',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 11),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 24),

            // 1. SELECT TARGET WORKOUT
            Text(
              'ASSIGN TRAINING WORKOUT',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            workoutsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.colors.primary)),
              error: (err, st) => Center(child: Text('Failed to load workouts: $err', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24)))),
              data: (workouts) {
                if (workouts.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No custom workouts created yet! Build a routine first.',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.70), fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/workout/create'),
                          child: Text('BUILD', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w900)),
                        )
                      ],
                    ),
                  );
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedWorkoutId,
                      dropdownColor: Color(0xFF0F0F0F),
                      icon: Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60)),
                      hint: Text('Select Routine...', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.30), fontSize: 13)),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Rest / Recovery Day', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        ...workouts.map((w) {
                          return DropdownMenuItem<String?>(
                            value: w.id,
                            child: Text(w.name, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedWorkoutId = val;
                          if (val == null) {
                            _selectedStatus = PlannerStatus.recovery;
                          } else {
                            _selectedStatus = PlannerStatus.planned;
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),

            // 2. MISSION PLANNER STATUS
            Text(
              'MISSION STATUS OVERRIDE',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlannerStatus.values.map((status) {
                final isSelected = _selectedStatus == status;
                Color statusColor = context.colors.primary;
                if (status == PlannerStatus.completed) statusColor = context.customColors.success;
                if (status == PlannerStatus.recovery) statusColor = Colors.tealAccent;
                if (status == PlannerStatus.skipped) statusColor = Colors.orangeAccent;
                if (status == PlannerStatus.planned) statusColor = Colors.blueAccent;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? statusColor.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? statusColor : Colors.white.withOpacity(0.04),
                        width: isSelected ? 1.0 : 0.8,
                      ),
                    ),
                    child: Text(
                      status.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? statusColor : Colors.white.withOpacity(0.60),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // 3. TACTICAL NOTES FOR THE DAY
            Text(
              'PLANNING OR PRE-WORKOUT NOTES',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: 'Enter targets, energy levels, hydration plans, or notes...',
                  hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), fontSize: 12),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 40),

            // Save Action Button
            GestureDetector(
              onTap: _handleSave,
              child: Container(
                height: 50,
                decoration: context.customColors.primaryGradient.colors.isNotEmpty
                    ? BoxDecoration(
                        gradient: context.customColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                child: Center(
                  child: Text(
                    'COMMIT OBJECTIVES',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
