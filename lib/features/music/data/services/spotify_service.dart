import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart' as spotify;
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:logger/logger.dart';

import '../repositories/spotify_auth_repository.dart';
import '../../domain/models/workout_playlist.dart';

final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  final authRepo = ref.watch(spotifyAuthRepositoryProvider);
  return SpotifyService(authRepo);
});

class SpotifyService {
  final SpotifyAuthRepository _authRepository;
  final Logger _logger = Logger();
  
  SpotifyService(this._authRepository);
  
  // TODO: Replace with real credentials, potentially from .env or Firebase Remote Config
  static const String _clientId = 'c9ee90b121804959a02d5bc4c12aab61';
  static const String _redirectUrl = 'kratos://callback'; 

  Future<bool> connectToSpotify() async {
    try {
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
      );
      _logger.i("Connected to Spotify: $result");
      return result;
    } on PlatformException catch (e) {
      _logger.e("Failed to connect to Spotify: ${e.message}");
      return false;
    } on MissingPluginException {
      _logger.e("Spotify SDK not implemented on this platform");
      return false;
    } catch (e) {
      _logger.e("Unknown error connecting to Spotify: $e");
      return false;
    }
  }

  Future<bool> connectToSpotifyWithAuth() async {
    try {
      // First, trigger the authentication flow to get a token
      var token = await SpotifySdk.getAccessToken(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        scope: 'app-remote-control, user-modify-playback-state, playlist-read-private, playlist-read-collaborative, user-read-recently-played',
      );

      // Save token securely
      await _authRepository.saveToken(token);

      // Then connect to the remote SDK using that token
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: _clientId,
        redirectUrl: _redirectUrl,
        accessToken: token,
      );
      return result;
    } catch (e) {
      _logger.e("Failed to connect with auth: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _authRepository.clearToken();
      await SpotifySdk.disconnect();
    } catch (e) {
      _logger.e("Error disconnecting: $e");
    }
  }

  // --- Web API Endpoints ---

  Future<List<WorkoutPlaylist>> getUserPlaylists() async {
    return _fetchPlaylists('https://api.spotify.com/v1/me/playlists?limit=20');
  }

  Future<List<WorkoutPlaylist>> getFeaturedPlaylists() async {
    return _fetchPlaylists('https://api.spotify.com/v1/browse/featured-playlists?limit=10', isNested: true);
  }

  Future<List<WorkoutPlaylist>> getRecentlyPlayed() async {
    return _fetchPlaylists('https://api.spotify.com/v1/me/player/recently-played?limit=10', isNested: true);
  }

  // Generic helper for fetching and parsing playlists
  Future<List<WorkoutPlaylist>> _fetchPlaylists(String url, {bool isNested = false}) async {
    try {
      var token = await _authRepository.getValidToken();
      if (token == null) {
        _logger.w('No valid token, attempting to get access token...');
        try {
          token = await SpotifySdk.getAccessToken(
            clientId: _clientId,
            redirectUrl: _redirectUrl,
            scope: 'app-remote-control, user-modify-playback-state, playlist-read-private, playlist-read-collaborative, user-read-recently-played',
          );
          if (token != null && token.isNotEmpty) {
            await _authRepository.saveToken(token);
          }
        } catch (e) {
          _logger.e('Failed to get access token: $e');
        }
      }
      
      if (token == null || token.isEmpty) {
        _logger.w('Cannot fetch playlists: No valid token available.');
        return [];
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = isNested ? data['playlists']['items'] as List : data['items'] as List;
        return items.map((item) => WorkoutPlaylist.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        _logger.e('Failed to fetch playlists: 403 - Premium required or app owner needs Premium.');
        throw Exception('Spotify Premium is required to sync personal and featured playlists.');
      } else {
        _logger.e('Failed to fetch playlists: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch playlists from Spotify.');
      }
    } catch (e) {
      _logger.e('Error fetching playlists: $e');
      rethrow;
    }
  }

  Future<WorkoutPlaylist> getPlaylistById(String playlistId) async {
    try {
      var token = await _authRepository.getValidToken();
      if (token == null) {
        throw Exception('Not authenticated with Spotify');
      }

      final url = 'https://api.spotify.com/v1/playlists/$playlistId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkoutPlaylist.fromJson(data);
      } else {
        _logger.w('Spotify API failed (${response.statusCode}). Attempting public scrape fallback...');
        return await _scrapePlaylistFallback(playlistId);
      }
    } catch (e) {
      _logger.w('Spotify API error: $e. Attempting public scrape fallback...');
      try {
        return await _scrapePlaylistFallback(playlistId);
      } catch (scrapeError) {
        _logger.e('Scrape fallback also failed: $scrapeError');
        throw Exception('Failed to fetch playlist details: $e');
      }
    }
  }

  Future<WorkoutPlaylist> _scrapePlaylistFallback(String playlistId) async {
    final url = 'https://open.spotify.com/playlist/$playlistId';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final html = response.body;
      
      final titleMatch = RegExp(r'<meta property="og:title" content="([^"]+)"').firstMatch(html);
      final imageMatch = RegExp(r'<meta property="og:image" content="([^"]+)"').firstMatch(html);
      final descMatch = RegExp(r'<meta name="description" content="([^"]+)"').firstMatch(html);
      
      final title = titleMatch?.group(1) ?? 'Imported Playlist';
      final imageUrl = imageMatch?.group(1) ?? '';
      final desc = descMatch?.group(1) ?? '';
      
      int parsedTrackCount = 0;
      final itemsMatch = RegExp(r'(\d+)\s+(items|songs|tracks)').firstMatch(desc);
      if (itemsMatch != null) {
        parsedTrackCount = int.tryParse(itemsMatch.group(1) ?? '0') ?? 0;
      }
      
      final durationStr = parsedTrackCount > 0 
          ? '${parsedTrackCount * 3 ~/ 60}h ${(parsedTrackCount * 3) % 60}m'
          : 'Unknown';

      return WorkoutPlaylist(
        id: playlistId,
        name: title.replaceAll('&#39;', "'").replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
        uri: 'spotify:playlist:$playlistId',
        imageUrl: imageUrl,
        trackCount: parsedTrackCount,
        platform: MusicPlatform.spotify,
        mood: 'Custom',
        energyLevel: 'Unknown',
        duration: durationStr,
        category: 'IMPORTED',
        bpmRange: 'Unknown',
        difficulty: 'All Levels',
      );
    } else {
      throw Exception('Could not access public Spotify URL');
    }
  }

  // --- Player Controls ---

  Stream<spotify.PlayerState> subscribeToPlayerState() {
    return SpotifySdk.subscribePlayerState();
  }

  Stream<ConnectionStatus> subscribeToConnectionStatus() {
    return SpotifySdk.subscribeConnectionStatus();
  }

  Future<void> play({required String spotifyUri}) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      _logger.e("Failed to play: $e");
    }
  }

  Future<void> pause() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      _logger.e("Failed to pause: $e");
    }
  }

  Future<void> resume() async {
    try {
      await SpotifySdk.resume();
    } catch (e) {
      _logger.e("Failed to resume: $e");
    }
  }

  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      _logger.e("Failed to skip next: $e");
    }
  }

  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      _logger.e("Failed to skip previous: $e");
    }
  }

  Future<void> seekTo({required int positionedMilliseconds}) async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: positionedMilliseconds);
    } catch (e) {
      _logger.e("Failed to seek: $e");
    }
  }

  Future<void> setShuffle(bool shuffle) async {
    try {
      await SpotifySdk.setShuffle(shuffle: shuffle);
    } catch (e) {
      _logger.e("Failed to set shuffle: $e");
    }
  }

  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    try {
      await SpotifySdk.setRepeatMode(repeatMode: repeatMode);
    } catch (e) {
      _logger.e("Failed to set repeat: $e");
    }
  }
}
