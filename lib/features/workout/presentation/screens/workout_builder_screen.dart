// lib/features/workout/presentation/screens/workout_builder_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../exercise_library/domain/models/exercise_model.dart';
import '../../../exercise_library/presentation/providers/exercise_providers.dart';
import '../../../music/presentation/controllers/playlists_controller.dart';
import '../../../music/domain/models/workout_playlist.dart';
import '../controllers/workout_controller.dart';
import '../../domain/models/workout_model.dart';
import '../widgets/workout_exercise_card.dart';

class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final String? editWorkoutId;

  const WorkoutBuilderScreen({
    super.key,
    this.editWorkoutId,
  });

  @override
  ConsumerState<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _ScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _WorkoutBuilderScreenState extends ConsumerState<WorkoutBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _splits = ['Upper', 'Lower', 'Push', 'Pull', 'Legs', 'Full Body'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editWorkoutId != null) {
        final workoutsAsync = ref.read(workoutListProvider);
        workoutsAsync.whenData((workouts) {
          final target = workouts.firstWhere((w) => w.id == widget.editWorkoutId);
          ref.read(workoutBuilderProvider.notifier).initFromWorkout(target);
          _nameController.text = target.name;
        });
      } else {
        // Initialize builder with template defaults if empty
        final builderState = ref.read(workoutBuilderProvider);
        if (builderState.exercises.isEmpty) {
          _nameController.text = 'New Workout';
          ref.read(workoutBuilderProvider.notifier).updateName('New Workout');
          ref.read(workoutBuilderProvider.notifier).updateSplit('Push');
        } else {
          _nameController.text = builderState.name;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveWorkout() async {
    final builderState = ref.read(workoutBuilderProvider);
    if (builderState.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.error,
          content: Text('Please add at least 1 exercise to save your routine!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    final String finalId = widget.editWorkoutId ?? generateUniqueId();
    final String userId = 'default_user'; // Linked to authentication if loaded

    final finalWorkout = Workout(
      id: finalId,
      userId: userId,
      name: builderState.name.trim().isEmpty ? 'My Custom Routine' : builderState.name,
      split: builderState.split,
      createdAt: DateTime.now(),
      exercises: builderState.exercises,
      playlistUri: builderState.playlistUri,
      playlistName: builderState.playlistName,
    );

    // Save/update routine in repository
    await ref.read(workoutListProvider.notifier).addOrUpdateWorkout(finalWorkout);
    
    // Reset builder state
    ref.read(workoutBuilderProvider.notifier).reset();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.customColors.success,
          content: Text('Saved routine ${finalWorkout.name} successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      context.pop();
    }
  }

  // Sliding sheet to search and pick extra exercises from full library
  void _showAddExercisesSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddExercisesPickerModal(
          onAddExercise: (exercise) {
            // Generate standard sets template for this added exercise
            final newExercise = WorkoutExercise(
              exerciseId: exercise.id,
              name: exercise.name,
              category: exercise.category,
              image: exercise.image,
              gifUrl: exercise.gifUrl,
              restSeconds: 90,
              sets: List.generate(4, (index) {
                return WorkoutSet(
                  id: generateUniqueId(),
                  setNumber: index + 1,
                  reps: 10,
                  weight: 60.0,
                );
              }),
            );
            ref.read(workoutBuilderProvider.notifier).addExercise(newExercise);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(workoutBuilderProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: _ScrollBehavior(),
        child: Stack(
          children: [
            // 1. Ambient Dynamic Reflect Layer (Blurred low-fidelity GIF/Image background)
            () {
              final firstExercise = builderState.exercises.firstOrNull;
              String? gifPath;
              String? imgPath;
              if (firstExercise != null) {
                final img = firstExercise.image;
                final gif = firstExercise.gifUrl;
                imgPath = img.startsWith('assets/') ? img : 'assets/exercises/$img';
                if (gif.isNotEmpty) {
                  gifPath = gif.startsWith('assets/') ? gif : 'assets/exercises/$gif';
                }
              }

              return Stack(
                children: [
                  if (gifPath != null || imgPath != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.15,
                        child: gifPath != null
                            ? Image.asset(
                                gifPath,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                errorBuilder: (context, error, stackTrace) => imgPath != null
                                    ? Image.asset(
                                        imgPath,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.low,
                                        errorBuilder: (c, e, s) => Container(color: Colors.black),
                                      )
                                    : Container(color: Colors.black),
                              )
                            : imgPath != null
                                ? Image.asset(
                                    imgPath,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.low,
                                    errorBuilder: (c, e, s) => Container(color: Colors.black),
                                  )
                                : Container(color: Colors.black),
                      ),
                    ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.45) : context.colors.onSurface.withValues(alpha: 0.65),
                              context.colors.surface.withOpacity(0.92),
                              context.colors.surface,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }(),

            SafeArea(
              child: CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  // Premium App Bar header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref.read(workoutBuilderProvider.notifier).reset();
                              context.pop();
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.glassmorphism.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.glassmorphism.borderColor),
                              ),
                              child: Icon(Icons.close_rounded, color: context.colors.onSurface, size: 20),
                            ),
                          ),
                          Text(
                            widget.editWorkoutId != null ? 'EDIT ROUTINE' : 'CREATE ROUTINE',
                            style: TextStyle(color: context.colors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          GestureDetector(
                            onTap: _handleSaveWorkout,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.colors.primary.withOpacity(0.4)),
                              ),
                              child: Text(
                                'SAVE',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // WORKOUT NAME INPUT FIELD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORKOUT ROUTINE NAME',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: AppDecorations.glassInput(context),
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(color: context.colors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter routine name (e.g. Push Day)...',
                                hintStyle: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.24), fontSize: 15),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: InputBorder.none,
                                suffixIcon: Icon(Icons.edit_rounded, color: context.colors.onSurface.withValues(alpha: 0.3), size: 18),
                              ),
                              onChanged: (val) {
                                ref.read(workoutBuilderProvider.notifier).updateName(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SPLIT SELECTION CHIPS
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              'CHOOSE WORKOUT SPLIT',
                              style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _splits.length,
                              itemBuilder: (context, index) {
                                final split = _splits[index];
                                final isSelected = builderState.split == split;
                                return Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () => ref.read(workoutBuilderProvider.notifier).updateSplit(split),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? context.colors.primary : context.glassmorphism.cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? context.colors.primary : context.glassmorphism.borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          split.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? context.colors.onSurface : context.colors.onSurface.withOpacity(0.60),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PLAYLIST LINKING
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LINK TACTICAL PLAYLIST',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              // Instead of showing the full sheet, we could show a selection sheet.
                              // But for now, we'll just show the MusicCommandCenterSheet and let it handle selection.
                              // Wait, MusicCommandCenterSheet plays the playlist. We want to ASSIGN it here.
                              // We can open a dialog or simply use a predefined list. Let's create a small local modal for assignment.
                              _showPlaylistSelectorModal();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: AppDecorations.glassInput(context),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_library_music_rounded, 
                                    color: builderState.playlistName != null ? context.colors.primary : context.customColors.grey900.withOpacity(0.3),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      builderState.playlistName ?? 'Tap to assign a Spotify playlist...',
                                      style: TextStyle(
                                        color: builderState.playlistName != null 
                                          ? (context.colors.onSurface)
                                          : (Theme.of(context).brightness == Brightness.dark ? context.colors.onSurface.withValues(alpha: 0.54) : context.customColors.grey900.withOpacity(0.5)),
                                        fontSize: 15,
                                        fontWeight: builderState.playlistName != null ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (builderState.playlistName != null)
                                    GestureDetector(
                                      onTap: () => ref.read(workoutBuilderProvider.notifier).clearPlaylist(),
                                      child: Icon(Icons.close, size: 18, color: context.colors.onSurface.withValues(alpha: 0.54)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // REORDERABLE EXERCISES LIST
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXERCISES ADDED (${builderState.exercises.length})',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Drag to Reorder',
                            style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.24),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (builderState.exercises.isEmpty) ...[
                    // Empty Routine Placeholder
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: GlassCard(
                          borderRadius: 20,
                          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.playlist_add_rounded, color: context.colors.onSurface.withValues(alpha: 0.24), size: 48),
                              SizedBox(height: 14),
                              Text(
                                'Your custom routine is empty.',
                                style: TextStyle(color: context.colors.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Tap add exercises to construct your tactical split.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38), fontSize: 12),
                              ),
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: _showAddExercisesSelector,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: AppDecorations.outlineButton(context, borderRadius: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, color: context.colors.onSurface.withValues(alpha: 0.70), size: 16),
                                      SizedBox(width: 6),
                                      Text('ADD EXERCISE', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverReorderableList(
                        itemBuilder: (context, index) {
                          final exercise = builderState.exercises[index];
                          return ReorderableDelayedDragStartListener(
                            index: index,
                            key: ValueKey(exercise.exerciseId),
                            child: WorkoutExerciseCard(
                              exercise: exercise,
                              index: index,
                              onDelete: () {
                                ref.read(workoutBuilderProvider.notifier).removeExercise(exercise.exerciseId);
                              },
                              onEdit: () {
                                // Inline target edits (e.g. change Sets Count)
                                _showEditSetDetailsSheet(exercise);
                              },
                            ),
                          );
                        },
                        itemCount: builderState.exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          ref.read(workoutBuilderProvider.notifier).reorderExercises(oldIndex, newIndex);
                        },
                      ),
                    ),
                  ],

                  // ADD MORE EXERCISES FAB LINK
                  if (builderState.exercises.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: GestureDetector(
                          onTap: _showAddExercisesSelector,
                          child: DottedBorderContainer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: context.colors.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'ADD MORE EXERCISES',
                                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),

            // FLOATING SAVE BUTTON AT BOTTOM
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: _handleSaveWorkout,
                child: Container(
                  height: 52,
                  decoration: AppDecorations.primaryButton(context, borderRadius: 16),
                  child: Center(
                    child: Text(
                      'SAVE WORKOUT ROUTINE',
                      style: TextStyle(color: context.colors.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small inline modal sheet to modify target Sets/Reps/Rest inside the Builder screen
  void _showEditSetDetailsSheet(WorkoutExercise exercise) {
    int localSets = exercise.sets.length;
    int localReps = exercise.sets.firstOrNull?.reps ?? 10;
    double localWeight = exercise.sets.firstOrNull?.weight ?? 60.0;
    int localRest = exercise.restSeconds;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDIT TARGETS: ${exercise.name.toUpperCase()}',
                      style: TextStyle(color: context.colors.onSurface, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Divider(color: context.colors.onSurface.withOpacity(0.12), height: 24),
                    
                    // Sets Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Sets', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70))),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: context.colors.onSurface),
                              onPressed: () {
                                if (localSets > 1) setModalState(() => localSets--);
                              },
                            ),
                            Text('$localSets', style: TextStyle(color: context.colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add, color: context.colors.primary),
                              onPressed: () => setModalState(() => localSets++),
                            ),
                          ],
                        )
                      ],
                    ),

                    // Reps Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Reps', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70))),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: context.colors.onSurface),
                              onPressed: () {
                                if (localReps > 1) setModalState(() => localReps--);
                              },
                            ),
                            Text('$localReps', style: TextStyle(color: context.colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add, color: context.colors.primary),
                              onPressed: () => setModalState(() => localReps++),
                            ),
                          ],
                        )
                      ],
                    ),

                    // Weight Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Weight (KG)', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70))),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: context.colors.onSurface),
                              onPressed: () {
                                if (localWeight > 2.5) setModalState(() => localWeight -= 2.5);
                              },
                            ),
                            Text(localWeight.toStringAsFixed(1), style: TextStyle(color: context.colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add, color: context.colors.primary),
                              onPressed: () => setModalState(() => localWeight += 2.5),
                            ),
                          ],
                        )
                      ],
                    ),

                    // Rest Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rest Timer (Seconds)', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.70))),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: context.colors.onSurface),
                              onPressed: () {
                                if (localRest > 15) setModalState(() => localRest -= 15);
                              },
                            ),
                            Text('${localRest}s', style: TextStyle(color: context.colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add, color: context.colors.primary),
                              onPressed: () => setModalState(() => localRest += 15),
                            ),
                          ],
                        )
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        // Generate updated sets list
                        final updatedSets = List.generate(localSets, (idx) {
                          return WorkoutSet(
                            id: generateUniqueId(),
                            setNumber: idx + 1,
                            reps: localReps,
                            weight: localWeight,
                          );
                        });
                        ref.read(workoutBuilderProvider.notifier).updateExerciseSets(exercise.exerciseId, updatedSets);
                        
                        // Also update rest timer in routine
                        ref.read(workoutBuilderProvider.notifier).updateExerciseRest(exercise.exerciseId, localRest);

                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 48,
                        decoration: AppDecorations.primaryButton(context, borderRadius: 14),
                        child: Center(
                          child: Text('CONFIRM CHANGES', style: TextStyle(color: context.colors.onPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlaylistSelectorModal() {
    // Ensure playlists are loaded
    ref.read(playlistsControllerProvider.notifier).fetchPlaylists();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final playlistState = ref.watch(playlistsControllerProvider);
            final allPlaylists = playlistState.categorizedCuratedMixes.values.expand((e) => e).toList();
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: context.glassmorphism.borderColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: context.colors.onSurface.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SELECT TACTICAL PLAYLIST',
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (playlistState.isLoading && allPlaylists.isEmpty)
                      Center(child: CircularProgressIndicator(color: context.colors.primary))
                    else if (allPlaylists.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('No playlists available.', style: TextStyle(color: context.colors.onSurface.withOpacity(0.70))),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: allPlaylists.length,
                          separatorBuilder: (_, __) => Divider(color: context.colors.onSurface.withOpacity(0.12)),
                          itemBuilder: (context, index) {
                            final pl = allPlaylists[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: pl.imageUrl.isNotEmpty
                                    ? Image.network(pl.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                                    : Container(width: 40, height: 40, color: context.colors.onSurface.withOpacity(0.1), child: Icon(Icons.music_note, color: context.colors.onSurface)),
                              ),
                              title: Text(
                                pl.name, 
                                style: TextStyle(color: context.colors.onSurface, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                pl.category,
                                style: TextStyle(color: context.colors.primary, fontSize: 11),
                              ),
                              onTap: () {
                                ref.read(workoutBuilderProvider.notifier).updatePlaylist(pl.uri, pl.name);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Inline modal to search exercises within the routine builder
class _AddExercisesPickerModal extends ConsumerStatefulWidget {
  final Function(Exercise) onAddExercise;

  const _AddExercisesPickerModal({required this.onAddExercise});

  @override
  ConsumerState<_AddExercisesPickerModal> createState() => _AddExercisesPickerModalState();
}

class _AddExercisesPickerModalState extends ConsumerState<_AddExercisesPickerModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);
    final filteredExercises = ref.watch(filteredExercisesProvider);

    final categories = ['All', 'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.glassmorphism.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Drag indicator
          SizedBox(height: 10),
          Center(
            child: Container(
              width: 48,
              height: 4.5,
              decoration: BoxDecoration(
                color: context.colors.onSurface.withOpacity(0.24),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Header title
          Text(
            'SELECT EXERCISE',
            style: TextStyle(color: context.colors.onSurface, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: AppDecorations.glassInput(context),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: context.colors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search exercise library...',
                  hintStyle: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.24), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.colors.onSurface.withValues(alpha: 0.38)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) => ref.read(searchQueryProvider.notifier).setQuery(val),
              ),
            ),
          ),
          SizedBox(height: 12),

          // Horizontal Categories
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? context.colors.onPrimary : context.colors.onSurface.withOpacity(0.38),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: context.colors.primary,
                    backgroundColor: context.glassmorphism.cardColor,
                    onSelected: (val) {
                      if (val) ref.read(selectedCategoryProvider.notifier).setCategory(category);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? context.colors.primary : context.glassmorphism.borderColor,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),

          // Dynamic List items
          Expanded(
            child: filteredExercises.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.colors.primary)),
              error: (err, st) => Center(child: Text('Failed to load: $err', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38)))),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Text('No matching exercises found', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38), fontSize: 13)),
                  );
                }
                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        borderRadius: 16,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.colors.onSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(ex.localImagePath, fit: BoxFit.contain),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: context.colors.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '${ex.muscleGroup} • ${ex.equipment}',
                                    style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.38), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_rounded, color: context.colors.primary, size: 24),
                              onPressed: () {
                                widget.onAddExercise(ex);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: Duration(milliseconds: 600),
                                    backgroundColor: context.customColors.success,
                                    content: Text('Added ${ex.name} to template!', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// Simple helper widget to draw dotted-border look like the design mockup
class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: context.glassmorphism.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.glassmorphism.borderColor,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
