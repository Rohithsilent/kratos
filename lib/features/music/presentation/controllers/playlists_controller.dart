import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/spotify_service.dart';
import '../../domain/models/workout_playlist.dart';
import '../../data/datasources/curated_music_library.dart';
import '../../data/repositories/local_playlist_repository.dart';

class PlaylistsState {
  final List<WorkoutPlaylist> userPlaylists;
  final List<WorkoutPlaylist> featuredPlaylists;
  final Map<String, List<WorkoutPlaylist>> categorizedCuratedMixes;
  final bool isLoading;
  final String? error;

  PlaylistsState({
    this.userPlaylists = const [],
    this.featuredPlaylists = const [],
    this.categorizedCuratedMixes = const {},
    this.isLoading = false,
    this.error,
  });

  PlaylistsState copyWith({
    List<WorkoutPlaylist>? userPlaylists,
    List<WorkoutPlaylist>? featuredPlaylists,
    Map<String, List<WorkoutPlaylist>>? categorizedCuratedMixes,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistsState(
      userPlaylists: userPlaylists ?? this.userPlaylists,
      featuredPlaylists: featuredPlaylists ?? this.featuredPlaylists,
      categorizedCuratedMixes: categorizedCuratedMixes ?? this.categorizedCuratedMixes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final playlistsControllerProvider = NotifierProvider<PlaylistsController, PlaylistsState>(() {
  return PlaylistsController();
});

class PlaylistsController extends Notifier<PlaylistsState> {
  late final SpotifyService _spotifyService;
  late final LocalPlaylistRepository _localPlaylistRepository;

  @override
  PlaylistsState build() {
    _spotifyService = ref.watch(spotifyServiceProvider);
    _localPlaylistRepository = ref.watch(localPlaylistRepositoryProvider);
    
    return PlaylistsState();
  }

  Future<void> fetchPlaylists() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categorizedMixes = await _localPlaylistRepository.getAllCategorizedPlaylists();
      
      final userPlaylists = await _spotifyService.getUserPlaylists();
      final featuredPlaylists = await _spotifyService.getFeaturedPlaylists();
      
      state = state.copyWith(
        userPlaylists: userPlaylists,
        featuredPlaylists: featuredPlaylists,
        categorizedCuratedMixes: categorizedMixes,
        isLoading: false,
      );
    } catch (e) {
      // Even if Spotify fails, load the local ones
      final categorizedMixes = await _localPlaylistRepository.getAllCategorizedPlaylists();
      state = state.copyWith(
        isLoading: false,
        categorizedCuratedMixes: categorizedMixes,
        error: 'Failed to load playlists: $e',
      );
    }
  }

  Future<void> importPlaylistFromUrl(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final regex = RegExp(r'playlist\/([a-zA-Z0-9]+)');
      final match = regex.firstMatch(url);
      
      if (match != null && match.groupCount >= 1) {
        final playlistId = match.group(1)!;
        
        final playlist = await _spotifyService.getPlaylistById(playlistId);
        await _localPlaylistRepository.saveImportedPlaylist(playlist);
        
        // Refresh local playlists
        final categorizedMixes = await _localPlaylistRepository.getAllCategorizedPlaylists();
        state = state.copyWith(
          categorizedCuratedMixes: categorizedMixes,
          isLoading: false,
        );
      } else {
        throw Exception('Invalid Spotify Playlist URL');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import playlist: $e',
      );
      rethrow;
    }
  }

  Future<void> deletePlaylist(String category, String playlistId) async {
    try {
      await _localPlaylistRepository.deletePlaylist(category, playlistId);
      final categorizedMixes = await _localPlaylistRepository.getAllCategorizedPlaylists();
      state = state.copyWith(
        categorizedCuratedMixes: categorizedMixes,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete playlist: $e');
    }
  }
}

