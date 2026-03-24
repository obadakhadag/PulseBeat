import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/player_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/song_model.dart';
import '../../../widgets/song_artwork.dart';

const double _kNowPlayingCardRadius = 30;

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
        final bool isPlaying = playerController.isPlaying.value;
        final bool isBuffering = playerController.isBuffering.value;
        final bool hasSong = song != null;
        final String title = song?.title ?? 'No song playing'.tr;
        final String subtitle = hasSong
            ? song.artist.fallbackArtist
            : 'Tap play on any song to start listening.'.tr;
        final String helperText = hasSong
            ? 'Current playback is always synced from the active player state.'
                  .tr
            : 'Tap play on any song to start listening.'.tr;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_kNowPlayingCardRadius),
            onTap: hasSong ? controller.openPlayerIfAvailable : null,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kNowPlayingCardRadius),
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
                  final double artworkSize = compact ? 92 : 108;
                  final BorderRadius cardRadius = BorderRadius.circular(
                    _kNowPlayingCardRadius,
                  );

                  return ClipRRect(
                    borderRadius: cardRadius,
                    child: Stack(
                      children: <Widget>[
                        if (hasSong)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.14,
                                child: SongArtwork(
                                  songId: song.artworkId,
                                  artworkUri: song.artworkUri,
                                  width: constraints.maxWidth,
                                  height: 220,
                                  borderRadius: cardRadius,
                                  size: 900,
                                  quality: 85,
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
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.black.withValues(alpha: 0.34),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: compact ? 188 : 204,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 16 : 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _NowPlayingArtwork(
                                  song: song,
                                  size: artworkSize,
                                ),
                                SizedBox(width: compact ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: <Widget>[
                                          _NowPlayingBadge(
                                            label: hasSong
                                                ? playerController.playbackLabel
                                                : 'No song playing'.tr,
                                          ),
                                          if (hasSong)
                                            _NowPlayingIconAction(
                                              tooltip:
                                                  controller.isFavorite(song.id)
                                                  ? 'Favorites'.tr
                                                  : 'Save'.tr,
                                              icon:
                                                  controller.isFavorite(song.id)
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                        .favorite_border_rounded,
                                              onPressed: () => controller
                                                  .toggleFavorite(song),
                                            ),
                                          if (hasSong)
                                            _NowPlayingIconAction(
                                              tooltip: 'Open player'.tr,
                                              icon: Icons.graphic_eq_rounded,
                                              onPressed: controller
                                                  .openPlayerIfAvailable,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 1.08,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        subtitle,
                                        maxLines: compact ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.84,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        helperText,
                                        maxLines: compact ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                            ),
                                      ),
                                      if (hasSong) ...<Widget>[
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: <Widget>[
                                            _NowPlayingTransportButton(
                                              tooltip: 'Back'.tr,
                                              icon: Icons.skip_previous_rounded,
                                              onPressed:
                                                  playerController.previous,
                                            ),
                                            _NowPlayingPrimaryButton(
                                              label: isBuffering
                                                  ? 'Buffering'.tr
                                                  : isPlaying
                                                  ? 'Pause'.tr
                                                  : 'Play'.tr,
                                              icon: isBuffering
                                                  ? Icons.hourglass_top_rounded
                                                  : isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              onPressed: playerController
                                                  .togglePlayback,
                                            ),
                                            _NowPlayingTransportButton(
                                              tooltip: 'Next'.tr,
                                              icon: Icons.skip_next_rounded,
                                              onPressed: playerController.next,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
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
    final BorderRadius borderRadius = BorderRadius.circular(26);
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
      size: 300,
      quality: 80,
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NowPlayingIconAction extends StatelessWidget {
  const _NowPlayingIconAction({
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
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _NowPlayingTransportButton extends StatelessWidget {
  const _NowPlayingTransportButton({
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
        minimumSize: const Size(46, 46),
      ),
      icon: Icon(icon, size: 24),
    );
  }
}

class _NowPlayingPrimaryButton extends StatelessWidget {
  const _NowPlayingPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(118, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      icon: Icon(icon, size: 22),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
