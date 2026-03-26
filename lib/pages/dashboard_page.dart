import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../core/utils/extensions.dart';
import '../data/models/song_model.dart';
import '../routes/app_pages.dart';
import '../widgets/main_section_scaffold.dart';
import '../widgets/song_artwork.dart';

class DashboardPage extends GetView<HomeController> {
  const DashboardPage({super.key});

  Future<void> _refreshLibrary() async {
    await controller.loadLibrary(forceRefresh: true);
    controller.showRefreshedToast();
  }

  @override
  Widget build(BuildContext context) {
    controller.ensureInitialLibraryLoad();

    return Scaffold(
      body: MainSectionScaffold(
        currentRoute: AppPages.dashboard,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshLibrary,
            child: Obx(() {
              final List<SongModel> songs = controller.songs.toList(
                growable: false,
              );
              final List<SongModel> mostPlayed = controller.mostPlayedSongs;
              final List<SongModel> recents = controller.recentlyPlayedSongs;
              final int totalSongs = songs.length;
              final int totalFavorites = controller.favoriteIds.length;
              final int totalDownloads = controller.downloadedSongs.length;
              final int totalArtists = controller.totalArtistCount;
              final int totalFolders = controller.totalFolderCount;
              final int totalPlays = controller.totalPlayCount;
              final int listenedSongsCount = controller.listenedSongsCount;
              final double favoritesRatio = totalSongs == 0
                  ? 0
                  : totalFavorites / totalSongs;
              final double listenedRatio = totalSongs == 0
                  ? 0
                  : listenedSongsCount / totalSongs;
              final String? topArtist = controller.mostPlayedArtist;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _DashboardHeroCard(
                        title: 'Dashboard',
                        subtitle: controller.permissionGranted.value
                            ? 'Playback, favorites, saved tracks, and library totals at a glance.'
                            : 'Pull to refresh after granting audio access to complete your library insights.',
                        totalPlays: totalPlays,
                        totalSongs: totalSongs,
                        topArtist: topArtist,
                      ),
                    ),
                  ),
                  if (!controller.permissionGranted.value && songs.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.library_music_rounded,
                                  color: context.colors.secondary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Allow audio access so Dashboard can count artists, folders, and device tracks.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () => controller.loadLibrary(),
                                  child: const Text('Grant access'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _StatCard(
                            label: 'Songs',
                            value: '$totalSongs',
                            icon: Icons.music_note_rounded,
                            width: _statCardWidth(context),
                          ),
                          _StatCard(
                            label: 'Favorites',
                            value: '$totalFavorites',
                            icon: Icons.favorite_rounded,
                            width: _statCardWidth(context),
                          ),
                          _StatCard(
                            label: 'Saved',
                            value: '$totalDownloads',
                            icon: Icons.download_done_rounded,
                            width: _statCardWidth(context),
                          ),
                          _StatCard(
                            label: 'Artists',
                            value: '$totalArtists',
                            icon: Icons.mic_external_on_rounded,
                            width: _statCardWidth(context),
                          ),
                          _StatCard(
                            label: 'Folders',
                            value: '$totalFolders',
                            icon: Icons.folder_open_rounded,
                            width: _statCardWidth(context),
                          ),
                          _StatCard(
                            label: 'Plays',
                            value: '$totalPlays',
                            icon: Icons.bar_chart_rounded,
                            width: _statCardWidth(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ProgressInsightsCard(
                        favoritesRatio: favoritesRatio,
                        listenedRatio: listenedRatio,
                        listenedSongsCount: listenedSongsCount,
                        totalSongs: totalSongs,
                        topArtist: topArtist,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeading(
                        title: 'Most Played Songs',
                        subtitle: mostPlayed.isEmpty
                            ? 'Start a few tracks and this ranking will fill itself in.'
                            : 'Ranked by completed play-count triggers from your local playback history.',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: mostPlayed.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptyCard(
                              icon: Icons.multitrack_audio_rounded,
                              title: 'No ranked songs yet',
                              message:
                                  'Play a song long enough for it to count and it will appear here.',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                final SongModel song = mostPlayed[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RankedSongTile(
                                    rank: index + 1,
                                    song: song,
                                    playCount: controller.playCountFor(song.id),
                                    onTap: () => controller.playSongFromQueue(
                                      mostPlayed,
                                      song,
                                    ),
                                  ),
                                );
                              },
                              childCount: mostPlayed.length > 8
                                  ? 8
                                  : mostPlayed.length,
                            ),
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeading(
                        title: 'Recently Played',
                        subtitle: recents.isEmpty
                            ? 'Your recent queue will appear here after you start listening.'
                            : 'Quick access to the tracks you touched most recently.',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      MainSectionScaffold.bodyBottomInset(withMiniPlayer: true),
                    ),
                    sliver: SliverToBoxAdapter(
                      child: recents.isEmpty
                          ? const _EmptyCard(
                              icon: Icons.history_rounded,
                              title: 'No recent sessions yet',
                              message:
                                  'Songs you open from Home, Favorites, or search will show up here.',
                            )
                          : SizedBox(
                              height: 156,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (BuildContext context, int index) {
                                  final SongModel song = recents[index];
                                  return _RecentSongCard(
                                    song: song,
                                    playCount: controller.playCountFor(song.id),
                                    onTap: () => controller.playSongFromQueue(
                                      recents,
                                      song,
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemCount: recents.length > 6
                                    ? 6
                                    : recents.length,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  double _statCardWidth(BuildContext context) {
    final double availableWidth = MediaQuery.sizeOf(context).width - 52;
    final double cardWidth = (availableWidth - 12) / 2;
    return cardWidth < 170 ? availableWidth : cardWidth;
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({
    required this.title,
    required this.subtitle,
    required this.totalPlays,
    required this.totalSongs,
    required this.topArtist,
  });

  final String title;
  final String subtitle;
  final int totalPlays;
  final int totalSongs;
  final String? topArtist;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: <Color>[
              context.colors.primary.withValues(alpha: 0.92),
              context.colors.tertiary.withValues(alpha: 0.88),
              context.colors.secondary.withValues(alpha: 0.84),
            ],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
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
                    ).colorScheme.onPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$totalPlays plays',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _HeroMetric(
                    label: 'Library size',
                    value: totalSongs == 1 ? '1 track' : '$totalSongs tracks',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroMetric(
                    label: 'Most played artist',
                    value: topArtist ?? 'No listening history yet',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressInsightsCard extends StatelessWidget {
  const _ProgressInsightsCard({
    required this.favoritesRatio,
    required this.listenedRatio,
    required this.listenedSongsCount,
    required this.totalSongs,
    required this.topArtist,
  });

  final double favoritesRatio;
  final double listenedRatio;
  final int listenedSongsCount;
  final int totalSongs;
  final String? topArtist;

  @override
  Widget build(BuildContext context) {
    final int favoritePercent = (favoritesRatio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Library Insights',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              topArtist == null
                  ? 'We will surface deeper listening patterns as soon as play history grows.'
                  : 'Current front-runner: $topArtist',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: 'Favorite coverage',
              helper: favoritePercent == 0
                  ? 'No songs have been favorited yet.'
                  : '$favoritePercent% of your library is favorited.',
              value: favoritesRatio,
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: 'Listened coverage',
              helper: totalSongs == 0
                  ? 'Add songs to begin tracking listened coverage.'
                  : '$listenedSongsCount of $totalSongs songs have a confirmed play.',
              value: listenedRatio,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.helper,
    required this.value,
  });

  final String label;
  final String helper;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: value < 0
                ? 0
                : value > 1
                ? 1
                : value,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}

class _RankedSongTile extends StatelessWidget {
  const _RankedSongTile({
    required this.rank,
    required this.song,
    required this.playCount,
    required this.onTap,
  });

  final int rank;
  final SongModel song;
  final int playCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      context.colors.primary,
                      context.colors.tertiary,
                      context.colors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SongArtwork(
                songId: song.artworkId,
                artworkUri: song.artworkUri,
                width: 62,
                height: 62,
                borderRadius: BorderRadius.circular(20),
                size: 128,
                quality: 40,
                fallback: SongArtworkPlaceholder(
                  width: 62,
                  height: 62,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      song.title.ellipsis(30),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.artist.fallbackArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playCount == 1 ? '1 play' : '$playCount plays',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSongCard extends StatelessWidget {
  const _RecentSongCard({
    required this.song,
    required this.playCount,
    required this.onTap,
  });

  final SongModel song;
  final int playCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 156,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SongArtwork(
                  songId: song.artworkId,
                  artworkUri: song.artworkUri,
                  width: 124,
                  height: 68,
                  borderRadius: BorderRadius.circular(18),
                  size: 128,
                  quality: 40,
                  fallback: SongArtworkPlaceholder(
                    width: 124,
                    height: 68,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title.ellipsis(18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist.fallbackArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
                const Spacer(),
                Text(
                  playCount == 0 ? 'Fresh' : '$playCount plays',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
