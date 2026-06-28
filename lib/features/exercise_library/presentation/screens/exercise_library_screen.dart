// lib/features/exercise_library/presentation/screens/exercise_library_screen.dart

import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/exercise_providers.dart';
import '../widgets/exercise_card.dart';

class ExerciseCategory {
  final String name;
  final IconData icon;
  ExerciseCategory(this.name, this.icon);
}

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  bool _showFilters = false;
  bool _showSearch = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static List<ExerciseCategory> uiCategories = [
    ExerciseCategory('All', Icons.grid_view_rounded),
    ExerciseCategory('Chest', Icons.accessibility_new_rounded),
    ExerciseCategory('Back', Icons.sports_martial_arts_rounded),
    ExerciseCategory('Legs', Icons.directions_run_rounded),
    ExerciseCategory('Shoulders', Icons.sports_gymnastics_rounded),
    ExerciseCategory('Arms', Icons.fitness_center_rounded),
    ExerciseCategory('Core', Icons.shield_rounded),
    ExerciseCategory('Cardio', Icons.monitor_heart_rounded),
    ExerciseCategory('Neck', Icons.accessibility_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredExercisesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Premium App Bar / Header Section
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXERCISES',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Search/Explore badge icon
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _showFilters = false;
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).setQuery('');
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _showSearch
                              ? context.colors.primary.withOpacity(0.2)
                              : (isDark ? context.glassmorphism.cardColor : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _showSearch ? context.colors.primary : context.glassmorphism.borderColor,
                          ),
                        ),
                        child: Icon(
                          _showSearch ? Icons.close_rounded : Icons.search_rounded,
                          color: _showSearch ? context.colors.primary : (isDark ? Colors.white : Colors.black),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showSearch) SizedBox(height: 12),

              // 2. High-Fidelity Inline Search Field (collapsible)
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                secondChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? context.glassmorphism.cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.glassmorphism.borderColor),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).setQuery(val);
                          },
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, fontSize: 15),
                          cursorColor: context.colors.primary,
                          decoration: InputDecoration(
                            hintText: 'Search exercises...',
                            hintStyle: TextStyle(color: isDark ? Colors.white : context.customColors.grey900.withOpacity(0.4), fontSize: 15),
                            prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7)),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  color: _showFilters ? context.colors.primary : (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showFilters = !_showFilters;
                                  });
                                },
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
                crossFadeState: _showSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 250),
                sizeCurve: Curves.easeInOutCubic,
              ),

              // 3. Animated Category circular scroll selector
              AnimatedCrossFade(
                firstChild: SizedBox.shrink(),
                secondChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 86,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: uiCategories.length,
                        itemBuilder: (context, index) {
                          final cat = uiCategories[index];
                          final isSelected = selectedCategory == cat.name;

                          return Padding(
                            padding: EdgeInsets.only(right: 18.0),
                            child: GestureDetector(
                              onTap: () {
                                ref.read(selectedCategoryProvider.notifier).setCategory(cat.name);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark ? context.glassmorphism.cardColor : Colors.white),
                                      border: Border.all(
                                        color: isSelected ? context.colors.primary : context.glassmorphism.borderColor,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: context.glow.redGlow.withOpacity(0.2),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        cat.icon,
                                        color: isSelected
                                            ? context.colors.primary
                                            : (Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.70)
                                                : Colors.black.withOpacity(0.70)),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? context.colors.primary
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.54)
                                              : Colors.black.withOpacity(0.70)),
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
                crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: Duration(milliseconds: 250),
                sizeCurve: Curves.easeInOutCubic,
              ),

              // 4. Section Label: "ALL EXERCISES - X Exercises"
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedCategory.toUpperCase()} EXERCISES',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    filteredAsync.when(
                      data: (list) => Text(
                        '${list.length} Exercises',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                      ),
                      error: (_, _) => Text('Error', style: TextStyle(color: context.colors.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4),

              // 5. Scrollable Exercises List
              Expanded(
                child: filteredAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                            SizedBox(height: 16),
                            Text(
                              'No exercises found',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try checking spelling or changing filters',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.4), fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return ExerciseCard(exercise: exercises[index]);
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: context.colors.primary),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: context.colors.error),
                          SizedBox(height: 16),
                          Text(
                            'Error Loading Exercises',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
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
}
