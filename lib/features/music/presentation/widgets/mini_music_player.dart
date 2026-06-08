import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/music_controller.dart';
import 'music_command_center_sheet.dart';

class MiniMusicPlayer extends ConsumerStatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  ConsumerState<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends ConsumerState<MiniMusicPlayer> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = Duration.zero;
  DateTime? _lastUpdate;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_isPlaying && _lastUpdate != null) {
        final now = DateTime.now();
        final diff = now.difference(_lastUpdate!);
        setState(() {
          _currentPosition += diff;
          _lastUpdate = now;
          if (_currentPosition > _trackDuration) {
            _currentPosition = _trackDuration; // Clamp to end
          }
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncWithSpotifyState() {
    final state = ref.read(musicControllerProvider);
    if (state.progressMs != null) {
      _currentPosition = Duration(milliseconds: state.progressMs!);
      _lastUpdate = DateTime.now();
    }
    _isPlaying = state.isPlaying;
    _trackDuration = Duration(milliseconds: state.currentTrack?.durationMs ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(musicControllerProvider, (previous, next) {
      if (next.progressMs != previous?.progressMs || next.isPlaying != previous?.isPlaying) {
        _syncWithSpotifyState();
      }
    });

    final musicState = ref.watch(musicControllerProvider);
    final track = musicState.currentTrack;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (track == null && !musicState.isConnected) {
      return _buildConnectCard(context, ref, isDark);
    }

    if (track == null) {
      return const SizedBox.shrink(); 
    }

    final progressFraction = _trackDuration.inMilliseconds > 0 
        ? (_currentPosition.inMilliseconds / _trackDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        MusicCommandCenterSheet.show(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? context.colors.surface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? context.glassmorphism.borderColor : context.glassmorphism.borderColor,
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  // Progress Bar Background
                  Container(
                    height: 3,
                    color: isDark ? Colors.white10 : context.customColors.grey300,
                  ),
                  // Live Progress Bar
                  FractionallySizedBox(
                    widthFactor: progressFraction,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Cover Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black45 : context.customColors.grey100,
                            borderRadius: BorderRadius.circular(12),
                            image: track.albumImageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(track.albumImageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: track.albumImageUrl.isEmpty
                              ? Icon(Icons.graphic_eq, color: context.colors.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Track Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                track.name,
                                style: AppTypography.labelBold.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artistName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? Colors.white54 : context.customColors.grey600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Controls
                        _buildControls(ref, musicState, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(WidgetRef ref, musicState, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: isDark ? Colors.white : Colors.black, size: 28),
          onPressed: () => ref.read(musicControllerProvider.notifier).previous(),
        ),
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
              color: context.colors.primary.withValues(alpha: 0.15),
              border: Border.all(color: context.colors.primary.withValues(alpha: 0.5)),
            ),
            child: Icon(
              musicState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: context.colors.primary,
              size: 26,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: isDark ? Colors.white : Colors.black, size: 28),
          onPressed: () => ref.read(musicControllerProvider.notifier).next(),
        ),
      ],
    );
  }

  Widget _buildConnectCard(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? context.colors.surface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? context.glassmorphism.borderColor : context.glassmorphism.borderColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.speaker_group_outlined, color: context.colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "TACTICAL AUDIO",
                    style: AppTypography.labelBold.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(musicControllerProvider.notifier).connectWithAuth();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: context.colors.primary.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("CONNECT"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
