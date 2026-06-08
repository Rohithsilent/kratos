class SpotifyTrack {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String albumImageUrl;
  final String uri;
  final int durationMs;
  final bool isPlayable;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    required this.albumImageUrl,
    required this.uri,
    required this.durationMs,
    this.isPlayable = true,
  });
}
