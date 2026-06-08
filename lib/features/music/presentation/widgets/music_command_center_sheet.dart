import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/music_controller.dart';
import '../controllers/playlists_controller.dart';
import 'tactical_playlist_card.dart';
import '../screens/music_command_center_screen.dart';
import '../../domain/models/workout_playlist.dart';

class MusicCommandCenterSheet extends ConsumerStatefulWidget {
  const MusicCommandCenterSheet({super.key});

  @override
  ConsumerState<MusicCommandCenterSheet> createState() => _MusicCommandCenterSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicCommandCenterSheet(),
    );
  }
}

class _MusicCommandCenterSheetState extends ConsumerState<MusicCommandCenterSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsControllerProvider.notifier).fetchPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistsControllerProvider);
    final musicState = ref.watch(musicControllerProvider);
    final track = musicState.currentTrack;

    final flattenedCurated = playlistState.categorizedCuratedMixes.values.expand((e) => e).toList();

    // Find the active playlist
    WorkoutPlaylist? activePlaylist;
    if (musicState.currentPlaylistUri != null) {
      final allPlaylists = [
        ...flattenedCurated,
        ...playlistState.userPlaylists,
        ...playlistState.featuredPlaylists,
      ];
      try {
        activePlaylist = allPlaylists.firstWhere((p) => p.uri == musicState.currentPlaylistUri);
      } catch (_) {}
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.glassmorphism.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: context.glassmorphism.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header Row with "Expand" action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'AUDIO QUICK ACCESS',
                      style: AppTypography.labelBold.copyWith(
                        color: context.colors.primary,
                        letterSpacing: 2.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MusicCommandCenterScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          'FULL LIBRARY',
                          style: AppTypography.labelBold.copyWith(
                            color: context.colors.onSurface,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, color: context.colors.onSurface, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currently Playing Section
                    if (track != null || activePlaylist != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'NOW PLAYING',
                          style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.54), letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Active Playlist Info
                      if (activePlaylist != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Icon(Icons.playlist_play, color: context.colors.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'SOURCE: ${activePlaylist.name.toUpperCase()}',
                                  style: AppTypography.labelBold.copyWith(color: context.colors.primary, letterSpacing: 1.0, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Track Info
                      if (track != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: track.albumImageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(track.albumImageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: context.colors.onSurface.withValues(alpha: 0.1),
                                  ),
                                  child: track.albumImageUrl.isEmpty
                                      ? Icon(Icons.music_note, color: context.colors.onSurface.withValues(alpha: 0.54))
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.name,
                                        style: AppTypography.labelBold.copyWith(color: context.colors.onSurface, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        track.artistName,
                                        style: AppTypography.bodySmall.copyWith(color: context.colors.onSurface.withValues(alpha: 0.7)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Play/Pause Control inside Now Playing
                                GestureDetector(
                                  onTap: () {
                                    if (musicState.isPlaying) {
                                      ref.read(musicControllerProvider.notifier).pause();
                                    } else {
                                      ref.read(musicControllerProvider.notifier).play();
                                    }
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.colors.primary.withValues(alpha: 0.2),
                                      border: Border.all(color: context.colors.primary),
                                    ),
                                    child: Icon(
                                      musicState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: context.colors.primary,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],

                    // Recommended For Today
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'RECOMMENDED FOR TODAY',
                        style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.54), letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (playlistState.isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: context.colors.primary),
                        ),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: flattenedCurated.length > 3 ? 3 : flattenedCurated.length,
                          itemBuilder: (context, index) {
                            final playlist = flattenedCurated[index];
                            return TacticalPlaylistCard(
                              playlist: playlist,
                              onTap: () {
                                ref.read(musicControllerProvider.notifier).playPlaylist(playlist.uri);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: context.colors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelBold.copyWith(
            color: context.colors.onSurface,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(List playlists) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return TacticalPlaylistCard(
            playlist: playlist,
            onTap: () {
              ref.read(musicControllerProvider.notifier).playPlaylist(playlist.uri);
              Navigator.pop(context); // Close sheet and play
            },
          );
        },
      ),
    );
  }
}
