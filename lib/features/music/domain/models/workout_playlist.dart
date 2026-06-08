enum MusicPlatform {
  spotify,
  appleMusic,
  youtubeMusic,
  local,
}

class WorkoutPlaylist {
  final String id;
  final String name;
  final String uri;
  final String imageUrl;
  final int trackCount;
  final MusicPlatform platform;
  
  // Tactical UI Properties
  final String mood; 
  final String energyLevel;
  final String duration; 
  final String category;
  final String bpmRange;
  final String difficulty;

  WorkoutPlaylist({
    required this.id,
    required this.name,
    required this.uri,
    required this.imageUrl,
    required this.trackCount,
    this.platform = MusicPlatform.spotify,
    this.mood = 'Focus',
    this.energyLevel = 'High',
    this.duration = '1h 30m',
    this.category = 'Tactical',
    this.bpmRange = '120-140',
    this.difficulty = 'All Levels',
  });

  factory WorkoutPlaylist.fromJson(Map<String, dynamic> json) {
    String extractImageUrl(Map<String, dynamic> data) {
      if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
        return data['images'][0]['url'] ?? '';
      }
      return '';
    }

    return WorkoutPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Playlist',
      uri: json['uri'] ?? '',
      imageUrl: extractImageUrl(json),
      trackCount: json['tracks'] != null ? json['tracks']['total'] ?? 0 : 0,
      platform: MusicPlatform.spotify,
      mood: _deriveMood(json['name'] ?? ''),
      energyLevel: _deriveEnergy(json['name'] ?? ''),
      duration: '${(json['tracks']?['total'] ?? 0) * 3 ~/ 60}h ${((json['tracks']?['total'] ?? 0) * 3) % 60}m',
      category: 'Generated',
      bpmRange: 'Unknown',
      difficulty: 'All Levels',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'uri': uri,
      'imageUrl': imageUrl,
      'trackCount': trackCount,
      'platform': platform.name,
      'mood': mood,
      'energyLevel': energyLevel,
      'duration': duration,
      'category': category,
      'bpmRange': bpmRange,
      'difficulty': difficulty,
    };
  }

  factory WorkoutPlaylist.fromMap(Map<String, dynamic> map) {
    return WorkoutPlaylist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      uri: map['uri'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      trackCount: map['trackCount']?.toInt() ?? 0,
      platform: MusicPlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => MusicPlatform.spotify,
      ),
      mood: map['mood'] ?? 'Focus',
      energyLevel: map['energyLevel'] ?? 'High',
      duration: map['duration'] ?? '1h 30m',
      category: map['category'] ?? 'Tactical',
      bpmRange: map['bpmRange'] ?? '120-140',
      difficulty: map['difficulty'] ?? 'All Levels',
    );
  }

  static String _deriveMood(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('push') || lowerName.contains('heavy') || lowerName.contains('metal')) return 'Aggressive';
    if (lowerName.contains('cardio') || lowerName.contains('sprint') || lowerName.contains('run')) return 'Endurance';
    if (lowerName.contains('recover') || lowerName.contains('lo-fi') || lowerName.contains('chill')) return 'Recovery';
    return 'Tactical Focus';
  }

  static String _deriveEnergy(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('recover') || lowerName.contains('chill')) return 'Low';
    if (lowerName.contains('focus') || lowerName.contains('flow')) return 'Medium';
    return 'High';
  }
}
