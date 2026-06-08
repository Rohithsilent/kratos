// lib/features/workout/presentation/screens/my_workouts_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/workout_model.dart';
import '../controllers/workout_controller.dart';
import '../widgets/workout_exercise_card.dart';

class MyWorkoutsScreen extends ConsumerStatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  ConsumerState<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class WorkoutCategory {
  final String name;
  final String filterValue;
  final IconData icon;
  WorkoutCategory(this.name, this.filterValue, this.icon);
}

class _MyWorkoutsScreenState extends ConsumerState<MyWorkoutsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _filterSplit = 'ALL';
  bool _isFABVisible = true;
  bool _showSearch = false;
  bool _showFilters = false;
  late final TextEditingController _searchController;

  static List<WorkoutCategory> uiCategories = [
    WorkoutCategory('All', 'ALL', Icons.grid_view_rounded),
    WorkoutCategory('Push', 'PUSH', Icons.fitness_center_rounded),
    WorkoutCategory('Pull', 'PULL', Icons.accessibility_new_rounded),
    WorkoutCategory('Legs', 'LEGS', Icons.directions_run_rounded),
    WorkoutCategory('Full Body', 'FULL BODY', Icons.accessibility_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFABVisible) {
        setState(() {
          _isFABVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFABVisible) {
        setState(() {
          _isFABVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutListProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
            // Main Scrollable Area
            SafeArea(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.darkSurface,
                onRefresh: () async {
                  ref.invalidate(workoutListProvider);
                  ref.invalidate(workoutHistoryProvider);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Hero Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 8,
                        ),
                        child: _buildHeroHeader(),
                      ),
                    ),

                    // Collapsible Search Bar
                    SliverToBoxAdapter(
                      child: AnimatedCrossFade(
                        firstChild: SizedBox.shrink(),
                        secondChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showSearch) SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildSearchBar(),
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                        crossFadeState: _showSearch
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 250),
                        sizeCurve: Curves.easeInOutCubic,
                      ),
                    ),

                    // Animated Category circular scroll selector
                    SliverToBoxAdapter(
                      child: AnimatedCrossFade(
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
                                  final isSelected = _filterSplit == cat.filterValue;

                                  return Padding(
                                    padding: EdgeInsets.only(right: 18.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _filterSplit = cat.filterValue;
                                        });
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
                                              color: isSelected ? Colors.transparent : AppColors.glassDark,
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : AppColors.glassBorderDark,
                                                width: isSelected ? 2.0 : 1.0,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.primary.withOpacity(0.2),
                                                        blurRadius: 10,
                                                        spreadRadius: 2,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                cat.icon,
                                                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.70),
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            cat.name,
                                            style: TextStyle(
                                              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.54),
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
                        crossFadeState: _showFilters && _showSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: Duration(milliseconds: 250),
                        sizeCurve: Curves.easeInOutCubic,
                      ),
                    ),

                    // Dynamic Stats Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: _buildStatsGrid(workoutsAsync, historyAsync),
                      ),
                    ),

                    // Continue Workout Section
                    SliverToBoxAdapter(
                      child: workoutsAsync.when(
                        data: (workouts) =>
                            _buildContinueWorkoutSection(workouts),
                        loading: () => SizedBox.shrink(),
                        error: (_, _) => SizedBox.shrink(),
                      ),
                    ),

                    // My Custom Workouts Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MY ROUTINES',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.2,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/workout/create'),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'NEW ROUTINE',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // My Workouts List Content
                    workoutsAsync.when(
                      loading: () => SliverToBoxAdapter(
                        child: _ShimmerWorkoutsLoader(),
                      ),
                      error: (err, _) => SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Failed to sync routines: $err',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      data: (workouts) {
                        // Apply client search and split filter
                        final filteredList = workouts.where((w) {
                          final matchesSearch =
                              w.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              w.split.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              w.exercises.any(
                                (e) => e.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                              );

                          final matchesSplit =
                              _filterSplit == 'ALL' ||
                              w.split.toUpperCase() ==
                                  _filterSplit.toUpperCase();

                          return matchesSearch && matchesSplit;
                        }).toList();

                        if (filteredList.isEmpty) {
                          return SliverToBoxAdapter(
                            child: _buildEmptyState(workouts.isEmpty),
                          );
                        }

                        return SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final workout = filteredList[index];
                              return _buildWorkoutRoutineCard(workout, index);
                            }, childCount: filteredList.length),
                          ),
                        );
                      },
                    ),

                    // Main Templates Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DISCOVER ROUTINES',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.2,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'TEMPLATES',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Category 1: Hypertrophy Sub-Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'HYPERTROPHY SPLITS',
                          style: TextStyle(
                            color: Color(0xFF8A8A8A), // Subtle grey for sub-header
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Category 1: Carousel
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildTemplateCard(
                              name: 'Hypertrophy Push',
                              split: 'PUSH DAY',
                              difficulty: 'Popular',
                              duration: '60 min',
                              imagePath: 'assets/exercises/images/0025-EIeI8Vf.jpg',
                              tagColor: AppColors.primary,
                            ),
                            SizedBox(width: 14),
                            _buildTemplateCard(
                              name: 'Hypertrophy Pull',
                              split: 'PULL DAY',
                              difficulty: 'Intermediate',
                              duration: '50 min',
                              imagePath: 'assets/exercises/images/0017-kiJ4Z2K.jpg',
                              tagColor: Colors.blueAccent,
                            ),
                            SizedBox(width: 14),
                            _buildTemplateCard(
                              name: 'Leg Day Destroyer',
                              split: 'LEG DAY',
                              difficulty: 'Advanced',
                              duration: '75 min',
                              imagePath: 'assets/exercises/images/0024-Y7YcmIJ.jpg',
                              tagColor: Colors.greenAccent.shade700,
                            ),
                            SizedBox(width: 20),
                          ],
                        ),
                      ),
                    ),

                    // Category 2: Strength & Core Sub-Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'STRENGTH & CORE',
                          style: TextStyle(
                            color: Color(0xFF8A8A8A), // Subtle grey for sub-header
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Category 2: Carousel
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildTemplateCard(
                              name: 'Full Body Power',
                              split: 'FULL BODY',
                              difficulty: 'Advanced',
                              duration: '90 min',
                              imagePath: 'assets/exercises/images/0032-ila4NZS.jpg',
                              tagColor: Colors.deepPurpleAccent,
                            ),
                            SizedBox(width: 14),
                            _buildTemplateCard(
                              name: 'Core Shredder',
                              split: 'ABS & CORE',
                              difficulty: 'Beginner',
                              duration: '20 min',
                              imagePath: 'assets/exercises/images/0274-TFqbd8t.jpg',
                              tagColor: Colors.orangeAccent,
                            ),
                            SizedBox(width: 20),
                          ],
                        ),
                      ),
                    ),

                    // Bottom spacer for scrolling above bottom bar
                    SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),

            // Premium Floating Action Button (FAB)
            AnimatedPositioned(
              duration: Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              right: 20,
              bottom: _isFABVisible
                  ? 100
                  : -80, // Floats elegantly above bottom bar, hides below screen on scroll down
              child: _buildCreateWorkoutFAB(),
            ),
          ],
        ),
    );
  }

  // ─── 1. HERO HEADER ───
  Widget _buildHeroHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'MY WORKOUTS',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        // Search/Explore badge icon
        GestureDetector(
          onTap: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
                _showFilters = false;
              }
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _showSearch
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.glassDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: _showSearch
                    ? AppColors.primary
                    : AppColors.glassBorderDark,
              ),
            ),
            child: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: _showSearch ? AppColors.primary : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 1B. COLLAPSIBLE SEARCH BAR ───
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorderDark),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900, fontSize: 15),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Search routines, splits, or exercises...',
          hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.5),
          ),
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: _showFilters
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.5),
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
    );
  }

  // ─── 2. WORKOUT STATS OVERVIEW ───
  Widget _buildStatsGrid(
    AsyncValue<List<Workout>> workoutsAsync,
    AsyncValue<List<WorkoutSession>> historyAsync,
  ) {
    final int totalRoutines = workoutsAsync.value?.length ?? 0;
    final history = historyAsync.value ?? [];

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final int thisWeekCount = history
        .where((s) => s.completedAt.isAfter(sevenDaysAgo))
        .length;

    final int totalSeconds = history.fold(
      0,
      (sum, s) => sum + s.totalDurationSeconds,
    );
    final int hours = totalSeconds ~/ 3600;
    final int mins = (totalSeconds % 3600) ~/ 60;
    final String durationString = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    final int totalSessions = history.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTacticalStatCard(
            title: '🔥 WEEKLY STREAK',
            value: '$thisWeekCount DAYS',
            subhead: '+18% consistency',
            glowColor: Color(0xFFFF5252),
            bgGradient: LinearGradient(
              colors: [
                Color(0xFFFF3B3B).withOpacity(0.12),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(width: 12),
          _buildTacticalStatCard(
            title: '⏱ TOTAL DURATION',
            value: durationString,
            subhead: 'This week',
            glowColor: Color(0xFF40C4FF),
            bgGradient: LinearGradient(
              colors: [
                Color(0xFF40C4FF).withOpacity(0.10),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(width: 12),
          _buildTacticalStatCard(
            title: '🏋 TOTAL ROUTINES',
            value: totalRoutines.toString(),
            subhead: 'Active plans',
            glowColor: Color(0xFFE040FB),
            bgGradient: LinearGradient(
              colors: [
                Color(0xFFE040FB).withOpacity(0.10),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(width: 12),
          _buildTacticalStatCard(
            title: '🏆 SESSIONS RECORD',
            value: totalSessions.toString(),
            subhead: 'Completed total',
            glowColor: Color(0xFFFFD700),
            bgGradient: LinearGradient(
              colors: [
                Color(0xFFFFD700).withOpacity(0.10),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalStatCard({
    required String title,
    required String value,
    required String subhead,
    required Color glowColor,
    required Gradient bgGradient,
  }) {
    return Container(
      width: 145,
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color(0xFF131313),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.10),
                    blurRadius: 15,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: bgGradient,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.35),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      subhead.toUpperCase(),
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.25),
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. ACTIVE CONTINUE WORKOUT WIDGET ───
  Widget _buildContinueWorkoutSection(List<Workout> workouts) {
    WorkoutSessionState? activeState;
    Workout? activeWorkout;
    for (final w in workouts) {
      final s = ref.watch(activeSessionProvider(w));
      if (s != null) {
        activeState = s;
        activeWorkout = w;
        break;
      }
    }
    if (activeState == null || activeWorkout == null) {
      return SizedBox.shrink();
    }
    final state = activeState;

    final int completedExercisesCount = state.exercises
        .where((ex) => ex.sets.any((s) => s.isCompleted))
        .length;

    final double progress = state.workout.exercises.isEmpty
        ? 0.0
        : completedExercisesCount / state.workout.exercises.length;

    final duration = Duration(seconds: state.elapsedSeconds);
    final int hours = duration.inHours;
    final int mins = duration.inMinutes % 60;
    final int secs = duration.inSeconds % 60;
    final String timeStr = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.all(16),
        borderColor: AppColors.primary.withOpacity(0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ACTIVE TRAINING SESSION',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    context.push('/workout/session/${state.workout.id}');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                          size: 14,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'RESUME',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                            fontSize: 10,
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
            SizedBox(height: 12),

            Text(
              state.workout.name.toUpperCase(),
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${state.workout.split.toUpperCase()} SPLIT  •  Tactical Fitness Integration',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.35),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 14),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COMPLETION PROGRESS',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.25),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.70),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.04),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActiveMetric(
                  icon: Icons.timer_outlined,
                  label: 'ELAPSED',
                  value: timeStr,
                ),
                _buildActiveMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'EST. KCAL',
                  value: '${(duration.inMinutes * 7.5).toInt()} KCAL',
                ),
                _buildActiveMetric(
                  icon: Icons.fitness_center_rounded,
                  label: 'EXERCISES',
                  value:
                      '$completedExercisesCount/${state.workout.exercises.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38), size: 10),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.25),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─── 4. CUSTOM WORKOUT ROUTINE CARD ───
  Widget _buildWorkoutRoutineCard(Workout workout, int index) {
    final int totalSets = workout.exercises.fold(
      0,
      (sum, e) => sum + e.sets.length,
    );

    String difficulty = 'POPULAR';
    if (index % 3 == 1) difficulty = 'ADVANCED';
    if (index % 3 == 2) difficulty = 'INTERMEDIATE';

    final firstExercise = workout.exercises.firstOrNull;
    String imagePath = '';
    if (firstExercise != null) {
      if (firstExercise.image.startsWith('assets/')) {
        imagePath = firstExercise.image;
      } else {
        imagePath = 'assets/exercises/${firstExercise.image}';
      }
    }

    final muscleChips = workout.exercises
        .map((e) => e.category)
        .toSet()
        .toList();
    final String muscleString = muscleChips.isNotEmpty
        ? muscleChips.join('  •  ').toUpperCase()
        : 'STRENGTH';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/workout/detail/${workout.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Routine preview image using the first exercise's image
                Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: imagePath.isNotEmpty
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.darkSurface,
                                  child: Center(
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: AppColors.grey600,
                                      size: 28,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            color: AppColors.darkSurface,
                            child: Center(
                              child: Icon(
                                Icons.fitness_center,
                                color: AppColors.grey600,
                                size: 28,
                              ),
                            ),
                          ),
                  ),
                ),

                // Center Column: Details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              muscleString,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              workout.name,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${workout.split.toUpperCase()} SPLIT  •  ~${workout.exercises.length * 10} MIN',
                              style: TextStyle(
                                color: AppColors.grey400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildMiniBadge('${workout.exercises.length} EX'),
                              SizedBox(width: 6),
                              _buildMiniBadge('$totalSets SETS'),
                              SizedBox(width: 6),
                              _buildMiniBadge(difficulty),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Column: Options & Start
                Padding(
                  padding: EdgeInsets.only(
                    right: 12,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showWorkoutOptions(workout),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.grey500,
                            size: 20,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(activeSessionProvider(workout).notifier)
                              .startSession();
                          context.push('/workout/session/${workout.id}');
                        },
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                            size: 14,
                          ),
                        ),
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

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.5),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required String name,
    required String split,
    required String difficulty,
    required String duration,
    required String imagePath,
    required Color tagColor,
  }) {
    // Determine the actual image path robustly
    String finalImagePath = imagePath.startsWith('assets/') ? imagePath : 'assets/exercises/$imagePath';

    return GestureDetector(
      onTap: () => _onTemplateTapped(name, split),
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: Color(0xFF111111), // Premium dark surface
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
        ),
        child: Row(
          children: [
            // Left: Exercise Image
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white, // So the transparent/white-bg images blend perfectly
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Image.asset(
                    finalImagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.fitness_center, color: Colors.grey, size: 28),
                  ),
                ),
              ),
            ),
            
            // Right: Content Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header (Split and Tag)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            split.toUpperCase(),
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.add_circle, color: AppColors.primary, size: 16),
                      ],
                    ),
                    
                    // Name
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Footer (Duration & Difficulty)
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Color(0xFF8A8A8A), size: 10),
                        SizedBox(width: 3),
                        Text(
                          duration,
                          style: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tagColor.withOpacity(0.3), width: 0.5),
                          ),
                          child: Text(
                            difficulty.toUpperCase(),
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 6. CREATE WORKOUT FAB ───
  Widget _buildCreateWorkoutFAB() {
    return GestureDetector(
      onTap: () => context.push('/workout/create'),
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.add_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900, size: 24),
        ),
      ),
    );
  }

  // ─── ACTION MENUS & BOTTOM SHEET TRIGGERS ───
  void _showWorkoutOptions(Workout workout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: BoxDecoration(
                color: Color(0xFF0F0F0F).withOpacity(0.92),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull notch bar
                  Container(
                    height: 4,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Title header info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.name.toUpperCase(),
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${workout.split.toUpperCase()} SPLIT  •  ${workout.exercises.length} EXERCISES',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.10)),

                  // Option Actions
                  _buildOptionItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Routine',
                    color: Colors.white.withOpacity(0.70),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/workout/create?id=${workout.id}');
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.copy_all_rounded,
                    title: 'Duplicate Routine',
                    color: Colors.white.withOpacity(0.70),
                    onTap: () async {
                      Navigator.pop(context);
                      _triggerDuplicate(workout);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.share_rounded,
                    title: 'Share Strength routine',
                    color: Colors.white.withOpacity(0.70),
                    onTap: () {
                      Navigator.pop(context);
                      _triggerShare(workout);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Permanently',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(workout);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }

  // ─── ACTION IMPLEMENTATIONS ───
  Future<void> _triggerDuplicate(Workout workout) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final copy = Workout(
        id: '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 1000)}',
        userId: workout.userId,
        name: '${workout.name} (Copy)',
        split: workout.split,
        createdAt: DateTime.now(),
        exercises: workout.exercises
            .map(
              (e) => WorkoutExercise(
                exerciseId: e.exerciseId,
                name: e.name,
                category: e.category,
                image: e.image,
                gifUrl: e.gifUrl,
                restSeconds: e.restSeconds,
                sets: e.sets
                    .map(
                      (s) => WorkoutSet(
                        id: '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 1000)}_set',
                        setNumber: s.setNumber,
                        reps: s.reps,
                        weight: s.weight,
                        isCompleted: false,
                      ),
                    )
                    .toList(),
                notes: e.notes,
              ),
            )
            .toList(),
      );

      await ref.read(workoutListProvider.notifier).addOrUpdateWorkout(copy);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Duplicated ${workout.name} successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error duplicating: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _triggerShare(Workout workout) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: Color(0xFF0F0F0F).withOpacity(0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                SizedBox(height: 8),
                Text(
                  'SHARE STRENGTH ROUTINE',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share links or export code for: ${workout.name.toUpperCase()}',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.54), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'KRATOS-${workout.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.70),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Routine Code copied to Clipboard!',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.70),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'DISMISS',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Workout workout) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: Color(0xFF0F0F0F).withOpacity(0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'DELETE ROUTINE?',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to permanently delete "${workout.name}"? This action is absolute and cannot be undone.',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.54),
                fontSize: 11,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(workoutListProvider.notifier)
                        .removeWorkout(workout.id);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted "${workout.name}" successfully.',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Text(
                  'DELETE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onTemplateTapped(String name, String split) {
    final user = ref.read(firebaseAuthProvider).currentUser;
    List<WorkoutExercise> exercises = [];
    
    if (name.contains('Push')) {
      exercises = [
        WorkoutExercise(
          exerciseId: '0025',
          name: 'Barbell Bench Press',
          category: 'Chest',
          image: 'images/0025-EIeI8Vf.jpg',
          gifUrl: 'videos/0025-EIeI8Vf.gif',
          restSeconds: 90,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_bench_$i', setNumber: i + 1, reps: 10, weight: 60.0)),
        ),
        WorkoutExercise(
          exerciseId: '0091',
          name: 'Barbell Seated Overhead Press',
          category: 'Shoulders',
          image: 'images/0091-kTbSH9h.jpg',
          gifUrl: 'videos/0091-kTbSH9h.gif',
          restSeconds: 90,
          sets: List.generate(3, (i) => WorkoutSet(id: 'set_ohp_$i', setNumber: i + 1, reps: 10, weight: 40.0)),
        ),
        WorkoutExercise(
          exerciseId: '0194',
          name: 'Cable Overhead Triceps Extension',
          category: 'Upper Arms',
          image: 'images/0194-2IxROQ1.jpg',
          gifUrl: 'videos/0194-2IxROQ1.gif',
          restSeconds: 60,
          sets: List.generate(3, (i) => WorkoutSet(id: 'set_tri_$i', setNumber: i + 1, reps: 12, weight: 20.0)),
        ),
      ];
    } else if (name.contains('Pull')) {
      exercises = [
        WorkoutExercise(
          exerciseId: '0017',
          name: 'Assisted Pull-up',
          category: 'Back',
          image: 'images/0017-kiJ4Z2K.jpg',
          gifUrl: 'videos/0017-kiJ4Z2K.gif',
          restSeconds: 90,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_pull_$i', setNumber: i + 1, reps: 8, weight: 0.0)),
        ),
        WorkoutExercise(
          exerciseId: '1677',
          name: 'Dumbbell Seated Bicep Curl',
          category: 'Upper Arms',
          image: 'images/1677-xiA6lRr.jpg',
          gifUrl: 'videos/1677-xiA6lRr.gif',
          restSeconds: 60,
          sets: List.generate(3, (i) => WorkoutSet(id: 'set_curl_$i', setNumber: i + 1, reps: 12, weight: 15.0)),
        ),
      ];
    } else if (name.contains('Full Body Power')) {
      exercises = [
        WorkoutExercise(
          exerciseId: '0032',
          name: 'Barbell Deadlift',
          category: 'Back',
          image: 'images/0032-ila4NZS.jpg',
          gifUrl: 'videos/0032-ila4NZS.gif',
          restSeconds: 120,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_dl_$i', setNumber: i + 1, reps: 5, weight: 100.0)),
        ),
        WorkoutExercise(
          exerciseId: '0025',
          name: 'Barbell Bench Press',
          category: 'Chest',
          image: 'images/0025-EIeI8Vf.jpg',
          gifUrl: 'videos/0025-EIeI8Vf.gif',
          restSeconds: 120,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_bench_$i', setNumber: i + 1, reps: 8, weight: 60.0)),
        ),
        WorkoutExercise(
          exerciseId: '0024',
          name: 'Barbell Bench Front Squat',
          category: 'Upper Legs',
          image: 'images/0024-Y7YcmIJ.jpg',
          gifUrl: 'videos/0024-Y7YcmIJ.gif',
          restSeconds: 120,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_squat_$i', setNumber: i + 1, reps: 8, weight: 80.0)),
        ),
      ];
    } else if (name.contains('Core Shredder')) {
      exercises = [
        WorkoutExercise(
          exerciseId: '0274',
          name: 'Crunch Floor',
          category: 'Waist',
          image: 'images/0274-TFqbd8t.jpg',
          gifUrl: 'videos/0274-TFqbd8t.gif',
          restSeconds: 45,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_crunch_$i', setNumber: i + 1, reps: 20, weight: 0.0)),
        ),
        WorkoutExercise(
          exerciseId: '3544',
          name: 'Bodyweight Incline Side Plank',
          category: 'Waist',
          image: 'images/3544-5VXmnV5.jpg',
          gifUrl: 'videos/3544-5VXmnV5.gif',
          restSeconds: 45,
          sets: List.generate(3, (i) => WorkoutSet(id: 'set_plank_$i', setNumber: i + 1, reps: 1, weight: 0.0)),
        ),
      ];
    } else {
      exercises = [
        WorkoutExercise(
          exerciseId: '0024',
          name: 'Barbell Bench Front Squat',
          category: 'Upper Legs',
          image: 'images/0024-Y7YcmIJ.jpg',
          gifUrl: 'videos/0024-Y7YcmIJ.gif',
          restSeconds: 120,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_squat_$i', setNumber: i + 1, reps: 8, weight: 80.0)),
        ),
        WorkoutExercise(
          exerciseId: '0999',
          name: 'Band Single Leg Calf Raise',
          category: 'Lower Legs',
          image: 'images/0999-9JprnPh.jpg',
          gifUrl: 'videos/0999-9JprnPh.gif',
          restSeconds: 60,
          sets: List.generate(4, (i) => WorkoutSet(id: 'set_calf_$i', setNumber: i + 1, reps: 15, weight: 0.0)),
        ),
      ];
    }

    final templateRoutine = Workout(
      id: '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 1000)}',
      userId: user?.uid ?? 'guest_user',
      name: name,
      split: split.replaceAll(' SPLIT', ''),
      createdAt: DateTime.now(),
      exercises: exercises,
    );

    _showTemplatePreviewModal(templateRoutine);
  }

  void _showTemplatePreviewModal(Workout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                Text(
                  workout.name.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${workout.exercises.length} EXERCISES • ${workout.split.toUpperCase()} SPLIT',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, index) {
                      return WorkoutExerciseCard(
                        exercise: workout.exercises[index],
                        index: index,
                        isReorderable: false,
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close modal
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await ref.read(workoutListProvider.notifier).addOrUpdateWorkout(workout);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Added ${workout.name} to your custom routines!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'ADD TO MY ROUTINES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── EMPTY STATE WIDGET ───
  Widget _buildEmptyState(bool isListTotallyEmpty) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center_outlined,
                  color: AppColors.primary.withOpacity(0.4),
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              isListTotallyEmpty
                  ? 'NO WORKOUT ROUTINES YET'
                  : 'NO MATCHES FOUND',
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              isListTotallyEmpty
                  ? 'Welcome to the tactical fitness command center. Build your elite strength routines from scratch or split templates.'
                  : 'We couldn\'t find any matches for your active filter split or search queries. Clear search to show all.',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900.withOpacity(0.38),
                fontSize: 11,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                if (isListTotallyEmpty) {
                  context.push('/workout/create');
                } else {
                  setState(() {
                    _searchQuery = '';
                    _filterSplit = 'ALL';
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Text(
                  isListTotallyEmpty ? 'BUILD ELITE ROUTINE' : 'CLEAR FILTERS',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.grey900,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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

// ─── SHIMMER SKELETON LOADER ───
class _ShimmerWorkoutsLoader extends StatelessWidget {
  const _ShimmerWorkoutsLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left image skeleton
                Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Center details skeleton
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 10,
                              width: 80,
                              color: Colors.white.withOpacity(0.03),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 14,
                              width: 140,
                              color: Colors.white.withOpacity(0.03),
                            ),
                            SizedBox(height: 6),
                            Container(
                              height: 10,
                              width: 100,
                              color: Colors.white.withOpacity(0.02),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              height: 16,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 16,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
