import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/player_controller.dart';
import '../core/utils/extensions.dart';
import '../core/utils/helpers.dart';
import '../data/models/song_model.dart';
import 'song_artwork.dart';

const double kGlobalMiniPlayerHeight = 88;

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({
    super.key,
    required this.song,
    required this.controller,
    required this.onOpen,
  });

  final SongModel song;
  final PlayerController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isPlaying = controller.isPlaying.value;
      final Duration total = controller.total.value;
      final Duration position = controller.position.value;
      final double progress = total.inMilliseconds <= 0
          ? 0
          : (position.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onOpen,
          child: Ink(
            height: kGlobalMiniPlayerHeight,
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              boxShadow: AppHelpers.glowShadows(context),
            ),
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SongArtwork(
                      songId: song.artworkId,
                      artworkUri: song.artworkUri,
                      width: 58,
                      height: 58,
                      borderRadius: BorderRadius.circular(20),
                      size: 160,
                      quality: 50,
                      fallback: SongArtworkPlaceholder(
                        width: 58,
                        height: 58,
                        borderRadius: BorderRadius.circular(20),
                        gradientColors: <Color>[
                          context.colors.primary,
                          context.colors.tertiary,
                          context.colors.secondary,
                        ],
                        icon: Icons.graphic_eq_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            song.title.ellipsis(28),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist.fallbackArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.60),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: controller.togglePlayback,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.secondary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.next,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: progress,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
