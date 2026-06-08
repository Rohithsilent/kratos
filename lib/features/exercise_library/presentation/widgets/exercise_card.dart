// lib/features/exercise_library/presentation/widgets/exercise_card.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/exercise_model.dart';
import '../providers/exercise_providers.dart';
import '../screens/exercise_detail_screen.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseCard({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(exercise.id);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            );
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Exercise preview image
                Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    child: Image.asset(
                      exercise.localImagePath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.colors.surface,
                        child: Center(
                          child: Icon(
                            Icons.fitness_center,
                            color: context.customColors.grey600,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Center-Right: Exercise metadata and tags
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Muscle Category
                            Text(
                              exercise.category.toUpperCase(),
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            // Exercise Name
                            Text(
                              exercise.name,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            // Equipment Needed
                            Text(
                              exercise.equipment.toUpperCase(),
                              style: TextStyle(
                                color: context.customColors.grey400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Difficulty Level Capsule Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colors.primary.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            exercise.difficulty.toUpperCase(),
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Column: Favorites Toggle and Navigation Chevron
                Padding(
                  padding: EdgeInsets.only(right: 12, top: 12, bottom: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Star Icon Toggle
                      GestureDetector(
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(exercise.id);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.amber : context.customColors.grey500,
                            size: 20,
                          ),
                        ),
                      ),
                      // Chevron right icon
                      Icon(
                        Icons.chevron_right,
                        color: context.customColors.grey600,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
