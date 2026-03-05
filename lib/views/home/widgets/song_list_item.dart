import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/song_model.dart';
import '../../../widgets/song_artwork.dart';

class SongListItem extends StatelessWidget {
  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoriteToggle,
    this.subtitle,
    this.trailingLabel,
  });

  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final String? subtitle;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(
                alpha: context.theme.brightness == Brightness.dark
                    ? 0.58
                    : 0.75,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: <Widget>[
                SongArtwork(
                  songId: song.artworkId,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(18),
                  size: 96,
                  quality: 35,
                  fallback: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.music_note_rounded),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title.ellipsis(30),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ??
                            '${song.artist.fallbackArtist} - ${song.album.ellipsis(16)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Obx(
                      () => IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          controller.isFavorite(song.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                      ),
                    ),
                    Text(
                      song.duration.toClock(),
                      style: context.theme.textTheme.labelMedium,
                    ),
                    if (trailingLabel != null)
                      Text(
                        trailingLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
