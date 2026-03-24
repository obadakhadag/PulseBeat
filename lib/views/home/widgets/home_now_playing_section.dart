import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/player_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/song_model.dart';
import '../../../widgets/song_artwork.dart';

const double _kNowPlayingCardRadius = 28;

class HomeNowPlayingSection extends StatelessWidget {
  const HomeNowPlayingSection({
    super.key,
    required this.controller,
    required this.playerController,
  });

  final HomeController controller;
  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Obx(() {
        final SongModel? song = playerController.currentSong.value;
        final bool hasSong = song != null;
        final BorderRadius cardRadius = BorderRadius.circular(
          _kNowPlayingCardRadius,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: cardRadius,
            onTap: hasSong ? controller.openPlayerIfAvailable : null,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: cardRadius,
                boxShadow: AppHelpers.glowShadows(context),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    context.colors.primary.withValues(alpha: 0.88),
                    context.colors.tertiary.withValues(alpha: 0.86),
                    context.colors.secondary.withValues(alpha: 0.84),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 360;
                  final double artworkSize = compact ? 74 : 84;
                  final EdgeInsets contentPadding = EdgeInsets.all(
                    compact ? 14 : 16,
                  );
                  final String title = song?.title ?? 'No song playing'.tr;
                  final String subtitle = hasSong
                      ? song.artist.fallbackArtist
                      : 'Tap play on any song to start listening.'.tr;

                  return ClipRRect(
                    borderRadius: cardRadius,
                    child: Stack(
                      children: <Widget>[
                        if (hasSong)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.10,
                                child: SongArtwork(
                                  songId: song.artworkId,
                                  artworkUri: song.artworkUri,
                                  width: constraints.maxWidth,
                                  height: compact ? 150 : 160,
                                  borderRadius: cardRadius,
                                  size: 720,
                                  quality: 80,
                                  fallback: const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Colors.black.withValues(alpha: 0.06),
                                  Colors.black.withValues(alpha: 0.16),
                                  Colors.black.withValues(alpha: 0.28),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: compact ? 144 : 154,
                          ),
                          child: Padding(
                            padding: contentPadding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    _NowPlayingBadge(
                                      label: hasSong
                                          ? playerController.playbackLabel
                                          : 'No song playing'.tr,
                                    ),
                                    const Spacer(),
                                    if (hasSong)
                                      _NowPlayingFavoriteButton(
                                        controller: controller,
                                        song: song,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _NowPlayingArtwork(
                                      song: song,
                                      size: artworkSize,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.08,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            maxLines: compact ? 2 : 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.82),
                                                ),
                                          ),
                                          if (hasSong) ...<Widget>[
                                            const SizedBox(height: 10),
                                            _NowPlayingControlsRow(
                                              playerController:
                                                  playerController,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NowPlayingArtwork extends StatelessWidget {
  const _NowPlayingArtwork({required this.song, required this.size});

  final SongModel? song;
  final double size;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(22);
    final Widget fallback = SongArtworkPlaceholder(
      width: size,
      height: size,
      borderRadius: borderRadius,
      icon: Icons.graphic_eq_rounded,
    );

    final SongModel? currentSong = song;
    if (currentSong == null) {
      return fallback;
    }

    return SongArtwork(
      songId: currentSong.artworkId,
      artworkUri: currentSong.artworkUri,
      width: size,
      height: size,
      borderRadius: borderRadius,
      size: 260,
      quality: 78,
      fallback: fallback,
    );
  }
}

class _NowPlayingBadge extends StatelessWidget {
  const _NowPlayingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NowPlayingFavoriteButton extends StatelessWidget {
  const _NowPlayingFavoriteButton({
    required this.controller,
    required this.song,
  });

  final HomeController controller;
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isFavorite = controller.favoriteIds.contains(song.id);

      return IconButton(
        tooltip: isFavorite ? 'Favorites'.tr : 'Save'.tr,
        onPressed: () => controller.toggleFavorite(song),
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
        ),
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
        ),
      );
    });
  }
}

class _NowPlayingControlsRow extends StatelessWidget {
  const _NowPlayingControlsRow({required this.playerController});

  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isPlaying = playerController.isPlaying.value;
      final bool isBuffering = playerController.isBuffering.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _CompactTransportButton(
            tooltip: 'Back'.tr,
            icon: Icons.skip_previous_rounded,
            onPressed: playerController.previous,
          ),
          const SizedBox(width: 8),
          _CompactPrimaryButton(
            tooltip: isBuffering
                ? 'Buffering'.tr
                : isPlaying
                ? 'Pause'.tr
                : 'Play'.tr,
            icon: isBuffering
                ? Icons.hourglass_top_rounded
                : isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            onPressed: playerController.togglePlayback,
          ),
          const SizedBox(width: 8),
          _CompactTransportButton(
            tooltip: 'Next'.tr,
            icon: Icons.skip_next_rounded,
            onPressed: playerController.next,
          ),
        ],
      );
    });
  }
}

class _CompactTransportButton extends StatelessWidget {
  const _CompactTransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

class _CompactPrimaryButton extends StatelessWidget {
  const _CompactPrimaryButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 24),
    );
  }
}
