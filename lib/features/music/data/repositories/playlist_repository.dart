import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_playlist.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(FirebaseFirestore.instance);
});

class PlaylistRepository {
  final FirebaseFirestore _firestore;

  PlaylistRepository(this._firestore);

  CollectionReference get _playlists => _firestore.collection('workout_playlists');

  Future<void> savePlaylist(WorkoutPlaylist playlist) async {
    await _playlists.doc(playlist.id).set(playlist.toMap());
  }

  Future<WorkoutPlaylist?> getPlaylistForWorkout(String workoutId) async {
    final snapshot = await _playlists.where('workoutId', isEqualTo: workoutId).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return WorkoutPlaylist.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<WorkoutPlaylist>> getAllPlaylists() async {
    final snapshot = await _playlists.get();
    return snapshot.docs
        .map((doc) => WorkoutPlaylist.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
