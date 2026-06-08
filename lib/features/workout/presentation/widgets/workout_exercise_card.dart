// lib/features/workout/presentation/widgets/workout_exercise_card.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/workout_model.dart';

class WorkoutExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isReorderable;

  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    this.onDelete,
    this.onEdit,
    this.isReorderable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 16, // Refined rounded corners
        padding: EdgeInsets.all(12),
        backgroundColor: Color(0xFF111111), // Surface #111111
        borderColor: Colors.white.withOpacity(0.04), // Restrained Border Opacity 0.04
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Restrained Image Container with Circular Elegant Index
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Color(0xFF171717), // elevated dark surface #171717
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92), // soft premium white backing for drawing lines visibility
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/exercises/${exercise.image}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.black54,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // Elegant Restrained Circular Index Badge (Hevy/Strong Style)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E), // Premium dark theme background
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.0),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Color(0xFFF5F5F5), // Primary Text
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),

            // Right Column: Title, Split Category, Metadata & Micro Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and drag reorder handle row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF5F5F5), // Primary Text #F5F5F5
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (isReorderable)
                        Padding(
                          padding: EdgeInsets.only(left: 8.0, top: 1.0),
                          child: Icon(Icons.reorder_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2),

                  // Category Label (uppercase muted grey)
                  Text(
                    exercise.category.toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFF8A8A8A), // Secondary Text #8A8A8A
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Highly Refined Single-Chip Metadata Row
                  Row(
                    children: [
                      // Highlight Primary Targets (e.g. 4 x 12)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF5252).withOpacity(0.08), // Muted accent wash
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(0xFFFF5252).withOpacity(0.18),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${exercise.sets.length} x ${exercise.sets.firstOrNull?.reps ?? 12}',
                          style: TextStyle(
                            color: Color(0xFFFF5252), // Premium soft accent crimson
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Secondary metadata elements inline (Rest and Weight details)
                      Expanded(
                        child: Text(
                          '${exercise.restSeconds}s Rest${exercise.sets.isNotEmpty && exercise.sets.first.weight > 0 ? '  •  ${exercise.sets.first.weight.toStringAsFixed(1)} KG' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF8A8A8A), // Secondary Text #8A8A8A
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Conditionally render actions row if callbacks exist
                  if (onEdit != null || onDelete != null) ...[
                    SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.10), height: 1),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (onEdit != null)
                          _MicroTactilePressable(
                            onTap: onEdit!,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.4),
                                  size: 11,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Edit Targets',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.45),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (onEdit != null && onDelete != null)
                          SizedBox(width: 20),
                        if (onDelete != null)
                          _MicroTactilePressable(
                            onTap: onDelete!,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent.withOpacity(0.65),
                                  size: 11,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.redAccent.withOpacity(0.7),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Micro tactile scale animation helper for actions inside exercise card
class _MicroTactilePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _MicroTactilePressable({
    required this.child,
    required this.onTap,
  });

  @override
  State<_MicroTactilePressable> createState() => _MicroTactilePressableState();
}

class _MicroTactilePressableState extends State<_MicroTactilePressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
