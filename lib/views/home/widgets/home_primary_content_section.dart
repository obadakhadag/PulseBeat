import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/song_model.dart';
import '../../../pages/library_group_detail_page.dart';
import '../../../widgets/song_artwork.dart';
import 'song_list_item.dart';

class HomePrimaryContentSection extends StatelessWidget {
  const HomePrimaryContentSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final HomeBrowseCategory activeCategory = controller.browseCategory.value;
      return switch (activeCategory) {
        HomeBrowseCategory.allSongs => AllSongsContent(controller: controller),
        HomeBrowseCategory.folders => FoldersContent(controller: controller),
        HomeBrowseCategory.language => LanguageContent(controller: controller),
        HomeBrowseCategory.artist => ArtistContent(controller: controller),
      };
    });
  }
}

class AllSongsContent extends StatelessWidget {
  const AllSongsContent({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.permissionGranted.value && controller.songs.isEmpty) {
        return _SingleCardSliver(
          child: _HomeEmptyStateCard(
            icon: Icons.library_music_rounded,
            title: 'Unlock your library'.tr,
            message: 'Allow audio access so your library stays up to date.'.tr,
            action: controller.loadLibrary,
            actionLabel: 'Grant access'.tr,
          ),
        );
      }

      if (controller.isLoading.value && controller.songs.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final List<SongModel> allSongs = controller.visibleSongs.toList(
        growable: false,
      );
      final bool hideRecordings = controller.hideRecordings.value;
      final List<SongModel> displayedSongs = hideRecordings
          ? allSongs
                .where((SongModel song) => !controller.isVoiceRecording(song))
                .toList(growable: false)
          : allSongs;

      if (allSongs.isEmpty) {
        return _SingleCardSliver(
          child: _HomeEmptyStateCard(
            icon: Icons.queue_music_rounded,
            title: 'No songs found'.tr,
            message:
                'Pull down to scan again after adding music to the device.'.tr,
            action: controller.loadLibrary,
            actionLabel: 'Refresh library'.tr,
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _HomeContentHeader(
                title: 'All Songs'.tr,
                description: 'Search songs, artists, albums'.tr,
                countLabel: displayedSongs.length == 1
                    ? '1 song'.tr
                    : '@count songs'.trParams(<String, String>{
                        'count': '${displayedSongs.length}',
                      }),
                trailing: _HideRecordingsToggle(
                  value: hideRecordings,
                  onChanged: controller.setHideRecordings,
                ),
              ),
            ),
          ),
          if (displayedSongs.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _HomeEmptyStateCard(
                  icon: Icons.keyboard_voice_rounded,
                  title: 'No songs match this filter'.tr,
                  message:
                      'Turn off Hide voice recordings to show every track again.'
                          .tr,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  final SongModel song = displayedSongs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SongListItem(
                      key: ValueKey<String>('home-song-${song.id}'),
                      song: song,
                      onTap: () =>
                          controller.playSongFromQueue(displayedSongs, song),
                      onFavoriteToggle: () => controller.toggleFavorite(song),
                    ),
                  );
                }, childCount: displayedSongs.length),
              ),
            ),
        ],
      );
    });
  }
}

class FoldersContent extends StatelessWidget {
  const FoldersContent({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _GroupedContentSection(
      controller: controller,
      category: HomeBrowseCategory.folders,
    );
  }
}

class LanguageContent extends StatelessWidget {
  const LanguageContent({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _GroupedContentSection(
      controller: controller,
      category: HomeBrowseCategory.language,
    );
  }
}

class ArtistContent extends StatelessWidget {
  const ArtistContent({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _GroupedContentSection(
      controller: controller,
      category: HomeBrowseCategory.artist,
    );
  }
}

class _GroupedContentSection extends StatelessWidget {
  const _GroupedContentSection({
    required this.controller,
    required this.category,
  });

  final HomeController controller;
  final HomeBrowseCategory category;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<LibraryCollectionGroup> groups = controller
          .collectionGroupsFor(category);

      if (groups.isEmpty) {
        return _SingleCardSliver(
          child: _HomeEmptyStateCard(
            icon: switch (category) {
              HomeBrowseCategory.folders => Icons.folder_open_rounded,
              HomeBrowseCategory.language => Icons.translate_rounded,
              HomeBrowseCategory.artist => Icons.mic_external_on_rounded,
              HomeBrowseCategory.allSongs => Icons.queue_music_rounded,
            },
            title: 'This category is empty'.tr,
            message: 'We could not find any items for this section yet.'.tr,
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _HomeContentHeader(
                title: switch (category) {
                  HomeBrowseCategory.folders => 'Folders'.tr,
                  HomeBrowseCategory.language => 'Language'.tr,
                  HomeBrowseCategory.artist => 'Artist'.tr,
                  HomeBrowseCategory.allSongs => 'All Songs'.tr,
                },
                description: switch (category) {
                  HomeBrowseCategory.folders =>
                    'Browse device folders and open the songs inside each one.'
                        .tr,
                  HomeBrowseCategory.language =>
                    'Explore songs grouped by detected metadata language.'.tr,
                  HomeBrowseCategory.artist =>
                    'Jump into artist-based groupings from your library.'.tr,
                  HomeBrowseCategory.allSongs =>
                    'Search songs, artists, albums'.tr,
                },
                countLabel: groups.length == 1
                    ? '1 group'.tr
                    : '@count groups'.trParams(<String, String>{
                        'count': '${groups.length}',
                      }),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final LibraryCollectionGroup group = groups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LibraryCollectionCard(
                    category: category,
                    group: group,
                    onTap: () => Get.to<void>(
                      () => LibraryGroupDetailPage(
                        title: group.title,
                        subtitle: group.subtitle,
                        songs: group.songs,
                      ),
                    ),
                  ),
                );
              }, childCount: groups.length),
            ),
          ),
        ],
      );
    });
  }
}

class _SingleCardSliver extends StatelessWidget {
  const _SingleCardSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: child,
      ),
    );
  }
}

class _HomeContentHeader extends StatelessWidget {
  const _HomeContentHeader({
    required this.title,
    required this.description,
    required this.countLabel,
    this.trailing,
  });

  final String title;
  final String description;
  final String countLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget countChip = DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              countLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );
        Widget buildTrailingGroup(WrapAlignment alignment) {
          return Wrap(
            alignment: alignment,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[countChip, if (trailing != null) trailing!],
          );
        }

        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 12),
              buildTrailingGroup(WrapAlignment.start),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            Flexible(child: buildTrailingGroup(WrapAlignment.end)),
          ],
        );
      },
    );
  }
}

class _HideRecordingsToggle extends StatelessWidget {
  const _HideRecordingsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 4,
          end: 12,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: value,
                onChanged: (bool? nextValue) => onChanged(nextValue ?? false),
                activeColor: theme.colorScheme.secondary,
                checkColor: theme.colorScheme.onPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.36),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Hide voice recordings'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyStateCard extends StatelessWidget {
  const _HomeEmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final String buttonLabel = actionLabel ?? '';

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
            if (action != null && buttonLabel.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: action, child: Text(buttonLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryCollectionCard extends StatelessWidget {
  const _LibraryCollectionCard({
    required this.category,
    required this.group,
    required this.onTap,
  });

  final HomeBrowseCategory category;
  final LibraryCollectionGroup group;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (category) {
      HomeBrowseCategory.folders => Icons.folder_copy_rounded,
      HomeBrowseCategory.language => Icons.translate_rounded,
      HomeBrowseCategory.artist => Icons.mic_external_on_rounded,
      HomeBrowseCategory.allSongs => Icons.queue_music_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CollectionPreview(song: group.previewSong, icon: _icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            group.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.64),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.subtitle ??
                          'Songs inside this group will open on the next page.'
                              .tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _CollectionInfoChip(
                          label: group.count == 1
                              ? '1 song'.tr
                              : '@count songs'.trParams(<String, String>{
                                  'count': '${group.count}',
                                }),
                        ),
                        _CollectionInfoChip(
                          label: switch (category) {
                            HomeBrowseCategory.folders => 'Folder'.tr,
                            HomeBrowseCategory.language => 'Language'.tr,
                            HomeBrowseCategory.artist => 'Artist'.tr,
                            HomeBrowseCategory.allSongs => 'All Songs'.tr,
                          },
                        ),
                      ],
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

class _CollectionInfoChip extends StatelessWidget {
  const _CollectionInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.70),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CollectionPreview extends StatelessWidget {
  const _CollectionPreview({required this.song, required this.icon});

  final SongModel? song;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final SongModel? previewSong = song;
    final Widget fallback = SongArtworkPlaceholder(
      width: 60,
      height: 60,
      borderRadius: BorderRadius.circular(20),
      icon: icon,
    );

    if (previewSong == null) {
      return fallback;
    }

    return SongArtwork(
      songId: previewSong.artworkId,
      artworkUri: previewSong.artworkUri,
      width: 60,
      height: 60,
      borderRadius: BorderRadius.circular(20),
      size: 160,
      quality: 55,
      fallback: fallback,
    );
  }
}
