import '../../domain/models/workout_playlist.dart';

class CuratedMusicLibrary {
  static final Map<String, List<WorkoutPlaylist>> categorizedCuratedMixes = {
    'BEAST MODE': [
      WorkoutPlaylist(
        id: 'beast_mode_2',
        name: 'PHONK TRAINING',
        uri: 'spotify:playlist:37i9dQZF1DWWY64CwZNa3i',
        imageUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800&auto=format&fit=crop',
        trackCount: 50,
        mood: 'Aggressive',
        energyLevel: 'High',
        duration: '2h 15m',
        category: 'BEAST MODE',
        bpmRange: '120-140',
        difficulty: 'Intermediate',
      ),

      WorkoutPlaylist(
        id: 'beast_mode_3',
        name: 'USER PHONK MIX',
        uri: 'spotify:playlist:37i9dQZF1DWWY64wDtewQt',
        imageUrl:
            'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=800&auto=format&fit=crop',
        trackCount: 80,
        mood: 'Aggressive',
        energyLevel: 'Max',
        duration: '3h 40m',
        category: 'BEAST MODE',
        bpmRange: '130-150',
        difficulty: 'Advanced',
      ),

      WorkoutPlaylist(
        id: 'beast_mode_1',
        name: 'HEAVY METAL LIFTING',
        uri: 'spotify:playlist:37i9dQZF1DX9qNs32fujYe',
        imageUrl:
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800&auto=format&fit=crop',
        trackCount: 100,
        mood: 'Aggressive',
        energyLevel: 'Max',
        duration: '6h 12m',
        category: 'BEAST MODE',
        bpmRange: '130-160',
        difficulty: 'Advanced',
      ),
    ],
    'CARDIO SPRINT': [
      WorkoutPlaylist(
        id: 'cardio_1',
        name: 'RUNNING TEMPO',
        uri: 'spotify:playlist:37i9dQZF1DWXRqgorJj26U',
        imageUrl:
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=800&auto=format&fit=crop',
        trackCount: 75,
        mood: 'Endurance',
        energyLevel: 'High',
        duration: '3h 45m',
        category: 'CARDIO SPRINT',
        bpmRange: '160-180',
        difficulty: 'All Levels',
      ),
      WorkoutPlaylist(
        id: 'cardio_2',
        name: 'HIIT BEATS',
        uri: 'spotify:playlist:37i9dQZF1DX0HRj9P7NxeE',
        imageUrl:
            'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=800&auto=format&fit=crop',
        trackCount: 45,
        mood: 'Energetic',
        energyLevel: 'Max',
        duration: '2h 10m',
        category: 'CARDIO SPRINT',
        bpmRange: '140-150',
        difficulty: 'Advanced',
      ),
    ],
    'FOCUS ZONE': [
      WorkoutPlaylist(
        id: 'focus_1',
        name: 'SYNTHWAVE CYBERPUNK',
        uri: 'spotify:playlist:37i9dQZF1DXdLEN7aqioJC',
        imageUrl:
            'https://images.unsplash.com/photo-1554244933-d876deb6b2ff?q=80&w=800&auto=format&fit=crop',
        trackCount: 60,
        mood: 'Tactical Focus',
        energyLevel: 'Medium',
        duration: '3h 20m',
        category: 'FOCUS ZONE',
        bpmRange: '100-120',
        difficulty: 'All Levels',
      ),
    ],
    'RECOVERY FLOW': [
      WorkoutPlaylist(
        id: 'recovery_1',
        name: 'YOGA & MOBILITY',
        uri: 'spotify:playlist:37i9dQZF1DX9uKNf5jGX6m',
        imageUrl:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
        trackCount: 80,
        mood: 'Recovery',
        energyLevel: 'Low',
        duration: '4h 15m',
        category: 'RECOVERY FLOW',
        bpmRange: '60-90',
        difficulty: 'Beginner',
      ),
    ],
  };

  static List<WorkoutPlaylist> get flatCuratedMixes {
    return categorizedCuratedMixes.values.expand((list) => list).toList();
  }
}
