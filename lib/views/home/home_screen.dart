import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/song_model.dart';
import '../../routes/app_pages.dart';
import '../../widgets/floating_music_nav_bar.dart';
import '../../widgets/music_page_background.dart';
import '../../widgets/song_artwork.dart';
import 'widgets/sort_bottom_sheet.dart';

const double _kHomeFloatingNavHeight = 76;
const double _kHomeFloatingNavBottom = 20;
const double _kHomeFloatingInset = 16;
const double _kHomeBodyBottomPadding = 100;
const double _kHomeMiniPlayerHeight = 88;
const double _kHomeMiniPlayerBottom =
    _kHomeFloatingNavBottom + _kHomeFloatingNavHeight + 16;
const Color _kHomeDebugBackground = Color(0xFF1B1D22);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final PlayerController playerController = Get.find<PlayerController>();

  List<SongModel> get _playlistSongs {
    final List<SongModel> recents = controller.recentIds
        .map(controller.findSongById)
        .whereType<SongModel>()
        .toList(growable: false);
    return recents.isNotEmpty ? recents : controller.featuredSongs;
  }

  Future<void> _openSortSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SortBottomSheet(),
    );
  }

  void _applyDiscovery(_DiscoveryChip chip) {
    switch (chip) {
      case _DiscoveryChip.all:
        controller.setSection(HomeSection.all);
      case _DiscoveryChip.newRelease:
        controller.setSection(HomeSection.recents);
      case _DiscoveryChip.trending:
        controller.setSection(HomeSection.mostPlayed);
      case _DiscoveryChip.topList:
        controller.setSection(HomeSection.favorites);
    }
  }

  _DiscoveryChip _activeDiscovery() {
    return switch (controller.section.value) {
      HomeSection.recents => _DiscoveryChip.newRelease,
      HomeSection.mostPlayed => _DiscoveryChip.trending,
      HomeSection.favorites => _DiscoveryChip.topList,
      HomeSection.all => _DiscoveryChip.all,
    };
  }

  int get _contentCount {
    return controller.visibleSongs.length;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color homeBackgroundColor = theme.brightness == Brightness.dark
        ? _kHomeDebugBackground
        : theme.scaffoldBackgroundColor;
    // ignore: avoid_print
    print("HOME PAGE BUILD START");
    // ignore: avoid_print
    print("HOME PAGE CONTENT COUNT: $_contentCount");

    return Scaffold(
      backgroundColor: homeBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: homeBackgroundColor),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: _kHomeBodyBottomPadding),
              child: _HomePageContent(
                controller: controller,
                playerController: playerController,
                playlistSongs: _playlistSongs,
                activeDiscovery: _activeDiscovery(),
                backgroundColor: homeBackgroundColor,
                onOpenSort: _openSortSheet,
                onRefresh: () async {
                  await controller.loadLibrary(forceRefresh: true);
                  controller.showRefreshedToast();
                },
                onDiscoverySelected: _applyDiscovery,
              ),
            ),
          ),
          Obx(() {
            final SongModel? song = playerController.currentSong.value;
            if (song == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: _kHomeFloatingInset,
              right: _kHomeFloatingInset,
              bottom: _kHomeMiniPlayerBottom,
              child: _MiniPlayer(
                song: song,
                controller: playerController,
                onOpen: controller.openPlayerIfAvailable,
              ),
            );
          }),
          const Positioned(
            left: _kHomeFloatingInset,
            right: _kHomeFloatingInset,
            bottom: _kHomeFloatingNavBottom,
            child: SizedBox(
              height: _kHomeFloatingNavHeight,
              child: FloatingMusicNavBar(currentRoute: AppPages.home),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (!controller.showScrollToTop.value) {
          return const SizedBox.shrink();
        }
        final bool hasMiniPlayer = playerController.currentSong.value != null;
        return Padding(
          padding: EdgeInsets.only(
            bottom: hasMiniPlayer
                ? _kHomeMiniPlayerBottom + _kHomeMiniPlayerHeight + 18
                : _kHomeFloatingNavBottom + _kHomeFloatingNavHeight + 20,
          ),
          child: FloatingActionButton.small(
            onPressed: controller.scrollToTop,
            backgroundColor: context.colors.secondary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent({
    required this.controller,
    required this.playerController,
    required this.playlistSongs,
    required this.activeDiscovery,
    required this.backgroundColor,
    required this.onOpenSort,
    required this.onRefresh,
    required this.onDiscoverySelected,
  });

  final HomeController controller;
  final PlayerController playerController;
  final List<SongModel> playlistSongs;
  final _DiscoveryChip activeDiscovery;
  final Color backgroundColor;
  final Future<void> Function() onOpenSort;
  final Future<void> Function() onRefresh;
  final ValueChanged<_DiscoveryChip> onDiscoverySelected;

  Widget _buildEmptyCard(
    BuildContext context, {
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

  Widget _buildFallback(BuildContext context, Object error) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Home Loaded',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Fallback UI active: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print("HOME PAGE CONTENT RENDERING");
    return MusicPageBackground(
      baseColor: backgroundColor,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: Obx(() {
          try {
            final SongModel? featuredSong = controller.featuredSongs.isNotEmpty
                ? controller.featuredSongs.first
                : controller.songs.isNotEmpty
                ? controller.songs.first
                : playerController.currentSong.value;
            final List<SongModel> previewSongs =
                controller.featuredSongs.isNotEmpty
                ? controller.featuredSongs.take(4).toList(growable: false)
                : playlistSongs.take(4).toList(growable: false);

            return CustomScrollView(
              controller: controller.scrollController,
              cacheExtent: 900,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: const _HomeTopBar()),
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
                          onPressed: onOpenSort,
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
                    child: _DiscoveryRow(
                      activeChip: activeDiscovery,
                      onTap: onDiscoverySelected,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturedCard(
                      song: featuredSong,
                      headline: controller.headline,
                      subline: controller.subline,
                      playbackLabel: playerController.playbackLabel,
                      isLiked:
                          featuredSong != null &&
                          controller.isFavorite(featuredSong.id),
                      onPlay: featuredSong == null
                          ? null
                          : () => controller.playSong(featuredSong),
                      onLike: featuredSong == null
                          ? null
                          : () => controller.toggleFavorite(featuredSong),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CollectionAccessCard(
                      onTap: () => Get.toNamed(AppPages.collection),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PlaylistPreview(
                      songs: previewSongs,
                      onPlay: controller.playSong,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child:
                        controller.permissionGranted.value ||
                            controller.songs.isNotEmpty
                        ? const SizedBox.shrink()
                        : _buildEmptyCard(
                            context,
                            icon: Icons.library_music_rounded,
                            title: 'Unlock your library',
                            message:
                                'Allow audio access so your collection stays up to date.',
                            action: controller.loadLibrary,
                            actionLabel: 'Grant access',
                          ),
                  ),
                ),
              ],
            );
          } catch (error, stackTrace) {
            debugPrint('HOME PAGE FALLBACK TRIGGERED: $error');
            debugPrintStack(stackTrace: stackTrace);
            return _buildFallback(context, error);
          }
        }),
      ),
    );
  }
}

enum _DiscoveryChip { all, newRelease, trending, topList }

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final User? user = FirebaseAuth.instance.currentUser;
    return Row(
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Get.toNamed(AppPages.profile),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            backgroundImage: user?.photoURL?.isNotEmpty == true
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL?.isEmpty ?? true
                ? const Icon(Icons.person_rounded)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Your Mix',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PulseBeat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => homeController.setSection(
            homeController.section.value == HomeSection.favorites
                ? HomeSection.all
                : HomeSection.favorites,
          ),
          icon: Icon(
            homeController.section.value == HomeSection.favorites
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
          ),
          style: IconButton.styleFrom(
            backgroundColor:
                homeController.section.value == HomeSection.favorites
                ? context.colors.tertiary.withValues(alpha: 0.24)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Get.toNamed(AppPages.settings),
          icon: const Icon(Icons.settings_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _CollectionAccessCard extends StatelessWidget {
  const _CollectionAccessCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      context.colors.primary,
                      context.colors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.library_music_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'My Collection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open your tracks, favorites, downloads, and grouped library.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: onTap, child: const Text('Go')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({required this.activeChip, required this.onTap});

  final _DiscoveryChip activeChip;
  final ValueChanged<_DiscoveryChip> onTap;

  @override
  Widget build(BuildContext context) {
    const List<(_DiscoveryChip, String)> chips = <(_DiscoveryChip, String)>[
      (_DiscoveryChip.all, 'All'),
      (_DiscoveryChip.newRelease, 'New Release'),
      (_DiscoveryChip.trending, 'Trending'),
      (_DiscoveryChip.topList, 'Top List'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips
            .map(((_DiscoveryChip, String) item) {
              final bool active = item.$1 == activeChip;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onTap(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: active
                          ? LinearGradient(
                              colors: <Color>[
                                context.colors.secondary,
                                context.colors.tertiary,
                              ],
                            )
                          : null,
                      color: active
                          ? null
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.song,
    required this.headline,
    required this.subline,
    required this.playbackLabel,
    required this.isLiked,
    required this.onPlay,
    required this.onLike,
  });

  final SongModel? song;
  final String headline;
  final String subline;
  final String playbackLabel;
  final bool isLiked;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppHelpers.glowShadows(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            song == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          context.colors.primary,
                          context.colors.secondary,
                          context.colors.tertiary,
                        ],
                      ),
                    ),
                  )
                : SongArtwork(
                    songId: song!.artworkId,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(30),
                    size: 900,
                    quality: 80,
                    fallback: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            context.colors.primary,
                            context.colors.secondary,
                            context.colors.tertiary,
                          ],
                        ),
                      ),
                    ),
                  ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.10),
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.55),
                    Theme.of(context).colorScheme.scrim.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      song == null ? 'Library Preview' : playbackLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    song?.title ?? headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song?.artist.fallbackArtist ?? subline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onPlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onLike,
                        icon: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistPreview extends StatelessWidget {
  const _PlaylistPreview({required this.songs, required this.onPlay});

  final List<SongModel> songs;
  final ValueChanged<SongModel> onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Daily Playlist',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${songs.length} songs',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (songs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Play some tracks and your quick playlist will show up here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
            ),
          )
        else
          ...songs.map((SongModel song) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      SongArtwork(
                        songId: song.artworkId,
                        width: 62,
                        height: 62,
                        borderRadius: BorderRadius.circular(18),
                        size: 160,
                        quality: 45,
                        fallback: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                context.colors.primary,
                                context.colors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              song.title.ellipsis(28),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              song.artist.fallbackArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.60),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => onPlay(song),
                        icon: const Icon(Icons.play_arrow_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: context.colors.secondary.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.song,
    required this.controller,
    required this.onOpen,
  });

  final SongModel song;
  final PlayerController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onOpen,
        child: Ink(
          height: 88,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
              Obx(
                () => IconButton(
                  onPressed: controller.togglePlayback,
                  icon: Icon(
                    controller.isPlaying.value
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.secondary.withValues(
                      alpha: 0.18,
                    ),
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
  }
}
