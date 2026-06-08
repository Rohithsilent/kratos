import 'spotify_track.dart';

class MusicPlaybackState {
  final SpotifyTrack? currentTrack;
  final String? currentPlaylistUri;
  final bool isPlaying;
  final int progressMs;
  final bool isConnected;
  final String? error;
  final bool isBuffering;
  final bool shuffle;
  final bool repeat;

  const MusicPlaybackState({
    this.currentTrack,
    this.currentPlaylistUri,
    this.isPlaying = false,
    this.progressMs = 0,
    this.isConnected = false,
    this.error,
    this.isBuffering = false,
    this.shuffle = false,
    this.repeat = false,
  });

  MusicPlaybackState copyWith({
    SpotifyTrack? currentTrack,
    String? currentPlaylistUri,
    bool? isPlaying,
    int? progressMs,
    bool? isConnected,
    String? error,
    bool? isBuffering,
    bool? shuffle,
    bool? repeat,
    bool clearError = false,
  }) {
    return MusicPlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      currentPlaylistUri: currentPlaylistUri ?? this.currentPlaylistUri,
      isPlaying: isPlaying ?? this.isPlaying,
      progressMs: progressMs ?? this.progressMs,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
      isBuffering: isBuffering ?? this.isBuffering,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
    );
  }
}
