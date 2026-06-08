// lib/features/dashboard/presentation/widgets/dashboard_music_player.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../music/presentation/controllers/music_controller.dart';
import '../../../music/presentation/controllers/playlists_controller.dart';
import '../../../music/presentation/widgets/music_command_center_sheet.dart';

class DashboardMusicPlayer extends ConsumerStatefulWidget {
  const DashboardMusicPlayer({super.key});

  @override
  ConsumerState<DashboardMusicPlayer> createState() =>
      _DashboardMusicPlayerState();
}

class _DashboardMusicPlayerState extends ConsumerState<DashboardMusicPlayer>
    with SingleTickerProviderStateMixin {
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
            _currentPosition = _trackDuration;
          }
        });
      }
    });
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsControllerProvider.notifier).fetchPlaylists();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncState() {
    final state = ref.read(musicControllerProvider);
    if (state.progressMs != 0) {
      _currentPosition = Duration(milliseconds: state.progressMs);
      _lastUpdate = DateTime.now();
    }
    _isPlaying = state.isPlaying;
    _trackDuration = Duration(milliseconds: state.currentTrack?.durationMs ?? 0);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(musicControllerProvider, (prev, next) {
      if (next.progressMs != prev?.progressMs || next.isPlaying != prev?.isPlaying) {
        _syncState();
      }
    });

    final musicState = ref.watch(musicControllerProvider);
    final playlistState = ref.watch(playlistsControllerProvider);
    final track = musicState.currentTrack;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = playlistState.categorizedCuratedMixes.values.expand((e) => e).toList();

    if (track == null && !musicState.isConnected) return _connectCard(isDark);
    if (track == null) return _idleCard(isDark, playlists);

    final frac = _trackDuration.inMilliseconds > 0
        ? (_currentPosition.inMilliseconds / _trackDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => MusicCommandCenterSheet.show(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D1A) : const Color(0xFFF0F2EF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album art + track info + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72, height: 72,
                      child: track.albumImageUrl.isNotEmpty
                          ? Image.network(track.albumImageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(isDark))
                          : _placeholder(isDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(track.name,
                            style: AppTypography.headlineSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.grey900,
                                fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(track.artistName,
                            style: AppTypography.bodySmall.copyWith(
                                color: isDark ? Colors.white54 : AppColors.grey500, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: frac,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  color: const Color(0xFF1DB954),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_currentPosition), style: TextStyle(color: isDark ? Colors.white38 : AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w600)),
                  Text(_fmt(_trackDuration), style: TextStyle(color: isDark ? Colors.white38 : AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ctrl(Icons.shuffle_rounded, isDark, size: 20, active: musicState.shuffle,
                      onTap: () => ref.read(musicControllerProvider.notifier).toggleShuffle()),
                  const SizedBox(width: 20),
                  _ctrl(Icons.skip_previous_rounded, isDark, size: 28,
                      onTap: () => ref.read(musicControllerProvider.notifier).previous()),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => musicState.isPlaying
                        ? ref.read(musicControllerProvider.notifier).pause()
                        : ref.read(musicControllerProvider.notifier).play(),
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white : AppColors.grey900,
                        boxShadow: [BoxShadow(color: (isDark ? Colors.white : AppColors.grey900).withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2)],
                      ),
                      child: Icon(musicState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isDark ? AppColors.grey900 : Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ctrl(Icons.skip_next_rounded, isDark, size: 28,
                      onTap: () => ref.read(musicControllerProvider.notifier).next()),
                  const SizedBox(width: 20),
                  _ctrl(Icons.repeat_rounded, isDark, size: 20, active: musicState.repeat,
                      onTap: () => ref.read(musicControllerProvider.notifier).toggleRepeat()),
                ],
              ),

              // Playlist thumbnails
              if (playlists.isNotEmpty) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: playlists.length > 5 ? 5 : playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final p = playlists[i];
                      final isActive = musicState.currentPlaylistUri == p.uri;
                      return GestureDetector(
                        onTap: () => ref.read(musicControllerProvider.notifier).playPlaylist(p.uri),
                        child: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? const Color(0xFF1DB954) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _thumbPlaceholder(isDark))
                                : _thumbPlaceholder(isDark),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
      color: isDark ? Colors.black38 : AppColors.grey200,
      child: Icon(Icons.album_rounded, color: isDark ? Colors.white38 : AppColors.grey500, size: 32));

  Widget _thumbPlaceholder(bool isDark) => Container(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
      child: Icon(Icons.music_note_rounded, color: isDark ? Colors.white24 : AppColors.grey400, size: 20));

  Widget _ctrl(IconData icon, bool isDark, {double size = 24, bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: active ? const Color(0xFF1DB954) : (isDark ? Colors.white70 : AppColors.grey600), size: size),
    );
  }

  Widget _connectCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D1A) : const Color(0xFFF0F2EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFF1DB954).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.headphones_rounded, color: Color(0xFF1DB954), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TACTICAL AUDIO', style: AppTypography.labelBold.copyWith(color: isDark ? Colors.white : AppColors.grey900, letterSpacing: 1.5, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Connect Spotify to fuel your sessions', style: AppTypography.caption.copyWith(color: isDark ? Colors.white38 : AppColors.grey500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(musicControllerProvider.notifier).connectWithAuth(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(12)),
                child: Text('CONNECT', style: AppTypography.labelBold.copyWith(color: Colors.white, fontSize: 11, letterSpacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _idleCard(bool isDark, List playlists) {
    return GestureDetector(
      onTap: () => MusicCommandCenterSheet.show(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D1A) : const Color(0xFFF0F2EF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFF1DB954).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.headphones_rounded, color: Color(0xFF1DB954), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('READY TO PLAY', style: AppTypography.labelBold.copyWith(color: isDark ? Colors.white : AppColors.grey900, letterSpacing: 1.2, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Tap a playlist below to start', style: AppTypography.caption.copyWith(color: isDark ? Colors.white38 : AppColors.grey500)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppColors.grey400),
                ],
              ),
              if (playlists.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: playlists.length > 5 ? 5 : playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final p = playlists[i];
                      return GestureDetector(
                        onTap: () => ref.read(musicControllerProvider.notifier).playPlaylist(p.uri),
                        child: Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _thumbPlaceholder(isDark))
                                : _thumbPlaceholder(isDark),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
