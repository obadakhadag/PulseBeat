import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../core/utils/extensions.dart';
import '../data/models/song_model.dart';
import '../views/home/widgets/song_list_item.dart';
import '../routes/app_pages.dart';
import '../widgets/main_section_scaffold.dart';

class FavoriteSongsPage extends GetView<HomeController> {
  const FavoriteSongsPage({super.key});

  List<SongModel> _favoriteSongs(HomeController controller) {
    return controller.songs
        .where((SongModel song) => controller.favoriteIds.contains(song.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    controller.ensureInitialLibraryLoad();

    return Scaffold(
      body: MainSectionScaffold(
        currentRoute: AppPages.favoriteSongs,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            final List<SongModel> songs = _favoriteSongs(controller);
            final bool isLoading =
                controller.isLoading.value && controller.songs.isEmpty;

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Favorites'.tr,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All the tracks you have liked in one place.'.tr,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              context.colors.primary,
                              context.colors.tertiary,
                              context.colors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${songs.length}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                    child: isLoading
                        ? const _FavoriteLoadingState(
                            key: ValueKey<String>('favorites-loading'),
                          )
                        : songs.isEmpty
                        ? const _FavoriteEmptyState(
                            key: ValueKey<String>('favorites-empty'),
                          )
                        : ListView.separated(
                            key: ValueKey<String>(
                              'favorites-list-${songs.length}',
                            ),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              MainSectionScaffold.bodyBottomInset(
                                withMiniPlayer: true,
                              ),
                            ),
                            itemCount: songs.length + 1,
                            separatorBuilder: (_, int index) =>
                                SizedBox(height: index == 0 ? 18 : 12),
                            itemBuilder: (BuildContext context, int index) {
                              if (index == 0) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                context.colors.primary,
                                                context.colors.tertiary,
                                                context.colors.secondary,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Liked songs'.tr,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'This page reads the same favorite IDs used across Home and Dashboard.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.70,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final SongModel song = songs[index - 1];
                              return SongListItem(
                                key: ValueKey<String>(
                                  'favorite-song-${song.id}',
                                ),
                                song: song,
                                onTap: () =>
                                    controller.playSongFromQueue(songs, song),
                                onFavoriteToggle: () =>
                                    controller.toggleFavorite(song),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _FavoriteLoadingState extends StatelessWidget {
  const _FavoriteLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _FavoriteEmptyState extends StatelessWidget {
  const _FavoriteEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 34,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'No favorite songs yet'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the heart on any song and it will show up here.'.tr,
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
        ),
      ),
    );
  }
}
