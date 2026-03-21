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
    final HomeController controller = Get.find<HomeController>();

    return RepaintBoundary(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                SongArtwork(
                  songId: song.artworkId,
                  width: 66,
                  height: 66,
                  borderRadius: BorderRadius.circular(20),
                  size: 128,
                  quality: 40,
                  fallback: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          context.colors.primary.withValues(alpha: 0.95),
                          context.colors.secondary.withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title.ellipsis(32),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle ??
                            '${song.artist.fallbackArtist} - ${song.album.ellipsis(18)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.onSurface.withValues(
                            alpha: 0.60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
                          color: controller.isFavorite(song.id)
                              ? context.colors.tertiary
                              : context.colors.onSurface.withValues(
                                  alpha: 0.70,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trailingLabel ?? song.duration.toClock(),
                      style: context.theme.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.60),
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
