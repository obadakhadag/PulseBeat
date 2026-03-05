import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/song_model.dart';
import '../../widgets/song_artwork.dart';
import 'widgets/lyrics_view.dart';
import 'widgets/seek_bar.dart';

class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      body: Obx(() {
        final song = controller.currentSong.value;
        if (song == null) {
          return const Center(child: Text('No song selected'));
        }

        return _PlayerBody(
          song: song,
          controller: controller,
          settings: settings,
          immersive: settings.immersivePlayer.value,
        );
      }),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.song,
    required this.controller,
    required this.settings,
    required this.immersive,
  });

  final SongModel song;
  final PlayerController controller;
  final SettingsController settings;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppHelpers.songGradient(
          seed: song.id,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: <Widget>[
                  IconButton.filledTonal(
                    onPressed: Get.back<void>,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Spacer(),
                  Text(
                    'Now Playing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => IconButton.filledTonal(
                      onPressed: controller.toggleShuffle,
                      icon: Icon(
                        controller.shuffleEnabled.value
                            ? Icons.shuffle_on_rounded
                            : Icons.shuffle_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: immersive ? 0.16 : 0.32,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    RepaintBoundary(
                      child: SongArtwork(
                        songId: song.artworkId,
                        width: 310,
                        height: 310,
                        borderRadius: BorderRadius.circular(32),
                        size: 600,
                        quality: 85,
                        fallback: Container(
                          height: 310,
                          width: 310,
                          color: Colors.black.withValues(alpha: 0.14),
                          child: const Icon(
                            Icons.album_rounded,
                            size: 82,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.artist.fallbackArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => SeekBar(
                        position: controller.position.value,
                        total: controller.total.value,
                        onChanged: (_) {},
                        onChangeEnd: (double value) => controller.seek(
                          Duration(milliseconds: value.toInt()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Obx(
                          () => IconButton(
                            onPressed: controller.cycleLoopMode,
                            iconSize: 28,
                            color: Colors.white,
                            icon: Icon(switch (controller.loopMode.value) {
                              LoopMode.one => Icons.repeat_one_on_rounded,
                              LoopMode.all => Icons.repeat_on_rounded,
                              LoopMode.off => Icons.repeat_rounded,
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(58, 58),
                          ),
                          onPressed: controller.previous,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () => IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(74, 74),
                            ),
                            onPressed: controller.togglePlayback,
                            icon: Icon(
                              controller.isPlaying.value
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(58, 58),
                          ),
                          onPressed: controller.next,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => controller.loadLyrics(song),
                          iconSize: 28,
                          color: Colors.white,
                          icon: const Icon(Icons.lyrics_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Obx(() {
                      if (!settings.showLyrics.value) {
                        return const SizedBox.shrink();
                      }

                      return Expanded(
                        child: Column(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Lyrics',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Obx(
                                  () => LyricsView(
                                    isLoading: controller.isLoadingLyrics.value,
                                    lyrics: controller.lyrics.value,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
