// lib/features/workout/presentation/widgets/set_tracker_widget.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/workout_model.dart';

class SetTrackerWidget extends StatelessWidget {
  final List<WorkoutSet> sets;
  final Function(int setIndex) onToggleComplete;
  final Function(int setIndex, double weight) onWeightChanged;
  final Function(int setIndex, int reps) onRepsChanged;

  const SetTrackerWidget({
    super.key,
    required this.sets,
    required this.onToggleComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  'SET',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'WEIGHT (KG)',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'REPS',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
              SizedBox(width: 6),
              SizedBox(
                width: 48,
                child: Text(
                  'STATUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.38), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withOpacity(0.10), height: 1, thickness: 1),
        SizedBox(height: 6),

        // Set Rows List
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final setItem = sets[index];
            final isCompleted = setItem.isCompleted;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted ? context.colors.primary.withOpacity(0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Set Number Column
                  SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        '${setItem.setNumber}',
                        style: TextStyle(
                          color: isCompleted ? context.colors.primary : Colors.white.withOpacity(0.70),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  // Weight Input Box
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.transparent : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? context.colors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: isCompleted ? null : () => onWeightChanged(index, setItem.weight - 2.5),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Icon(Icons.remove, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), size: 14),
                            ),
                          ),
                          Text(
                            setItem.weight.toStringAsFixed(1),
                            style: TextStyle(
                              color: isCompleted ? Colors.white.withOpacity(0.70) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: isCompleted ? null : () => onWeightChanged(index, setItem.weight + 2.5),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Icon(Icons.add, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 6),

                  // Reps Input Box
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.transparent : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? context.colors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: isCompleted ? null : () {
                              if (setItem.reps > 1) onRepsChanged(index, setItem.reps - 1);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Icon(Icons.remove, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), size: 14),
                            ),
                          ),
                          Text(
                            '${setItem.reps}',
                            style: TextStyle(
                              color: isCompleted ? Colors.white.withOpacity(0.70) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: isCompleted ? null : () => onRepsChanged(index, setItem.reps + 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                              child: Icon(Icons.add, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.24), size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 6),

                  // Status Completed Checkmark Column
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => onToggleComplete(index),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 220),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted ? context.colors.primary : Colors.white.withOpacity(0.02),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted ? context.colors.primary : Colors.white.withOpacity(0.12),
                              width: 1.5,
                            ),
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: context.colors.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: isCompleted ? Colors.white : Colors.transparent,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
