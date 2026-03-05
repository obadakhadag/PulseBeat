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
  final int quality;
  final int size;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: audio_query.QueryArtworkWidget(
          key: ValueKey<int>(songId),
          controller: _sharedArtworkQuery,
          id: songId,
          type: audio_query.ArtworkType.AUDIO,
          quality: quality,
          size: size,
          keepOldArtwork: true,
          artworkQuality: filterQuality,
          artworkHeight: height,
          artworkWidth: width,
          artworkFit: fit,
          artworkBorder: borderRadius,
          nullArtworkWidget: fallback,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}
