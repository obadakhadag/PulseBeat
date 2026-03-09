import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';
import '../../pages/chat_list_page.dart';
import '../../pages/follow_requests_page.dart';
import '../../routes/app_pages.dart';
import '../../widgets/song_artwork.dart';
import 'widgets/library_group_header.dart';
import 'widgets/song_list_item.dart';
import 'widgets/sort_bottom_sheet.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              context.colors.primary.withValues(alpha: 0.16),
              Theme.of(context).scaffoldBackgroundColor,
              context.colors.secondary.withValues(alpha: 0.09),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.loadLibrary(forceRefresh: true);
              controller.showRefreshedToast();
            },
            child: CustomScrollView(
              controller: controller.scrollController,
              cacheExtent: 720,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _HeroHeader(playerController: playerController),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _LibrarySnapshot(controller: controller),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(controller: controller),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionControls(controller: controller),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _ViewModeCard(controller: controller),
                    ),
                  ),
                ),
                _LibraryContent(controller: controller),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        if (!controller.showScrollToTop.value) {
          return const SizedBox.shrink();
        }

        final hasMiniPlayer = playerController.currentSong.value != null;
        return Padding(
          padding: EdgeInsets.only(bottom: hasMiniPlayer ? 88 : 0),
          child: FloatingActionButton.small(
            onPressed: controller.scrollToTop,
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Obx(() {
        final song = playerController.currentSong.value;
        if (song == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: controller.openPlayerIfAvailable,
              child: Ink(
                height: 82,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppHelpers.glowShadows(context),
                ),
                child: RepaintBoundary(
                  child: Row(
                    children: <Widget>[
                      SongArtwork(
                        songId: song.artworkId,
                        width: 52,
                        height: 52,
                        borderRadius: BorderRadius.circular(18),
                        size: 128,
                        quality: 45,
                        fallback: Container(
                          width: 52,
                          height: 52,
                          color: context.colors.primary.withValues(alpha: 0.18),
                          child: const Icon(Icons.graphic_eq_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              song.title.ellipsis(24),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              song.artist.fallbackArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: playerController.previous,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      IconButton(
                        onPressed: playerController.togglePlayback,
                        icon: Obx(
                          () => Icon(
                            playerController.isPlaying.value
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: playerController.next,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.playerController});

  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'PulseBeat',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      homeController.subline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ChatListPage()),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const FollowRequestsPage(),
                ),
              ),
              icon: const Icon(Icons.person_add),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => Get.toNamed(AppPages.settings),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[context.colors.primary, context.colors.secondary],
            ),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Obx(() {
            final currentSong = playerController.currentSong.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentSong == null
                        ? 'Ready to scan'
                        : playerController.playbackLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  currentSong?.title ?? homeController.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong?.artist.fallbackArtist ??
                      'Scan your phone and turn your library into a designed experience.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: InputDecoration(
        hintText: 'Search tracks, artists, albums',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const SortBottomSheet(),
          ),
          icon: const Icon(Icons.tune_rounded),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SectionControls extends StatelessWidget {
  const _SectionControls({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: HomeSection.values
              .map((HomeSection item) {
                final selected = controller.section.value == item;
                final label = switch (item) {
                  HomeSection.all => 'All',
                  HomeSection.favorites => 'Favorites',
                  HomeSection.recents => 'Recents',
                  HomeSection.mostPlayed => 'Most played',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => controller.setSection(item),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _LibrarySnapshot extends StatelessWidget {
  const _LibrarySnapshot({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: <Widget>[
          Expanded(
            child: _StatCard(
              label: 'Tracks',
              value: '${controller.songs.length}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Favorites',
              value: '${controller.favoriteIds.length}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Plays',
              value: '${controller.totalPlayCount}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ViewModeCard extends StatelessWidget {
  const _ViewModeCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        controller.sectionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Grouped by ${controller.groupLabel} | Sorted by ${controller.sortLabel}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${controller.visibleSongs.length} songs',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Group songs by category',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LibraryGroup.values
                    .map((LibraryGroup item) {
                      final selected = controller.group.value == item;
                      final label = switch (item) {
                        LibraryGroup.folder => 'Folder',
                        LibraryGroup.titleLanguage => 'Title language',
                        LibraryGroup.artist => 'Artist',
                      };

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => controller.setGroup(item),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.permissionGranted.value) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _PermissionState(controller: controller),
        );
      }
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.visibleSongs.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyLibrary(controller: controller),
        );
      }

      return SliverMainAxisGroup(
        slivers: <Widget>[
          if (controller.featuredSongs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              sliver: SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: _FeaturedRail(controller: controller),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final entry = controller.libraryEntries[index];
                  if (entry is LibraryHeaderEntry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 8,
                        bottom: 12,
                      ),
                      child: LibraryGroupHeader(
                        key: ValueKey<String>('group-${entry.title}'),
                        title: entry.title,
                        subtitle: entry.subtitle,
                        count: entry.count,
                      ),
                    );
                  }

                  final song = (entry as LibrarySongEntry).song;
                  final isMostPlayed =
                      controller.section.value == HomeSection.mostPlayed;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SongListItem(
                      key: ValueKey<int>(song.id),
                      song: song,
                      subtitle: isMostPlayed
                          ? '${song.artist.fallbackArtist} - ${controller.playCountLabel(song.id)}'
                          : null,
                      trailingLabel: isMostPlayed
                          ? controller.playCountLabel(song.id)
                          : null,
                      onTap: () => controller.playSong(song),
                      onFavoriteToggle: () => controller.toggleFavorite(song),
                    ),
                  );
                },
                childCount: controller.libraryEntries.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.featuredSongs;
    final isMostPlayed = controller.section.value == HomeSection.mostPlayed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isMostPlayed ? 'Heavy Rotation' : 'Quick Picks',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 152,
          child: ListView.builder(
            cacheExtent: 320,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final song = items[index];
              return Padding(
                padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 12),
                child: GestureDetector(
                  onTap: () => controller.playSong(song),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppHelpers.songGradient(
                        seed: song.id,
                        brightness: Theme.of(context).brightness,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isMostPlayed
                              ? '${song.artist.fallbackArtist} - ${controller.playCountLabel(song.id)}'
                              : song.artist.fallbackArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
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
      ],
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.library_music_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Audio permission required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant access so PulseBeat can scan the songs on your device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.loadLibrary,
                child: const Text('Try again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.openAppSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.queue_music_rounded, size: 48),
              const SizedBox(height: 14),
              Text(
                'No songs found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add music files to the device, then pull down to scan again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.loadLibrary,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
