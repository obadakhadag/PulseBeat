import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_pages.dart';
import '../../data/models/song_model.dart';
import '../../widgets/song_artwork.dart';
import 'widgets/lyrics_view.dart';
import 'widgets/seek_bar.dart';

class PlayerScreen extends GetView<PlayerController> {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = Get.find<SettingsController>();

    return Scaffold(
      body: Obx(() {
        final SongModel? song = controller.currentSong.value;
        if (song == null) {
          return const Center(child: Text('No song selected'));
        }

        return _PlayerBody(
          song: song,
          controller: controller,
          settings: settings,
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
  });

  final SongModel song;
  final PlayerController controller;
  final SettingsController settings;

  Future<void> _openPlayerOptions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text('Show lyrics'),
                  subtitle: const Text('Load lyrics for the active track.'),
                  trailing: Switch.adaptive(
                    value: settings.showLyrics.value,
                    onChanged: (bool value) {
                      settings.setShowLyrics(value);
                      controller.setShowLyrics(value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Repeat mode'),
                  subtitle: Text(switch (controller.loopMode.value) {
                    LoopMode.one => 'Repeat one',
                    LoopMode.all => 'Repeat all',
                    LoopMode.off => 'Off',
                  }),
                  trailing: const Icon(Icons.repeat_rounded),
                  onTap: controller.cycleLoopMode,
                ),
                ListTile(
                  title: const Text('Open app settings'),
                  trailing: const Icon(Icons.tune_rounded),
                  onTap: () {
                    Get.back<void>();
                    Get.toNamed(AppPages.settings);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            context.colors.primary.withValues(
              alpha: settings.immersivePlayer.value ? 0.92 : 0.72,
            ),
            context.colors.secondary.withValues(alpha: 0.88),
            context.colors.tertiary.withValues(alpha: 0.86),
            const Color(0xFF0D0D0D),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Spacer(),
                  Text(
                    'Now Playing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _openPlayerOptions(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.86),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 300,
                          height: 300,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.24),
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.04),
                              ],
                            ),
                          ),
                          child: ClipOval(
                            child: SongArtwork(
                              songId: song.artworkId,
                              width: 272,
                              height: 272,
                              borderRadius: BorderRadius.circular(999),
                              size: 700,
                              quality: 90,
                              fallback: Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.scrim.withValues(alpha: 0.20),
                                child: Icon(
                                  Icons.album_rounded,
                                  size: 84,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist.fallbackArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.78),
                              ),
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Obx(
                              () => _RoundPlayerButton(
                                onPressed: controller.toggleShuffle,
                                icon: controller.shuffleEnabled.value
                                    ? Icons.shuffle_on_rounded
                                    : Icons.shuffle_rounded,
                              ),
                            ),
                            _RoundPlayerButton(
                              onPressed: controller.previous,
                              icon: Icons.skip_previous_rounded,
                              size: 58,
                            ),
                            Obx(
                              () => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: AppHelpers.glowShadows(context),
                                ),
                                child: IconButton.filled(
                                  onPressed: controller.togglePlayback,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    minimumSize: const Size(84, 84),
                                  ),
                                  icon: Icon(
                                    controller.isPlaying.value
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                            _RoundPlayerButton(
                              onPressed: controller.next,
                              icon: Icons.skip_next_rounded,
                              size: 58,
                            ),
                            _RoundPlayerButton(
                              onPressed: () => _openPlayerOptions(context),
                              icon: Icons.settings_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Obx(
                              () => ChoiceChip(
                                label: Text(switch (controller.loopMode.value) {
                                  LoopMode.one => 'Repeat One',
                                  LoopMode.all => 'Repeat All',
                                  LoopMode.off => 'Repeat Off',
                                }),
                                selected:
                                    controller.loopMode.value != LoopMode.off,
                                onSelected: (_) => controller.cycleLoopMode(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Obx(
                              () => ChoiceChip(
                                label: const Text('Lyrics'),
                                selected: settings.showLyrics.value,
                                onSelected: (bool value) {
                                  settings.setShowLyrics(value);
                                  controller.setShowLyrics(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Obx(() {
                          if (!settings.showLyrics.value) {
                            return const SizedBox.shrink();
                          }

                          return Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.scrim.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Obx(
                                () => LyricsView(
                                  isLoading: controller.isLoadingLyrics.value,
                                  lyrics: controller.lyrics.value,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundPlayerButton extends StatelessWidget {
  const _RoundPlayerButton({
    required this.onPressed,
    required this.icon,
    this.size = 52,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: 0.10),
      ),
      icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}
