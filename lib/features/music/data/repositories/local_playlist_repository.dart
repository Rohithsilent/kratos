import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workout_playlist.dart';
import '../datasources/curated_music_library.dart';

final localPlaylistRepositoryProvider = Provider<LocalPlaylistRepository>((ref) {
  return LocalPlaylistRepository();
});

class LocalPlaylistRepository {
  static const String _playlistsKey = 'kratos_playlists_db';
  static const String _isInitializedKey = 'kratos_playlists_initialized';

  Future<void> initializeDefaultPlaylistsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_isInitializedKey) ?? false;
    
    if (!isInitialized) {
      // Seed the database with defaults
      final defaults = CuratedMusicLibrary.categorizedCuratedMixes;
      await saveAllCategorizedPlaylists(defaults);
      await prefs.setBool(_isInitializedKey, true);
    }
  }

  Future<Map<String, List<WorkoutPlaylist>>> getAllCategorizedPlaylists() async {
    await initializeDefaultPlaylistsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_playlistsKey);
    
    if (jsonString == null) return {};
    
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    
    final Map<String, List<WorkoutPlaylist>> result = {};
    for (final entry in map.entries) {
      final list = entry.value as List;
      result[entry.key] = list.map((item) => WorkoutPlaylist.fromMap(item as Map<String, dynamic>)).toList();
    }
    
    return result;
  }

  Future<void> saveAllCategorizedPlaylists(Map<String, List<WorkoutPlaylist>> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> jsonMap = {};
    for (final entry in data.entries) {
      jsonMap[entry.key] = entry.value.map((p) => p.toMap()).toList();
    }
    
    await prefs.setString(_playlistsKey, jsonEncode(jsonMap));
  }

  Future<void> saveImportedPlaylist(WorkoutPlaylist playlist) async {
    final allPlaylists = await getAllCategorizedPlaylists();
    
    // Add to 'IMPORTED PROTOCOLS' category
    const category = 'IMPORTED PROTOCOLS';
    if (!allPlaylists.containsKey(category)) {
      // Insert at the top of the map
      final newMap = <String, List<WorkoutPlaylist>>{
        category: [playlist]
      };
      newMap.addAll(allPlaylists);
      await saveAllCategorizedPlaylists(newMap);
      return;
    }
    
    final currentImported = allPlaylists[category]!;
    final existingIndex = currentImported.indexWhere((p) => p.id == playlist.id);
    if (existingIndex >= 0) {
      currentImported[existingIndex] = playlist;
    } else {
      currentImported.add(playlist);
    }
    
    await saveAllCategorizedPlaylists(allPlaylists);
  }

  Future<void> deletePlaylist(String category, String id) async {
    final allPlaylists = await getAllCategorizedPlaylists();
    
    if (allPlaylists.containsKey(category)) {
      allPlaylists[category]!.removeWhere((p) => p.id == id);
      
      if (allPlaylists[category]!.isEmpty && category == 'IMPORTED PROTOCOLS') {
         allPlaylists.remove(category);
      }
      
      await saveAllCategorizedPlaylists(allPlaylists);
    }
  }
}
