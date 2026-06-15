import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/workout_playlist.dart';

class TacticalPlaylistCard extends StatelessWidget {
  final WorkoutPlaylist playlist;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TacticalPlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 240, // Wider for cinematic feel
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.glassmorphism.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : context.colors.onSurface.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Gradient Overlay and Chips
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: playlist.imageUrl.isNotEmpty
                        ? Image.network(
                            playlist.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black26,
                                child: Icon(Icons.music_note, color: context.colors.onSurface.withValues(alpha: 0.54), size: 40),
                              );
                            },
                          )
                        : Container(
                            color: Colors.black26,
                            child: Icon(Icons.music_note, color: context.colors.onSurface.withValues(alpha: 0.54), size: 40),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.colors.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  // Top Metadata Chips
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildChip('[ ${playlist.bpmRange} BPM ]', context.colors.primary),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildChip(playlist.difficulty.toUpperCase(), context.colors.onSurface.withValues(alpha: 0.54)),
                  ),
                ],
              ),
            ),
            // Text Details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name.toUpperCase(),
                    style: AppTypography.labelBold.copyWith(
                      color: context.colors.onSurface,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: context.colors.primary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${playlist.category} • ${playlist.duration}',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.onSurface.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
