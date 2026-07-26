import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_sdk/models/player_state.dart' as spotify;
import '../../domain/entities/music_playback_state.dart';
import '../../domain/entities/spotify_track.dart';
import '../../data/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

final musicControllerProvider = NotifierProvider<MusicController, MusicPlaybackState>(() {
  return MusicController();
});

class MusicController extends Notifier<MusicPlaybackState> {
  late final SpotifyService _spotifyService;
  StreamSubscription<spotify.PlayerState>? _playerStateSubscription;
  StreamSubscription? _connectionSubscription;

  @override
  MusicPlaybackState build() {
    _spotifyService = ref.watch(spotifyServiceProvider);
    _initConnection();
    
    ref.onDispose(() {
      _playerStateSubscription?.cancel();
      _connectionSubscription?.cancel();
      _spotifyService.disconnect();
    });
    
    return const MusicPlaybackState();
  }

  Future<void> _initConnection() async {
    final isConnected = await _spotifyService.connectToSpotify();
    if (isConnected) {
      state = state.copyWith(isConnected: true, clearError: true);
      _subscribeToStreams();
    } else {
      state = state.copyWith(isConnected: false, error: 'Failed to connect to Spotify');
    }
  }

  Future<void> connectWithAuth() async {
    final isConnected = await _spotifyService.connectToSpotifyWithAuth();
    if (isConnected) {
      state = state.copyWith(isConnected: true, clearError: true);
      _subscribeToStreams();
    } else {
      state = state.copyWith(isConnected: false, error: 'Failed to authenticate with Spotify');
    }
  }

  void _subscribeToStreams() {
    _connectionSubscription?.cancel();
    _connectionSubscription = _spotifyService.subscribeToConnectionStatus().listen((status) {
      if (status.connected) {
        state = state.copyWith(isConnected: true, clearError: true);
      } else {
        state = state.copyWith(isConnected: false, error: status.errorDetails ?? 'Disconnected');
      }
    });

    _playerStateSubscription?.cancel();
    _playerStateSubscription = _spotifyService.subscribeToPlayerState().listen((spotify.PlayerState playerState) {
      final track = playerState.track;
      SpotifyTrack? currentTrack;
      if (track != null) {
        String imageUrl = track.imageUri.raw;
        if (imageUrl.startsWith('spotify:image:')) {
          imageUrl = imageUrl.replaceFirst('spotify:image:', 'https://i.scdn.co/image/');
        }

        currentTrack = SpotifyTrack(
          id: track.uri,
          name: track.name,
          artistName: track.artist.name ?? 'Unknown Artist',
          albumName: track.album.name ?? 'Unknown Album',
          albumImageUrl: imageUrl,
          uri: track.uri,
          durationMs: track.duration,
          isPlayable: true,
        );
      }

      state = state.copyWith(
        currentTrack: currentTrack,
        isPlaying: !playerState.isPaused,
        progressMs: playerState.playbackPosition,
        shuffle: playerState.playbackOptions.isShuffling,
        repeat: playerState.playbackOptions.repeatMode.index != RepeatMode.off.index,
      );
    });
  }

  Future<void> playPlaylist(String uri) async {
    if (!state.isConnected) {
      await connectWithAuth();
    }
    state = state.copyWith(currentPlaylistUri: uri);
    await _spotifyService.play(spotifyUri: uri);
  }

  Future<void> play() async {
    await _spotifyService.resume();
  }

  Future<void> pause() async {
    await _spotifyService.pause();
  }

  Future<void> next() async {
    await _spotifyService.skipNext();
  }

  Future<void> previous() async {
    await _spotifyService.skipPrevious();
  }

  Future<void> toggleShuffle() async {
    await _spotifyService.setShuffle(!state.shuffle);
  }

  Future<void> toggleRepeat() async {
    final newMode = state.repeat ? RepeatMode.off : RepeatMode.track;
    try {
      await _spotifyService.setRepeatMode(newMode);
    } catch (e) {
      // Fallback for non-premium users who get CANT_PLAY_ON_DEMAND
      if (newMode == RepeatMode.track) {
        try {
          await _spotifyService.setRepeatMode(RepeatMode.context);
        } catch (_) {}
      }
    }
  }
}
