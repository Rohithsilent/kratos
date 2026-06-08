// lib/features/workout/presentation/widgets/add_to_workout_bottom_sheet.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../exercise_library/domain/models/exercise_model.dart';
import '../controllers/workout_controller.dart';
import '../../domain/models/workout_model.dart';

class AddToWorkoutBottomSheet extends ConsumerStatefulWidget {
  final Exercise exercise;

  const AddToWorkoutBottomSheet({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<AddToWorkoutBottomSheet> createState() => _AddToWorkoutBottomSheetState();
}

class _AddToWorkoutBottomSheetState extends ConsumerState<AddToWorkoutBottomSheet> {
  int _sets = 4;
  String _selectedRepRange = '10-12';
  int _restSeconds = 90;
  double _weight = 80;
  String _weightUnit = 'KG';
  final TextEditingController _notesController = TextEditingController();
  
  bool _showWorkoutPicker = false;
  bool _isCreatingCustomRest = false;
  final TextEditingController _customRestTimerController = TextEditingController();

  final List<String> _repRanges = ['6-8', '8-10', '10-12', '12-15', '15+'];
  final List<int> _restOptions = [30, 60, 90, 120];

  @override
  void dispose() {
    _notesController.dispose();
    _customRestTimerController.dispose();
    super.dispose();
  }

  // Generate target sets from current config
  List<WorkoutSet> _generateSets() {
    // Parse target reps from range string (e.g. '10-12' -> 12 reps)
    int targetReps = 12;
    if (_selectedRepRange == '6-8') targetReps = 8;
    if (_selectedRepRange == '8-10') targetReps = 10;
    if (_selectedRepRange == '10-12') targetReps = 12;
    if (_selectedRepRange == '12-15') targetReps = 15;
    if (_selectedRepRange == '15+') targetReps = 20;

    return List.generate(_sets, (index) {
      return WorkoutSet(
        id: generateUniqueId(),
        setNumber: index + 1,
        reps: targetReps,
        weight: _weight,
      );
    });
  }

  WorkoutExercise _buildWorkoutExercise() {
    return WorkoutExercise(
      exerciseId: widget.exercise.id,
      name: widget.exercise.name,
      category: widget.exercise.category,
      image: widget.exercise.image,
      gifUrl: widget.exercise.gifUrl,
      restSeconds: _restSeconds,
      sets: _generateSets(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  void _handleCreateNewWorkout() {
    final newExercise = _buildWorkoutExercise();
    
    // Pre-populate builder state with this new exercise
    ref.read(workoutBuilderProvider.notifier).reset();
    ref.read(workoutBuilderProvider.notifier).addExercise(newExercise);
    
    // Close modal and route to builder page
    Navigator.pop(context);
    context.push('/workout/create');
  }

  Future<void> _handleAddToWorkout(Workout workout) async {
    final newExercise = _buildWorkoutExercise();
    
    // Append exercise to existing workout
    final updatedExercises = [...workout.exercises, newExercise];
    final updatedWorkout = Workout(
      id: workout.id,
      userId: workout.userId,
      name: workout.name,
      split: workout.split,
      createdAt: workout.createdAt,
      exercises: updatedExercises,
    );

    // Save back to repository
    await ref.read(workoutListProvider.notifier).addOrUpdateWorkout(updatedWorkout);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.customColors.success,
          content: Text(
            'Added ${widget.exercise.name} to ${workout.name}!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutListProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 10,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF0C0C0C).withOpacity(0.92),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Notch / Drag indicator
              Center(
                child: Container(
                  width: 48,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),

              if (_showWorkoutPicker) ...[
                // SELECT WORKOUT SCREEN
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.70), size: 18),
                      onPressed: () => setState(() => _showWorkoutPicker = false),
                    ),
                    Text(
                      'ADD TO EXISTING ROUTINE',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                workoutsAsync.when(
                  loading: () => Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: CircularProgressIndicator(color: context.colors.primary),
                    ),
                  ),
                  error: (err, st) => Center(
                    child: Text('Failed to load workouts: $err', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54))),
                  ),
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No routines found.\nCreate a new custom routine instead!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 13, height: 1.4),
                            ),
                            SizedBox(height: 20),
                            GestureDetector(
                              onTap: _handleCreateNewWorkout,
                              child: Container(
                                height: 48,
                                decoration: AppDecorations.primaryButton(context, borderRadius: 14),
                                child: Center(
                                  child: Text(
                                    'CREATE NEW WORKOUT',
                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _handleAddToWorkout(workout),
                            child: GlassCard(
                              borderRadius: 16,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        workout.name.toUpperCase(),
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '${workout.split}  •  ${workout.exercises.length} Exercises',
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.add_circle_outline_rounded, color: context.colors.primary, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                // EXERCISE PREVIEW HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          widget.exercise.localImagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.black54,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exercise.name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                widget.exercise.muscleGroup.toUpperCase(),
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text('  •  ', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24))),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.exercise.difficulty.toUpperCase(),
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.10), height: 28, thickness: 1),

                // SETS SELECTOR
                Text(
                  'SETS',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60), size: 28),
                      onPressed: () {
                        if (_sets > 1) setState(() => _sets--);
                      },
                    ),
                    Text(
                      '$_sets',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.primary, size: 28),
                      onPressed: () => setState(() => _sets++),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // REPS SELECTOR
                Text(
                  'REPS TARGET RANGE',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Row(
                    children: _repRanges.map((range) {
                      final isSelected = _selectedRepRange == range;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            range,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.60),
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: context.colors.primary,
                          backgroundColor: Colors.white.withOpacity(0.04),
                          onSelected: (val) {
                            if (val) setState(() => _selectedRepRange = range);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? context.colors.primary : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),

                // REST SELECTOR
                Text(
                  'REST TIME BETWEEN SETS',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            ..._restOptions.map((sec) {
                              final isSelected = !_isCreatingCustomRest && _restSeconds == sec;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    '$sec sec',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.60),
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: context.colors.primary,
                                  backgroundColor: Colors.white.withOpacity(0.04),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _isCreatingCustomRest = false;
                                        _restSeconds = sec;
                                      });
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? context.colors.primary : Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            }),
                            ChoiceChip(
                              label: Text(
                                _isCreatingCustomRest ? '${_restSeconds}s (Custom)' : 'Custom',
                                style: TextStyle(
                                  color: _isCreatingCustomRest ? Colors.white : Colors.white.withOpacity(0.60),
                                  fontWeight: _isCreatingCustomRest ? FontWeight.w900 : FontWeight.w500,
                                ),
                              ),
                              selected: _isCreatingCustomRest,
                              selectedColor: context.colors.primary,
                              backgroundColor: Colors.white.withOpacity(0.04),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _isCreatingCustomRest = true;
                                  });
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _isCreatingCustomRest ? context.colors.primary : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCreatingCustomRest) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _customRestTimerController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter rest in seconds...',
                              hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), fontSize: 13),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.02),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: context.colors.primary),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val) ?? 90;
                              setState(() {
                                _restSeconds = parsed;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16),

                // WEIGHT SELECTOR WITH INTERACTIVE LBS/KG SEGMENTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TARGET WEIGHT',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: ['KG', 'LBS'].map((unit) {
                          final isSelected = _weightUnit == unit;
                          return GestureDetector(
                            onTap: () => setState(() => _weightUnit = unit),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.38),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54)),
                      onPressed: () {
                        if (_weight > 2.5) setState(() => _weight -= 2.5);
                      },
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: context.colors.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.12),
                          thumbColor: Colors.white,
                          overlayColor: context.colors.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _weight,
                          min: 0,
                          max: 200,
                          divisions: 80,
                          onChanged: (val) => setState(() => _weight = val),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: context.colors.primary),
                      onPressed: () {
                        if (_weight < 200) setState(() => _weight += 2.5);
                      },
                    ),
                    Container(
                      width: 55,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _weight.toStringAsFixed(1),
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 16),

                // NOTES SELECTOR
                Text(
                  'OPTIONAL NOTES',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add tactical instruction or motivation...',
                    hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), fontSize: 13),
                    contentPadding: EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.02),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.colors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // SUBMIT CTAS
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showWorkoutPicker = true),
                        child: Container(
                          height: 48,
                          decoration: AppDecorations.outlineButton(context, borderRadius: 14),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'ADD TO EXISTING',
                                  maxLines: 1,
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleCreateNewWorkout,
                        child: Container(
                          height: 48,
                          decoration: AppDecorations.primaryButton(context, borderRadius: 14),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'CREATE NEW ROUTINE',
                                  maxLines: 1,
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
