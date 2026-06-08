// lib/features/workout/presentation/screens/workout_detail_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/workout_controller.dart';
import '../../domain/models/workout_model.dart';
import '../widgets/workout_exercise_card.dart';
import '../widgets/past_session_card.dart';

import '../../../music/presentation/controllers/music_controller.dart';
import '../../../music/presentation/controllers/playlists_controller.dart';
import '../../../music/presentation/widgets/tactical_playlist_card.dart';
import '../../../music/domain/models/workout_playlist.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsControllerProvider.notifier).fetchPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutListProvider);
    final playlistState = ref.watch(playlistsControllerProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: Color(0xFF090909), // Premium Primary Background #090909
      body: workoutsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: context.colors.primary)),
        error: (err, st) => Center(child: Text('Failed to load: $err', style: TextStyle(color: Color(0xFF8A8A8A)))),
        data: (workouts) {
          final workout = workouts.firstWhere(
            (w) => w.id == widget.workoutId,
            orElse: () => Workout(
              id: '',
              userId: '',
              name: 'Routine Not Found',
              split: 'Push',
              createdAt: DateTime.now(),
              exercises: [],
            ),
          );

          if (workout.id.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Routine not found or deleted', style: TextStyle(color: Color(0xFFF5F5F5))),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF171717),
                      foregroundColor: Color(0xFFF5F5F5),
                    ),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Estimate total routine duration dynamically: roughly 3.5 mins per set
          int totalSets = 0;
          for (var ex in workout.exercises) {
            totalSets += ex.sets.length;
          }
          final int estDurationMins = (totalSets * 3.5).round();

          // Calculate estimated target calories
          final int estCalories = (totalSets * 12 + estDurationMins * 7).round();

          // Find assigned playlist
          WorkoutPlaylist? assignedPlaylist;
          final allPlaylists = playlistState.categorizedCuratedMixes.values.expand((e) => e).toList();
          
          if (workout.playlistUri != null && workout.playlistUri!.isNotEmpty) {
            try {
              assignedPlaylist = allPlaylists.firstWhere((p) => p.uri == workout.playlistUri);
            } catch (_) {}
          }

          return Stack(
            children: [
              // Subtle Atmospheric glows (No hard radial circles, no aggressive red color)
              Positioned(
                top: -120,
                right: -60,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3B3B).withOpacity(0.015), // extremely subtle soft wash
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 250,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF3B3B).withOpacity(0.008), // extremely subtle soft wash
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Premium Custom AppBar Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TactilePressable(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF111111), // Surface #111111
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF5F5F5), size: 16),
                            ),
                          ),
                          Text(
                            'ROUTINE DETAILS',
                            style: TextStyle(
                              color: Color(0xFF8A8A8A), // Secondary Text #8A8A8A
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          _TactilePressable(
                            onTap: () {
                              ref.read(workoutBuilderProvider.notifier).initFromWorkout(workout);
                              context.push('/workout/create?id=${workout.id}');
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF111111),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Icon(Icons.edit_rounded, color: Color(0xFFF5F5F5), size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12),

                            // ─── PREMIUM HERO WORKOUT BANNER ───
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _buildHeroSection(workout, estDurationMins, estCalories),
                            ),
                            SizedBox(height: 20),

                            // ─── PREMIUM STATS ROW ───
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _buildStatsRow(estDurationMins, totalSets, estCalories),
                            ),
                            SizedBox(height: 24),

                            // ─── ASSIGNED AUDIO ───
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ASSIGNED AUDIO',
                                    style: TextStyle(
                                      color: Color(0xFFF5F5F5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showPlaylistSelectorModal(workout),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: context.colors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: context.colors.primary.withOpacity(0.3), width: 0.8),
                                      ),
                                      child: Text(
                                        'CHANGE',
                                        style: TextStyle(
                                          color: context.colors.secondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            if (assignedPlaylist != null)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: SizedBox(
                                  height: 240,
                                  child: TacticalPlaylistCard(
                                    playlist: assignedPlaylist,
                                    onTap: () {
                                      ref.read(musicControllerProvider.notifier).playPlaylist(assignedPlaylist!.uri);
                                    },
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: GestureDetector(
                                  onTap: () => _showPlaylistSelectorModal(workout),
                                  child: Container(
                                    height: 80,
                                    width: 240,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF111111),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_circle_outline, color: context.colors.primary, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'ASSIGN PLAYLIST',
                                            style: TextStyle(
                                              color: context.colors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 24),

                            // ─── EXERCISES HEADER SECTION ───
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'EXERCISES INCLUDED',
                                    style: TextStyle(
                                      color: Color(0xFFF5F5F5), // Primary Text #F5F5F5
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF111111),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                                    ),
                                    child: Text(
                                      '${workout.exercises.length} TOTAL',
                                      style: TextStyle(
                                        color: Color(0xFF8A8A8A), // Secondary Text #8A8A8A
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),

                            // ─── EXERCISES CARD LIST ───
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: workout.exercises.length,
                                itemBuilder: (context, index) {
                                  final ex = workout.exercises[index];
                                  return WorkoutExerciseCard(
                                    exercise: ex,
                                    index: index,
                                    isReorderable: false,
                                  );
                                },
                              ),
                            ),
                            
                            // ─── PAST SESSIONS SECTION ───
                            historyAsync.when(
                              data: (sessions) {
                                final pastSessions = sessions.where((s) => s.workoutId == workout.id).toList();
                                if (pastSessions.isEmpty) return SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 32),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PAST SESSIONS',
                                            style: TextStyle(
                                              color: Color(0xFFF5F5F5),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF111111),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
                                            ),
                                            child: Text(
                                              '${pastSessions.length} TOTAL',
                                              style: TextStyle(
                                                color: Color(0xFF8A8A8A),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: pastSessions.length,
                                        itemBuilder: (context, index) {
                                          return PastSessionCard(session: pastSessions[index]);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => SizedBox.shrink(),
                              error: (_, __) => SizedBox.shrink(),
                            ),

                            SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── FLOATING HERO START BUTTON ───
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _TactilePressable(
                  onTap: () {
                    // Initialize the session state & launch focus workout mode!
                    ref.read(activeSessionProvider(workout).notifier).startSession();
                    context.push('/workout/session/${workout.id}');
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB00020)], // Premium soft crimson gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE50914).withOpacity(0.18), // Restrained soft glow shadow
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'START WORKOUT ROUTINE',
                            style: TextStyle(
                              color: Color(0xFFF5F5F5),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900.withOpacity(0.54), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Premium Hero Workout Banner Widget Builder (Atmospheric, clean, layered, restrained)
  Widget _buildHeroSection(Workout workout, int estDuration, int estCalories) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF111111), // Surface #111111
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.04), // Subtle Border
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Soft crimson linear dark background blend to create warm atmospheric depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF161616),
                      Color(0xFFFF3B3B).withOpacity(0.015), // Warm dark crimson wash
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Content Layout Overlay
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Category Badge & Difficulty Chip Row
                  Row(
                    children: [
                      // Split Badge (e.g. PUSH)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Color(0xFF261010), // Extremely muted dark crimson
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(0xFFFF5252).withOpacity(0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          workout.split.toUpperCase(),
                          style: TextStyle(
                            color: Color(0xFFFF5252), // Soft premium crimson
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Difficulty chip derived dynamically
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Color(0xFF171717),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          workout.exercises.length <= 2
                              ? 'BEGINNER'
                              : workout.exercises.length <= 5
                                  ? 'INTERMEDIATE'
                                  : 'ADVANCED',
                          style: TextStyle(
                            color: workout.exercises.length <= 2
                                ? Color(0xFF52FFB8) // Soft mint
                                : workout.exercises.length <= 5
                                    ? Color(0xFFFFB852) // Soft amber
                                    : Color(0xFFFF5252), // Soft crimson
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  // Workout title (Restrained, elegant size 22)
                  Text(
                    workout.name.toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFFF5F5F5), // Primary Text
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Created on ${workout.createdAt.day}/${workout.createdAt.month}/${workout.createdAt.year}',
                    style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 11),
                  ),
                  SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.10), height: 1),
                  SizedBox(height: 12),
                  // Duration & Calories inline
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFFFF5252).withOpacity(0.7), size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${workout.exercises.length} Exercises  •  $estDuration mins  •  $estCalories kcal',
                        style: TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row containing the 3 fully responsive Glassmorphic Stats cards (Fully responsive, layout overflow safe)
  Widget _buildStatsRow(int estDuration, int totalSets, int estCalories) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            value: '$estDuration',
            unit: 'MIN',
            label: 'DURATION',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center_rounded,
            value: '$totalSets',
            unit: 'SETS',
            label: 'WORKSETS',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            value: '$estCalories',
            unit: 'KCAL',
            label: 'EST. BURN',
          ),
        ),
      ],
    );
  }

  // Responsive, compact Stat Card Widget (Restrained surfaces, absolutely overflow-safe)
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Color(0xFF111111), // Surface #111111
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.04), // Subtle Border
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row 1: Icon + Value + Unit inline (wrapped in FittedBox to absolutely prevent horizontal right overflow on narrow displays)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Color(0xFFFF5252), size: 14),
                    SizedBox(width: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: Color(0xFFF5F5F5), // Primary Text
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 2),
                        Text(
                          unit,
                          style: TextStyle(
                            color: Color(0xFFF5F5F5).withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6),
              // Row 2: Secondary label
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF8A8A8A), // Secondary Text
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylistSelectorModal(Workout workout) {
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
                      'SELECT TACTICAL PLAYLIST',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (playlistState.isLoading && allPlaylists.isEmpty)
                      Center(child: CircularProgressIndicator(color: context.colors.primary))
                    else if (allPlaylists.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No playlists available.', style: TextStyle(color: Colors.white70)),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: allPlaylists.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                          itemBuilder: (context, index) {
                            final pl = allPlaylists[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: pl.imageUrl.isNotEmpty
                                    ? Image.network(pl.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                                    : Container(width: 40, height: 40, color: Colors.black45, child: const Icon(Icons.music_note, color: Colors.white)),
                              ),
                              title: Text(
                                pl.name, 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                pl.category,
                                style: TextStyle(color: context.colors.primary, fontSize: 11),
                              ),
                              onTap: () {
                                ref.read(workoutListProvider.notifier).addOrUpdateWorkout(
                                  workout.copyWith(playlistUri: pl.uri, playlistName: pl.name)
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Audio updated to ${pl.name}'),
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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

// Reusable High-end scale animation interactive widget
class _TactilePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactilePressable({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TactilePressable> createState() => _TactilePressableState();
}

class _TactilePressableState extends State<_TactilePressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
