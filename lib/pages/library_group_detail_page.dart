import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../data/models/song_model.dart';
import '../views/home/widgets/song_list_item.dart';
import '../widgets/music_page_background.dart';

class LibraryGroupDetailPage extends StatelessWidget {
  const LibraryGroupDetailPage({
    super.key,
    required this.title,
    required this.songs,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      body: MusicPageBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final Widget headerText = Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle ??
                                (songs.length == 1
                                    ? '1 song'.tr
                                    : '@count songs'.trParams(<String, String>{
                                        'count': '${songs.length}',
                                      })),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.70),
                                ),
                          ),
                        ],
                      ),
                    );

                    if (constraints.maxWidth < 430) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Back'.tr,
                                onPressed: () => Get.back<void>(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const SizedBox(width: 10),
                              headerText,
                            ],
                          ),
                          if (songs.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => controller.playSongFromQueue(
                                songs,
                                songs.first,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text('Play'.tr),
                            ),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Back'.tr,
                          onPressed: () => Get.back<void>(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                        headerText,
                        if (songs.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => controller.playSongFromQueue(
                              songs,
                              songs.first,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text('Play'.tr),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.music_off_rounded, size: 36),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No songs in this section.'.tr,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: songs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final SongModel song = songs[index];
                          return SongListItem(
                            key: ValueKey<String>('library-group-${song.id}'),
                            song: song,
                            onTap: () =>
                                controller.playSongFromQueue(songs, song),
                            onFavoriteToggle: () =>
                                controller.toggleFavorite(song),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
