class WorkoutPlaylist {
  final String id;
  final String playlistName;
  final String? workoutId;
  final String moodType;
  final String spotifyUri;

  const WorkoutPlaylist({
    required this.id,
    required this.playlistName,
    this.workoutId,
    required this.moodType,
    required this.spotifyUri,
  });

  factory WorkoutPlaylist.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutPlaylist(
      id: id,
      playlistName: map['playlistName'] ?? '',
      workoutId: map['workoutId'],
      moodType: map['moodType'] ?? 'unspecified',
      spotifyUri: map['spotifyUri'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playlistName': playlistName,
      'workoutId': workoutId,
      'moodType': moodType,
      'spotifyUri': spotifyUri,
    };
  }
}
