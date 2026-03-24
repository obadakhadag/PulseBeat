import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/player_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/song_model.dart';
import '../../../widgets/main_section_scaffold.dart';
import '../../../widgets/song_artwork.dart';

const double kHomeMiniPlayerHeight = 88;
const double kHomeMiniPlayerBottom =
    kMainSectionFloatingNavBottom + kMainSectionFloatingNavHeight + 16;

class HomeMiniPlayer extends StatelessWidget {
  const HomeMiniPlayer({
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

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onOpen,
          child: Ink(
            height: kHomeMiniPlayerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              boxShadow: AppHelpers.glowShadows(context),
            ),
            child: Row(
              children: <Widget>[
                SongArtwork(
                  songId: song.artworkId,
                  width: 58,
                  height: 58,
                  borderRadius: BorderRadius.circular(20),
                  size: 160,
                  quality: 50,
                  fallback: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          context.colors.primary,
                          context.colors.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        song.title.ellipsis(26),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.previous,
                  icon: const Icon(Icons.skip_previous_rounded),
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
          ),
        ),
      );
    });
  }
}
