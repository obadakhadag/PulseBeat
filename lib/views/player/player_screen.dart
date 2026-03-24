import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/song_model.dart';
import '../../routes/app_pages.dart';
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
          return Center(child: Text('No song selected'.tr));
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
                  title: Text('Auto-load lyrics'.tr),
                  subtitle: Text('Load lyrics when a song becomes active.'.tr),
                  trailing: Switch.adaptive(
                    value: settings.showLyrics.value,
                    onChanged: (bool value) {
                      settings.setShowLyrics(value);
                      controller.setShowLyrics(value);
                    },
                  ),
                ),
                ListTile(
                  title: Text('Repeat mode'.tr),
                  subtitle: Text(switch (controller.loopMode.value) {
                    LoopMode.one => 'Repeat one'.tr,
                    LoopMode.all => 'Repeat all'.tr,
                    LoopMode.off => 'Repeat off'.tr,
                  }),
                  trailing: const Icon(Icons.repeat_rounded),
                  onTap: controller.cycleLoopMode,
                ),
                ListTile(
                  title: Text('Open app settings'.tr),
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

  Future<void> _openLyricsSheet(BuildContext context) {
    unawaited(controller.ensureLyricsLoaded(song));

    final ThemeData baseTheme = Theme.of(context);
    final ThemeData sheetTheme = baseTheme.copyWith(
      iconTheme: baseTheme.iconTheme.copyWith(color: Colors.white),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: baseTheme.colorScheme.copyWith(
        onSurface: Colors.white,
        surface: const Color(0xFF1F1F1F),
      ),
    );

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 280),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (BuildContext context) {
        return Theme(
          data: sheetTheme,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.56,
            maxChildSize: 0.96,
            builder: (BuildContext context, ScrollController scrollController) {
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 280),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 28),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xEE181818),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 12),
                      Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Lyrics'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${song.title} - ${song.artist.fallbackArtist}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back<void>(),
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Obx(() {
                          if (!controller.isLoadingLyrics.value &&
                              controller.lyrics.value.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Lyrics are getting ready.'.tr,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'If the song just changed, give it a moment while we fetch the lines.'
                                          .tr,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.70,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return LyricsView(
                            isLoading: controller.isLoadingLyrics.value,
                            lyrics: controller.lyrics.value,
                            scrollController: scrollController,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color headerForeground = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;
    final Color panelForeground = theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            context.colors.primary.withValues(
              alpha: settings.immersivePlayer.value
                  ? (isDark ? 0.88 : 0.30)
                  : (isDark ? 0.72 : 0.18),
            ),
            context.colors.tertiary.withValues(alpha: isDark ? 0.82 : 0.22),
            context.colors.secondary.withValues(alpha: isDark ? 0.74 : 0.20),
            isDark ? const Color(0xFF1A1A1A) : theme.scaffoldBackgroundColor,
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
                    style: IconButton.styleFrom(
                      foregroundColor: headerForeground,
                      backgroundColor: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.06,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Spacer(),
                  Text(
                    'Now Playing'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: headerForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _openPlayerOptions(context),
                    style: IconButton.styleFrom(
                      foregroundColor: headerForeground,
                      backgroundColor: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.06,
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  color: theme.cardColor.withValues(
                    alpha: isDark ? 0.94 : 0.97,
                  ),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool compactWidth = constraints.maxWidth < 360;
                          final double artworkShellSize =
                              (constraints.maxWidth < 430
                                      ? constraints.maxWidth * 0.74
                                      : 300.0)
                                  .clamp(220.0, 300.0)
                                  .toDouble();
                          final double artworkSize = (artworkShellSize - 28)
                              .clamp(192.0, 272.0)
                              .toDouble();
                          final double sideButtonSize = compactWidth ? 50 : 58;
                          final double utilityButtonSize = compactWidth
                              ? 46
                              : 52;
                          final double mainButtonSize = compactWidth ? 74 : 84;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  24,
                                  22,
                                  22,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      width: artworkShellSize,
                                      height: artworkShellSize,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            context.colors.primary.withValues(
                                              alpha: isDark ? 0.30 : 0.18,
                                            ),
                                            context.colors.tertiary.withValues(
                                              alpha: isDark ? 0.12 : 0.06,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: SongArtwork(
                                          songId: song.artworkId,
                                          artworkUri: song.artworkUri,
                                          width: artworkSize,
                                          height: artworkSize,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          size: 700,
                                          quality: 90,
                                          fallback: SongArtworkPlaceholder(
                                            width: artworkSize,
                                            height: artworkSize,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            icon: Icons.album_rounded,
                                            gradientColors: <Color>[
                                              theme.colorScheme.primary
                                                  .withValues(
                                                    alpha: isDark ? 0.72 : 0.86,
                                                  ),
                                              theme.colorScheme.tertiary
                                                  .withValues(alpha: 0.82),
                                              theme.colorScheme.secondary
                                                  .withValues(alpha: 0.90),
                                            ],
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
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: panelForeground,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      song.artist.fallbackArtist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: panelForeground.withValues(
                                              alpha: 0.72,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                    Obx(
                                      () => SeekBar(
                                        position: controller.position.value,
                                        total: controller.total.value,
                                        onChanged: (_) {},
                                        onChangeEnd: (double value) =>
                                            controller.seek(
                                              Duration(
                                                milliseconds: value.toInt(),
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: compactWidth ? 8 : 14,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        Obx(
                                          () => _RoundPlayerButton(
                                            onPressed: controller.toggleShuffle,
                                            icon:
                                                controller.shuffleEnabled.value
                                                ? Icons.shuffle_on_rounded
                                                : Icons.shuffle_rounded,
                                            size: utilityButtonSize,
                                            isActive:
                                                controller.shuffleEnabled.value,
                                          ),
                                        ),
                                        _RoundPlayerButton(
                                          onPressed: controller.previous,
                                          icon: Icons.skip_previous_rounded,
                                          size: sideButtonSize,
                                        ),
                                        Obx(
                                          () => Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: AppHelpers.glowShadows(
                                                context,
                                              ),
                                            ),
                                            child: IconButton.filled(
                                              onPressed:
                                                  controller.togglePlayback,
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    context.colors.secondary,
                                                foregroundColor:
                                                    theme.colorScheme.onPrimary,
                                                minimumSize: Size(
                                                  mainButtonSize,
                                                  mainButtonSize,
                                                ),
                                              ),
                                              icon: Icon(
                                                controller.isPlaying.value
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                size: compactWidth ? 32 : 36,
                                              ),
                                            ),
                                          ),
                                        ),
                                        _RoundPlayerButton(
                                          onPressed: controller.next,
                                          icon: Icons.skip_next_rounded,
                                          size: sideButtonSize,
                                        ),
                                        Obx(
                                          () => _RoundPlayerButton(
                                            onPressed: controller.cycleLoopMode,
                                            icon: switch (controller
                                                .loopMode
                                                .value) {
                                              LoopMode.one =>
                                                Icons.repeat_one_rounded,
                                              LoopMode.all =>
                                                Icons.repeat_on_rounded,
                                              LoopMode.off =>
                                                Icons.repeat_rounded,
                                            },
                                            size: utilityButtonSize,
                                            isActive:
                                                controller.loopMode.value !=
                                                LoopMode.off,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Obx(
                                        () => OutlinedButton.icon(
                                          onPressed: () =>
                                              _openLyricsSheet(context),
                                          icon: const Icon(
                                            Icons.lyrics_rounded,
                                          ),
                                          label: Text(
                                            controller.isLoadingLyrics.value
                                                ? 'Loading...'.tr
                                                : 'Lyrics'.tr,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: panelForeground,
                                            backgroundColor: panelForeground
                                                .withValues(
                                                  alpha: isDark ? 0.08 : 0.04,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
    this.isActive = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        backgroundColor: isActive
            ? context.colors.secondary.withValues(alpha: 0.18)
            : Theme.of(context).colorScheme.onSurface.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.10
                    : 0.05,
              ),
      ),
      icon: Icon(
        icon,
        color: isActive
            ? context.colors.secondary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
