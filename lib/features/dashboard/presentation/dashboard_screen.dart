// lib/features/dashboard/presentation/dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../exercise_library/presentation/screens/exercise_library_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../workout/presentation/screens/my_workouts_screen.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/theme/theme_controller.dart';

// Daily Planner Integrations
import '../../daily_planner/presentation/screens/daily_planner_screen.dart';
import '../../daily_planner/presentation/controllers/today_mission_controller.dart';
import '../../workout/presentation/controllers/workout_controller.dart';
import '../../music/presentation/screens/music_command_center_screen.dart';
import 'widgets/dashboard_music_player.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTabIndex = 0;
  bool _isNavBarVisible = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    final List<Widget> pages = [
      _buildHomeTab(user),
      MyWorkoutsScreen(),
      DailyPlannerScreen(),
      ExerciseLibraryScreen(),
      ProfileScreen(isTab: true),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          return false;
        },
        child: Stack(
          children: [
            IndexedStack(index: _currentTabIndex, children: pages),

            // Anchored MNC-Grade Bottom Navigation Bar (YouTube Style)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom > 0 
                      ? MediaQuery.of(context).padding.bottom 
                      : 10,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F0F0F)
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.fitness_center_rounded, 'Workouts'),
                    _buildNavItem(2, Icons.calendar_month_rounded, 'Planner'),
                    _buildNavItem(3, Icons.view_list_rounded, 'Exercises'),
                    _buildNavItem(4, Icons.person_rounded, 'You'),
                  ],
                ),
              ),
            ),
            
            // Floating AI Chat Button (only visible on Home tab)
            if (_currentTabIndex == 0)
              Positioned(
                right: 20,
                bottom: 80 + MediaQuery.of(context).padding.bottom,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push('/chat'),
                  backgroundColor: context.colors.primary,
                  elevation: 8,
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Kratos AI',
                    style: AppTypography.labelBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Nav Item Builder (YouTube Style)
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = isActive 
        ? context.colors.primary
        : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.6));

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: color,
                  size: isActive ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 0: REDESIGNED HOME DASHBOARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHomeTab(dynamic user) {
    final todayMission = ref.watch(todayMissionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawName = user?.displayName;
    final hasName = rawName != null && rawName.trim().isNotEmpty;
    final firstName = hasName ? rawName!.split(' ').first : null;

    // Time-of-day subtitle
    final hour = DateTime.now().hour;
    final String timeGreeting;
    if (hour < 5) {
      timeGreeting = 'Burn the midnight oil.';
    } else if (hour < 12) {
      timeGreeting = 'Rise and conquer.';
    } else if (hour < 17) {
      timeGreeting = 'Stay locked in.';
    } else if (hour < 21) {
      timeGreeting = 'Finish what you started.';
    } else {
      timeGreeting = 'Rest breeds power.';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── Header Row ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KRATOS',
                          style: AppTypography.displaySmall.copyWith(
                            color: isDark ? Colors.white : context.customColors.grey900,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasName) ...[
                              Text(
                                'Hello, ${firstName!}.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : context.customColors.grey500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              timeGreeting,
                              style: TextStyle(
                                color: context.colors.primary.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(themeControllerProvider.notifier).toggleTheme();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.white54 : context.customColors.grey600,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Hero Mission Card ───
              _buildHeroMissionCard(todayMission, isDark),

              const SizedBox(height: 20),

              // ─── Quick Actions ───
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.fitness_center_rounded,
                      label: 'WORKOUTS',
                      color: context.colors.primary,
                      isDark: isDark,
                      onTap: () => setState(() => _currentTabIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'NUTRITION',
                      color: const Color(0xFF22C55E),
                      isDark: isDark,
                      onTap: () => context.push('/nutrition'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.calendar_today_rounded,
                      label: 'PLANNER',
                      color: Colors.tealAccent.shade400,
                      isDark: isDark,
                      onTap: () => setState(() => _currentTabIndex = 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.headphones_rounded,
                      label: 'MUSIC',
                      color: const Color(0xFF1DB954),
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MusicCommandCenterScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Music Section Header ───
              Text(
                'NOW PLAYING',
                style: AppTypography.labelBold.copyWith(
                  color: isDark ? Colors.white54 : context.customColors.grey500,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),

              // ─── Inline Music Player ───
              const DashboardMusicPlayer(),

              const SizedBox(height: 80), // Bottom spacer for nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Mission Card ───
  Widget _buildHeroMissionCard(TodayMissionState todayMission, bool isDark) {
    if (todayMission.isRecovery || todayMission.workout == null) {
      return _buildRecoveryCard(isDark);
    }
    return _buildWorkoutMissionCard(todayMission, isDark);
  }

  Widget _buildRecoveryCard(bool isDark) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(22),
      backgroundColor: isDark
          ? Colors.teal.withValues(alpha: 0.08)
          : Colors.teal.withValues(alpha: 0.04),
      borderColor: Colors.tealAccent.withValues(alpha: isDark ? 0.15 : 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.spa_rounded, color: Colors.tealAccent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOVERY DAY',
                      style: AppTypography.labelBold.copyWith(
                        color: Colors.tealAccent,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Active System Repair',
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? Colors.white : context.customColors.grey900,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'No workout scheduled. Rest, hydrate, and prepare for your next mission.',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white38 : context.customColors.grey500,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => setState(() => _currentTabIndex = 2),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.tealAccent.shade400,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'VIEW WEEKLY PLANNER',
                  style: AppTypography.labelBold.copyWith(
                    color: Colors.black,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutMissionCard(TodayMissionState todayMission, bool isDark) {
    final workout = todayMission.workout!;
    final int totalExercises = workout.exercises.length;
    int totalSets = 0;
    for (var ex in workout.exercises) {
      totalSets += ex.sets.length;
    }
    final int estDurationMins = (totalSets * 3.5).round();
    final int estCalories = (totalSets * 12 + estDurationMins * 7).round();
    final bool isCompleted = todayMission.plannerItem?.completed ?? false;

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(22),
      backgroundColor: isDark
          ? (isCompleted
              ? context.customColors.success.withValues(alpha: 0.06)
              : context.colors.primary.withValues(alpha: 0.06))
          : (isCompleted
              ? context.customColors.success.withValues(alpha: 0.03)
              : context.colors.primary.withValues(alpha: 0.03)),
      borderColor: isCompleted
          ? context.customColors.success.withValues(alpha: 0.15)
          : context.colors.primary.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? context.customColors.success.withValues(alpha: 0.12)
                      : context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline_rounded : Icons.flash_on_rounded,
                  color: isCompleted ? context.customColors.success : context.colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'MISSION ACCOMPLISHED' : 'TODAY\'S MISSION',
                      style: AppTypography.labelBold.copyWith(
                        color: isCompleted ? context.customColors.success : context.colors.primary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      workout.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: isDark ? Colors.white : context.customColors.grey900,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stat pills
          Row(
            children: [
              _buildMissionPill(Icons.timer_outlined, '~$estDurationMins min', isDark),
              const SizedBox(width: 8),
              _buildMissionPill(Icons.fitness_center_rounded, '$totalExercises exercises', isDark),
              const SizedBox(width: 8),
              _buildMissionPill(Icons.local_fire_department_rounded, '$estCalories kcal', isDark),
            ],
          ),
          const SizedBox(height: 20),

          // CTA Button
          GestureDetector(
            onTap: () {
              if (isCompleted) {
                setState(() => _currentTabIndex = 2);
              } else {
                ref.read(activeSessionProvider(workout).notifier).startSession();
                context.push('/workout/session/${workout.id}');
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: isCompleted ? null : context.customColors.primaryGradient,
                color: isCompleted
                    ? (isDark
                        ? context.customColors.success.withValues(alpha: 0.12)
                        : context.customColors.success.withValues(alpha: 0.08))
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: isCompleted
                    ? Border.all(color: context.customColors.success.withValues(alpha: 0.25))
                    : null,
              ),
              child: Center(
                child: Text(
                  isCompleted ? 'CONQUERED • VIEW TIMELINE' : 'START WORKOUT',
                  style: AppTypography.labelBold.copyWith(
                    color: isCompleted ? context.customColors.success : Colors.white,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionPill(IconData icon, String text, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isDark ? Colors.white38 : context.customColors.grey500),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white70 : context.customColors.grey700,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Action Button ───
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.12 : 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : context.customColors.grey700,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
