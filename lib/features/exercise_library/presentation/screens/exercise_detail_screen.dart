// lib/features/exercise_library/presentation/screens/exercise_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/exercise_model.dart';
import '../providers/exercise_providers.dart';
import '../../../workout/presentation/widgets/add_to_workout_bottom_sheet.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(favoritesProvider).contains(widget.exercise.id);
    final steps = widget.exercise.englishInstructionSteps.isNotEmpty
        ? widget.exercise.englishInstructionSteps
        : widget.exercise.englishInstruction
              .split('.')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ScrollConfiguration(
        behavior: _ScrollBehavior(),
        child: Stack(
          children: [
            // 1. Ambient Dynamic Reflect Layer (Blurred low-fidelity GIF background)
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  widget.exercise.localGifPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    widget.exercise.localImagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (c, e, s) => Container(color: Colors.black),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        context.colors.surface.withOpacity(0.9),
                        context.colors.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Details layout
            SafeArea(
              child: CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  // App Bar Sliver
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Arrow Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.glassmorphism.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.glassmorphism.borderColor,
                                ),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                size: 18,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Add to Workout Button
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        AddToWorkoutBottomSheet(
                                          exercise: widget.exercise,
                                        ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: AppDecorations.primaryButton(context, 
                                    borderRadius: 14,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'ADD TO WORKOUT',
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Exercise title & Main tags
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exercise.name.toUpperCase(),
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Horizontally scrolling text metadata container to prevent pixel overflows on long strings
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      Text(
                                        widget.exercise.muscleGroup
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: context.colors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      Text(
                                        '  •  ',
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38)),
                                      ),
                                      Text(
                                        widget.exercise.equipment.toUpperCase(),
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.60),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.colors.primary.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  widget.exercise.difficulty.toUpperCase(),
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upscaled centered visual card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            widget.exercise.localGifPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  widget.exercise.localImagePath,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (c, e, s) => Container(
                                    color: context.colors.surface,
                                    child: Center(
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: context.customColors.grey500,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Horizontal scrolling pill metrics (Balanced spacing: 12 vertical padding)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildPillMetric(
                              'Equipment',
                              widget.exercise.equipment,
                              Icons.fitness_center_rounded,
                            ),
                            SizedBox(width: 10),
                            _buildPillMetric(
                              'Target Zone',
                              widget.exercise.target,
                              Icons.track_changes_rounded,
                            ),
                            SizedBox(width: 10),
                            _buildPillMetric(
                              'Body Part',
                              widget.exercise.bodyPart,
                              Icons.accessibility_new_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // HOW TO PERFORM Section (Balanced uniform spacing: 12 vertical padding)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOW TO PERFORM',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: steps.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Circular step index badge
                                    Container(
                                      width: 26,
                                      height: 26,
                                      margin: EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            context.colors.primary,
                                            context.colors.primary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    // Step description
                                    Expanded(
                                      child: Text(
                                        steps[index],
                                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.85),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom padding for scroll clearance
                  SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautifully formatted capsule pill card for horizontal list view with matching border radius
  Widget _buildPillMetric(String label, String value, IconData icon) {
    return GlassCard(
      borderRadius:
          14, // Set to 14 to match the standard layout system matching visual card corners
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary, size: 14),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 1),
              Text(
                value.toUpperCase(),
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
