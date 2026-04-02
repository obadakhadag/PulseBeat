import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;

final audio_query.OnAudioQuery _sharedArtworkQuery = audio_query.OnAudioQuery();

class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    required this.songId,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fallback,
    this.artworkUri,
    this.quality = 40,
    this.size = 128,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.low,
  });

  final int songId;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Widget fallback;
  final String? artworkUri;
  final int quality;
  final int size;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final double resolvedWidth = width.isFinite && width > 0
        ? width
        : size.toDouble();
    final double resolvedHeight = height.isFinite && height > 0
        ? height
        : size.toDouble();
    final String trimmedArtworkUri = artworkUri?.trim() ?? '';

    if (trimmedArtworkUri.isEmpty && songId <= 0) {
      return fallback;
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: _buildArtwork(
          resolvedWidth: resolvedWidth,
          resolvedHeight: resolvedHeight,
          trimmedArtworkUri: trimmedArtworkUri,
        ),
      ),
    );
  }

  Widget _buildArtwork({
    required double resolvedWidth,
    required double resolvedHeight,
    required String trimmedArtworkUri,
  }) {
    if (trimmedArtworkUri.startsWith('http://') ||
        trimmedArtworkUri.startsWith('https://')) {
      return Image.network(
        trimmedArtworkUri,
        width: resolvedWidth,
        height: resolvedHeight,
        fit: fit,
        filterQuality: filterQuality,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (songId <= 0) {
      return fallback;
    }

    return audio_query.QueryArtworkWidget(
      key: ValueKey<String>('artwork-$songId-$trimmedArtworkUri'),
      controller: _sharedArtworkQuery,
      id: songId,
      type: audio_query.ArtworkType.AUDIO,
      quality: quality,
      size: size,
      keepOldArtwork: true,
      artworkQuality: filterQuality,
      artworkHeight: resolvedHeight,
      artworkWidth: resolvedWidth,
      artworkFit: fit,
      artworkBorder: borderRadius,
      nullArtworkWidget: fallback,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class SongArtworkPlaceholder extends StatelessWidget {
  const SongArtworkPlaceholder({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.icon = Icons.music_note_rounded,
    this.iconColor = Colors.white,
    this.gradientColors,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final IconData icon;
  final Color iconColor;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors =
        gradientColors ??
        <Color>[
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.96),
          Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.92),
          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.96),
        ];
    final double shortestSide = width < height ? width : height;
    final double iconSize = shortestSide * 0.42;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: -height * 0.18,
              right: -width * 0.08,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                child: SizedBox(width: width * 0.56, height: width * 0.56),
              ),
            ),
            Positioned(
              bottom: -height * 0.16,
              left: -width * 0.10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.10),
                ),
                child: SizedBox(width: width * 0.44, height: width * 0.44),
              ),
            ),
            Center(
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
          ],
        ),
      ),
    );
  }
}
