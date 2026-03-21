import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/extensions.dart';
import '../data/models/song_model.dart';
import '../views/home/widgets/library_group_header.dart';
import '../views/home/widgets/song_list_item.dart';
import '../views/home/widgets/sort_bottom_sheet.dart';
import '../widgets/music_page_background.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final HomeController controller = Get.find<HomeController>();
  final ScrollController _scrollController = ScrollController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<SongModel> get _playlistSongs {
    final List<SongModel> recents = controller.recentIds
        .map(controller.findSongById)
        .whereType<SongModel>()
        .toList(growable: false);
    return recents.isNotEmpty ? recents : controller.featuredSongs;
  }

  List<SongModel> get _likedSongs => controller.songs
      .where((SongModel song) => controller.favoriteIds.contains(song.id))
      .toList(growable: false);

  List<SongModel> get _downloadedSongs => controller.songs
      .where(
        (SongModel song) => song.normalizedFilePath.toLowerCase().contains(
          '/${AppConstants.downloadedSongsFolder.toLowerCase()}/',
        ),
      )
      .toList(growable: false);

  Future<void> _openSortSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SortBottomSheet(),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? action,
    String? actionLabel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    context.colors.secondary,
                    context.colors.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
            if (action != null && actionLabel != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: action, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongListSliver({
    required List<SongModel> songs,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
    required double bottomPadding,
  }) {
    if (songs.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
        sliver: SliverToBoxAdapter(
          child: _buildEmptyCard(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final SongModel song = songs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SongListItem(
              key: ValueKey<String>('collection-${song.id}'),
              song: song,
              onTap: () => controller.playSong(song),
              onFavoriteToggle: () => controller.toggleFavorite(song),
            ),
          );
        }, childCount: songs.length),
      ),
    );
  }

  Widget _buildAllSongsSliver(double bottomPadding) {
    if (!controller.permissionGranted.value && controller.songs.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
        sliver: SliverToBoxAdapter(
          child: _buildEmptyCard(
            icon: Icons.library_music_rounded,
            title: 'Unlock your library',
            message:
                'Allow audio access so the app can scan and style your music.',
            action: controller.loadLibrary,
            actionLabel: 'Grant access',
          ),
        ),
      );
    }
    if (controller.isLoading.value) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
        sliver: const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    if (controller.visibleSongs.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
        sliver: SliverToBoxAdapter(
          child: _buildEmptyCard(
            icon: Icons.queue_music_rounded,
            title: 'No songs found',
            message:
                'Pull down to scan again after adding music to the device.',
            action: controller.loadLibrary,
            actionLabel: 'Scan again',
          ),
        ),
      );
    }

    final bool isMostPlayed =
        controller.section.value == HomeSection.mostPlayed;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final LibraryEntry entry = controller.libraryEntries[index];
          if (entry is LibraryHeaderEntry) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 10, bottom: 12),
              child: LibraryGroupHeader(
                key: ValueKey<String>('collection-group-${entry.title}'),
                title: entry.title,
                subtitle: entry.subtitle,
                count: entry.count,
              ),
            );
          }

          final SongModel song = (entry as LibrarySongEntry).song;
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
        }, childCount: controller.libraryEntries.length),
      ),
    );
  }

  Widget _buildLibrarySection(double bottomPadding) {
    return switch (_tabIndex) {
      1 => _buildSongListSliver(
        songs: _playlistSongs,
        emptyIcon: Icons.music_note_rounded,
        emptyTitle: 'No playlist picks',
        emptyMessage:
            'Play a few tracks and this quick playlist section will fill up.',
        bottomPadding: bottomPadding,
      ),
      2 => _buildSongListSliver(
        songs: _likedSongs,
        emptyIcon: Icons.favorite_border_rounded,
        emptyTitle: 'No liked songs',
        emptyMessage:
            'Tap the heart on any track to build your liked collection.',
        bottomPadding: bottomPadding,
      ),
      3 => _buildSongListSliver(
        songs: _downloadedSongs,
        emptyIcon: Icons.download_rounded,
        emptyTitle: 'No downloads found',
        emptyMessage: 'Save shared tracks from chat to see them here.',
        bottomPadding: bottomPadding,
      ),
      _ => _buildAllSongsSliver(bottomPadding),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MusicPageBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.loadLibrary(forceRefresh: true);
              controller.showRefreshedToast();
            },
            child: Obx(
              () => CustomScrollView(
                controller: _scrollController,
                cacheExtent: 900,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () => Get.back<void>(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'My Collection',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tracks, favorites, grouping, and sorting live here now.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.70),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        onChanged: controller.updateSearch,
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists, albums',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: _openSortSheet,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CollectionSummaryCard(controller: controller),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _CollectionLibraryTabs(
                        selectedIndex: _tabIndex,
                        allCount: controller.visibleSongs.length,
                        playlistCount: _playlistSongs.length,
                        likedCount: _likedSongs.length,
                        downloadCount: _downloadedSongs.length,
                        onSelected: (int index) =>
                            setState(() => _tabIndex = index),
                      ),
                    ),
                  ),
                  _buildLibrarySection(32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionSummaryCard extends StatelessWidget {
  const _CollectionSummaryCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        'Collection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Grouped by ${controller.groupLabel} - Sorted by ${controller.sortLabel}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${controller.visibleSongs.length} tracks',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                stat('${controller.songs.length}', 'Tracks'),
                const SizedBox(width: 10),
                stat('${controller.favoriteIds.length}', 'Favorites'),
                const SizedBox(width: 10),
                stat('${controller.totalPlayCount}', 'Plays'),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LibraryGroup.values
                    .map((LibraryGroup item) {
                      final bool selected = controller.group.value == item;
                      final String label = switch (item) {
                        LibraryGroup.folder => 'Folder',
                        LibraryGroup.titleLanguage => 'Language',
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

class _CollectionLibraryTabs extends StatelessWidget {
  const _CollectionLibraryTabs({
    required this.selectedIndex,
    required this.allCount,
    required this.playlistCount,
    required this.likedCount,
    required this.downloadCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int allCount;
  final int playlistCount;
  final int likedCount;
  final int downloadCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<(String, int)> tabs = <(String, int)>[
      ('All', allCount),
      ('Playlist', playlistCount),
      ('Liked', likedCount),
      ('Download', downloadCount),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Library Browser',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Jump between your grouped library, quick playlist, liked songs, and downloads.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: List<Widget>.generate(tabs.length, (int index) {
              final bool selected = index == selectedIndex;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: selected
                            ? LinearGradient(
                                colors: <Color>[
                                  context.colors.secondary,
                                  context.colors.tertiary,
                                ],
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            tabs[index].$1,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.70),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tabs[index].$2}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                            .withValues(alpha: 0.82)
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.54),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
