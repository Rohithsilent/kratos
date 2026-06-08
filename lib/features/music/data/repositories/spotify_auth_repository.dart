import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final spotifyAuthRepositoryProvider = Provider<SpotifyAuthRepository>((ref) {
  return SpotifyAuthRepository();
});

class SpotifyAuthRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  static const String _tokenKey = 'spotify_access_token';
  static const String _expirationKey = 'spotify_token_expiration';

  /// Saves the access token and sets an expiration time
  /// Spotify tokens usually expire in 1 hour (3600 seconds)
  Future<void> saveToken(String token, {int expiresInSeconds = 3600}) async {
    try {
      final expirationTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _expirationKey, value: expirationTime.toIso8601String());
      _logger.i('Spotify token saved securely. Expires: $expirationTime');
    } catch (e) {
      _logger.e('Failed to securely save Spotify token: $e');
    }
  }

  /// Retrieves the access token if it exists and is not expired.
  /// Returns null if missing or expired.
  Future<String?> getValidToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final expirationStr = await _secureStorage.read(key: _expirationKey);

      if (token == null || expirationStr == null) {
        return null; // No token found
      }

      final expirationTime = DateTime.tryParse(expirationStr);
      if (expirationTime == null || DateTime.now().isAfter(expirationTime)) {
        _logger.w('Spotify token has expired. Needs refresh.');
        await clearToken(); // Clear expired token
        return null;
      }

      return token;
    } catch (e) {
      _logger.e('Failed to retrieve Spotify token: $e');
      return null;
    }
  }

  /// Clears the stored token from secure storage
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _expirationKey);
      _logger.i('Spotify token cleared from secure storage.');
    } catch (e) {
      _logger.e('Failed to clear Spotify token: $e');
    }
  }
}
