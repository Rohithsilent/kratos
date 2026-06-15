import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/music_controller.dart';
import '../controllers/playlists_controller.dart';
import '../widgets/tactical_playlist_card.dart';
import '../../domain/models/workout_playlist.dart';

class MusicCommandCenterScreen extends ConsumerStatefulWidget {
  const MusicCommandCenterScreen({super.key});

  @override
  ConsumerState<MusicCommandCenterScreen> createState() => _MusicCommandCenterScreenState();
}

class _MusicCommandCenterScreenState extends ConsumerState<MusicCommandCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistsControllerProvider.notifier).fetchPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistsControllerProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AUDIO COMMAND',
          style: AppTypography.labelBold.copyWith(
            color: context.colors.primary,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_link, color: context.colors.primary),
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: playlistState.isLoading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tactical Music Library',
                          style: AppTypography.displaySmall.copyWith(color: context.colors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
                // Subtle error message for Spotify failures
                if (playlistState.error != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: context.colors.onSurface.withValues(alpha: 0.54), size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                playlistState.error!.contains('Spotify Premium')
                                    ? 'Spotify Premium is required for personal playlists. Tactical mixes are fully available.'
                                    : playlistState.error!,
                                style: AppTypography.bodySmall.copyWith(color: context.colors.onSurface.withValues(alpha: 0.54), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                

                // Categorized Curated Mixes & Imported Playlists
                ...playlistState.categorizedCuratedMixes.entries.map((entry) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildSectionHeader(
                              entry.key == 'IMPORTED PROTOCOLS' ? 'IMPORTED PLAYLISTS' : entry.key,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: entry.value.length,
                              itemBuilder: (context, index) {
                                final playlist = entry.value[index];
                                return TacticalPlaylistCard(
                                  playlist: playlist,
                                  onTap: () {
                                    ref.read(musicControllerProvider.notifier).playPlaylist(playlist.uri);
                                  },
                                  onLongPress: () {
                                    _showDeleteConfirmationDialog(context, entry.key, playlist);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // User Spotify Playlists (if available)
                if (playlistState.userPlaylists.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildSectionHeader('YOUR PROTOCOLS'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: playlistState.userPlaylists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlistState.userPlaylists[index];
                                return TacticalPlaylistCard(
                                  playlist: playlist,
                                  onTap: () {
                                    ref.read(musicControllerProvider.notifier).playPlaylist(playlist.uri);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 64)),
              ],
            ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curvedAnimation),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.colors.primary.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: context.glow.redGlowSubtle,
                          blurRadius: 50,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Column(
                          children: [
                            Text(
                              'IMPORT PLAYLIST',
                              style: AppTypography.displaySmall.copyWith(
                                color: context.colors.onSurface,
                                fontSize: 24,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(width: 48, height: 2, color: context.colors.primary),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: context.colors.primary.withOpacity(0.8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Make sure the Spotify playlist is public to allow tactical syncing.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: context.colors.onSurface.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Input Field
                        TextField(
                          controller: controller,
                          style: TextStyle(color: context.colors.onSurface),
                          cursorColor: context.colors.primary,
                          decoration: InputDecoration(
                            hintText: 'https://open.spotify.com/playlist/...',
                            hintStyle: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25)),
                            filled: true,
                            fillColor: context.colors.onSurface.withValues(alpha: 0.05),
                            prefixIcon: Icon(Icons.link, color: context.colors.onSurface.withValues(alpha: 0.30)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.10)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.10)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: context.colors.onSurface.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.10)),
                                  ),
                                ),
                                child: Text('CANCEL', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.54))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final url = controller.text.trim();
                                  if (url.isNotEmpty) {
                                    ref.read(playlistsControllerProvider.notifier).importPlaylistFromUrl(url).catchError((e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
                                      }
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 8,
                                  shadowColor: context.colors.primary.withOpacity(0.4),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [context.colors.primary, context.colors.primary.withOpacity(0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text('IMPORT', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String category, WorkoutPlaylist playlist) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curvedAnimation),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.colors.primary.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: context.glow.redGlowSubtle,
                          blurRadius: 40,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: context.colors.primary, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'DELETE PLAYLIST',
                          style: AppTypography.displaySmall.copyWith(
                            color: context.colors.onSurface,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Are you sure you want to permanently delete "${playlist.name}" from your library?',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.onSurface.withValues(alpha: 0.70),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: context.colors.onSurface.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.10)),
                                  ),
                                ),
                                child: Text('CANCEL', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.54))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(playlistsControllerProvider.notifier).deletePlaylist(category, playlist.id);
                                  Navigator.pop(context);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Playlist deleted.'),
                                        backgroundColor: context.colors.surface,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: context.colors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('DELETE', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          color: context.colors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelBold.copyWith(
            color: context.colors.onSurface,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
