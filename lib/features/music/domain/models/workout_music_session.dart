class WorkoutMusicSession {
  final String id;
  final String workoutId;
  final String playlistUri;
  final String playlistName;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalDurationSeconds;
  final int tracksSkipped;

  WorkoutMusicSession({
    required this.id,
    required this.workoutId,
    required this.playlistUri,
    required this.playlistName,
    required this.startTime,
    this.endTime,
    this.totalDurationSeconds = 0,
    this.tracksSkipped = 0,
  });

  WorkoutMusicSession copyWith({
    String? id,
    String? workoutId,
    String? playlistUri,
    String? playlistName,
    DateTime? startTime,
    DateTime? endTime,
    int? totalDurationSeconds,
    int? tracksSkipped,
  }) {
    return WorkoutMusicSession(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      playlistUri: playlistUri ?? this.playlistUri,
      playlistName: playlistName ?? this.playlistName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      tracksSkipped: tracksSkipped ?? this.tracksSkipped,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'playlistUri': playlistUri,
      'playlistName': playlistName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDurationSeconds': totalDurationSeconds,
      'tracksSkipped': tracksSkipped,
    };
  }

  factory WorkoutMusicSession.fromMap(Map<String, dynamic> map) {
    return WorkoutMusicSession(
      id: map['id'] ?? '',
      workoutId: map['workoutId'] ?? '',
      playlistUri: map['playlistUri'] ?? '',
      playlistName: map['playlistName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      totalDurationSeconds: map['totalDurationSeconds'] ?? 0,
      tracksSkipped: map['tracksSkipped'] ?? 0,
    );
  }
}
