import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/utils/library_identity.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../data/models/song_model.dart';
import '../data/repositories/audio_repository.dart';
import '../routes/app_pages.dart';
import '../services/permissions_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import 'app_controller.dart';
import 'auth_controller.dart';
import 'player_controller.dart';

enum LibrarySort { newest, title, artist, duration }

enum LibraryGroup { folder, titleLanguage, artist }

enum HomeSection { all, favorites, recents, mostPlayed }

enum HomeBrowseCategory { allSongs, folders, language, artist }

abstract class LibraryEntry {
  const LibraryEntry();
}

class LibraryHeaderEntry extends LibraryEntry {
  const LibraryHeaderEntry({
    required this.title,
    required this.count,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int count;
}

class LibrarySongEntry extends LibraryEntry {
  const LibrarySongEntry(this.song);

  final SongModel song;
}

class LibraryCollectionGroup {
  const LibraryCollectionGroup({
    required this.key,
    required this.title,
    required this.songs,
    this.subtitle,
  });

  final String key;
  final String title;
  final String? subtitle;
  final List<SongModel> songs;

  int get count => songs.length;
  SongModel? get previewSong => songs.isEmpty ? null : songs.first;
}

class HomeController extends GetxController {
  HomeController({
    required AudioRepository audioRepository,
    required PermissionsService permissionsService,
    required StorageService storageService,
    required PlayerController playerController,
  }) : _audioRepository = audioRepository,
       _permissionsService = permissionsService,
       _storageService = storageService,
       _playerController = playerController;

  final AudioRepository _audioRepository;
  final PermissionsService _permissionsService;
  final StorageService _storageService;
  final PlayerController _playerController;

  final RxBool isLoading = false.obs;
  final RxBool permissionGranted = false.obs;
  final RxList<SongModel> songs = <SongModel>[].obs;
  final RxList<SongModel> visibleSongs = <SongModel>[].obs;
  final RxSet<int> favoriteIds = <int>{}.obs;
  final RxList<int> recentIds = <int>[].obs;
  final RxString searchQuery = ''.obs;
  final Rx<LibrarySort> sort = LibrarySort.newest.obs;
  final Rx<LibraryGroup> group = LibraryGroup.folder.obs;
  final Rx<HomeSection> section = HomeSection.all.obs;
  final Rx<HomeBrowseCategory> browseCategory = HomeBrowseCategory.allSongs.obs;
  final RxList<LibraryEntry> libraryEntries = <LibraryEntry>[].obs;
  final RxBool showScrollToTop = false.obs;
  final ScrollController scrollController = ScrollController();
  bool _didRequestInitialLibraryLoad = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _storageService.ensureInitialized();
    scrollController.addListener(_handleScroll);
    favoriteIds.addAll(_storageService.getFavoriteIds());
    recentIds.assignAll(_storageService.getRecentIds());
    sort.value = LibrarySort.values.firstWhere(
      (LibrarySort item) => item.name == _storageService.getSortOrder(),
      orElse: () => LibrarySort.newest,
    );
    group.value = LibraryGroup.values.firstWhere(
      (LibraryGroup item) => item.name == _storageService.getLibraryGroup(),
      orElse: () => LibraryGroup.folder,
    );
    everAll(<RxInterface<dynamic>>[
      songs,
      favoriteIds,
      recentIds,
      _playerController.playCounts,
      searchQuery,
      sort,
      group,
      section,
    ], (_) => _applyFilters());
  }

  void ensureInitialLibraryLoad() {
    if (_didRequestInitialLibraryLoad) {
      return;
    }
    _didRequestInitialLibraryLoad = true;
    unawaited(loadLibrary());
  }

  Future<void> loadLibrary({bool forceRefresh = false}) async {
    if (isLoading.value) {
      return;
    }
    if (!forceRefresh && songs.isNotEmpty) {
      return;
    }

    isLoading.value = true;
    final bool hasPermission = permissionGranted.value
        ? true
        : await _permissionsService.requestAudioAccess();
    permissionGranted.value = hasPermission;

    try {
      final List<SongModel> results = await _audioRepository.loadDeviceSongs(
        forceRefresh: forceRefresh,
        includeDeviceSongs: permissionGranted.value,
      );
      if (!_hasSameSongs(songs, results)) {
        songs.assignAll(results);
      }
      unawaited(_cacheAndMaybeSyncLibrary(results));
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) => searchQuery.value = value;
  void setSection(HomeSection value) => section.value = value;
  void setBrowseCategory(HomeBrowseCategory value) =>
      browseCategory.value = value;

  void setSort(LibrarySort value) {
    sort.value = value;
    _storageService.setSortOrder(value.name);
  }

  void setGroup(LibraryGroup value) {
    group.value = value;
    _storageService.setLibraryGroup(value.name);
  }

  bool isFavorite(int songId) => favoriteIds.contains(songId);
  int playCountFor(int songId) => _playerController.playCounts[songId] ?? 0;

  String playCountLabel(int songId) {
    final count = playCountFor(songId);
    return count == 1
        ? '1 play'.tr
        : '@count plays'.trParams(<String, String>{'count': '$count'});
  }

  void toggleFavorite(SongModel song) {
    if (favoriteIds.contains(song.id)) {
      favoriteIds.remove(song.id);
    } else {
      favoriteIds.add(song.id);
    }
    favoriteIds.refresh();
    _storageService.setFavoriteIds(favoriteIds.toSet());
  }

  Future<void> playSong(SongModel song) async {
    final List<SongModel> activeQueue = visibleSongs.isNotEmpty
        ? visibleSongs.toList(growable: false)
        : songs.toList(growable: false);
    await playSongFromQueue(activeQueue, song);
  }

  Future<void> playSongFromQueue(
    List<SongModel> songQueue,
    SongModel selectedSong,
  ) async {
    final List<SongModel> activeQueue = songQueue.isNotEmpty
        ? songQueue.toList(growable: false)
        : songs.toList(growable: false);
    await _playerController.playFromQueue(activeQueue, selectedSong);
    _rememberRecent(selectedSong.id);
    Get.toNamed(AppPages.player);
  }

  void openPlayerIfAvailable() {
    if (_playerController.currentSong.value == null) {
      _playerController.announceMissingQueue();
      return;
    }
    Get.toNamed(AppPages.player);
  }

  Future<void> openAppSettings() => _permissionsService.openSettings();

  List<SongModel> get featuredSongs =>
      visibleSongs.take(5).toList(growable: false);

  List<SongModel> get downloadedSongs => songs
      .where(
        (SongModel song) => song.normalizedFilePath.toLowerCase().contains(
          '/${AppConstants.downloadedSongsFolder.toLowerCase()}/',
        ),
      )
      .toList(growable: false);

  List<SongModel> get recentlyPlayedSongs => recentIds
      .map(findSongById)
      .whereType<SongModel>()
      .toList(growable: false);

  List<SongModel> get mostPlayedSongs {
    final List<SongModel> ranked = songs
        .where((SongModel song) => playCountFor(song.id) > 0)
        .toList(growable: false);
    ranked.sort((SongModel a, SongModel b) {
      final int playDifference = playCountFor(
        b.id,
      ).compareTo(playCountFor(a.id));
      if (playDifference != 0) {
        return playDifference;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return ranked;
  }

  int get listenedSongsCount =>
      songs.where((SongModel song) => playCountFor(song.id) > 0).length;

  int get totalArtistCount => songs
      .map(
        (SongModel song) =>
            song.artist.trim().isEmpty ? '<unknown>' : song.artist.trim(),
      )
      .toSet()
      .length;

  int get totalFolderCount => songs
      .map(
        (SongModel song) => song.folderPath.trim().isEmpty
            ? 'unknown-folder'
            : song.folderPath.trim(),
      )
      .toSet()
      .length;

  String? get mostPlayedArtist {
    if (songs.isEmpty || totalPlayCount == 0) {
      return null;
    }

    final Map<String, int> artistCounts = <String, int>{};
    for (final SongModel song in songs) {
      final int count = playCountFor(song.id);
      if (count <= 0) {
        continue;
      }

      final String artist = song.artist.trim().isEmpty
          ? 'Unknown Artist'.tr
          : song.artist.trim();
      artistCounts[artist] = (artistCounts[artist] ?? 0) + count;
    }

    if (artistCounts.isEmpty) {
      return null;
    }

    final List<MapEntry<String, int>> rankedArtists =
        artistCounts.entries.toList()
          ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
            final int difference = b.value.compareTo(a.value);
            if (difference != 0) {
              return difference;
            }
            return a.key.toLowerCase().compareTo(b.key.toLowerCase());
          });

    return rankedArtists.first.key;
  }

  List<LibraryCollectionGroup> collectionGroupsFor(
    HomeBrowseCategory category,
  ) {
    final List<SongModel> source = visibleSongs.toList(growable: false);
    return switch (category) {
      HomeBrowseCategory.allSongs => const <LibraryCollectionGroup>[],
      HomeBrowseCategory.folders => _buildCollectionGroups(
        source: source,
        keyOf: (SongModel song) =>
            song.folderPath.isEmpty ? 'unknown-folder' : song.folderPath,
        titleOf: (String key) =>
            key == 'unknown-folder' ? 'Unknown folder'.tr : key.split('/').last,
        subtitleOf: (String key) => key == 'unknown-folder' ? null : key,
      ),
      HomeBrowseCategory.language => _buildLanguageCollectionGroups(source),
      HomeBrowseCategory.artist => _buildCollectionGroups(
        source: source,
        keyOf: (SongModel song) {
          final String artist = song.artist.trim();
          return artist.isEmpty || artist == '<unknown>' ? '<unknown>' : artist;
        },
        titleOf: (String key) => key == '<unknown>' ? 'Unknown Artist'.tr : key,
      ),
    };
  }

  void refreshPresentation() => _applyFilters();

  SongModel? findSongById(int id) {
    for (final song in songs) {
      if (song.id == id) {
        return song;
      }
    }
    return null;
  }

  void _rememberRecent(int id) {
    final updated = <int>[
      id,
      ...recentIds.where((int item) => item != id),
    ].take(AppConstants.recentLimit).toList(growable: false);
    recentIds.assignAll(updated);
    _storageService.setRecentIds(updated);
  }

  void _applyFilters() {
    Iterable<SongModel> result = songs;

    switch (section.value) {
      case HomeSection.all:
        break;
      case HomeSection.favorites:
        result = result.where(
          (SongModel song) => favoriteIds.contains(song.id),
        );
      case HomeSection.recents:
        final order = recentIds.toList(growable: false);
        result = order.map(findSongById).whereType<SongModel>();
      case HomeSection.mostPlayed:
        break;
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where(
        (SongModel song) =>
            song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query),
      );
    }

    final sorted = result.toList(growable: false);
    if (section.value == HomeSection.mostPlayed) {
      sorted.sort((SongModel a, SongModel b) {
        final difference = playCountFor(b.id).compareTo(playCountFor(a.id));
        if (difference != 0) {
          return difference;
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      switch (sort.value) {
        case LibrarySort.newest:
          break;
        case LibrarySort.title:
          sorted.sort(
            (SongModel a, SongModel b) =>
                a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        case LibrarySort.artist:
          sorted.sort(
            (SongModel a, SongModel b) =>
                a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
          );
        case LibrarySort.duration:
          sorted.sort(
            (SongModel a, SongModel b) => b.duration.compareTo(a.duration),
          );
      }
    }

    visibleSongs.assignAll(sorted);
    libraryEntries.assignAll(_buildEntries(sorted));
  }

  List<LibraryEntry> _buildEntries(List<SongModel> sortedSongs) {
    if (sortedSongs.isEmpty) {
      return const <LibraryEntry>[];
    }

    final groupedSongs = <String, List<SongModel>>{};
    for (final song in sortedSongs) {
      final key = _groupKey(song);
      groupedSongs.putIfAbsent(key, () => <SongModel>[]).add(song);
    }

    final entries = <LibraryEntry>[];
    for (final entry in groupedSongs.entries) {
      entries.add(
        LibraryHeaderEntry(
          title: _groupTitle(entry.key),
          subtitle: _groupSubtitle(entry.key),
          count: entry.value.length,
        ),
      );
      entries.addAll(entry.value.map(LibrarySongEntry.new));
    }
    return entries;
  }

  String _groupKey(SongModel song) {
    return switch (group.value) {
      LibraryGroup.folder =>
        song.folderPath.isEmpty ? 'unknown-folder' : song.folderPath,
      LibraryGroup.titleLanguage => song.titleLanguageKey,
      LibraryGroup.artist =>
        song.artist.trim().isEmpty ? '<unknown>' : song.artist,
    };
  }

  String _groupTitle(String key) {
    return switch (group.value) {
      LibraryGroup.folder =>
        key == 'unknown-folder' ? 'Unknown folder'.tr : key.split('/').last,
      LibraryGroup.titleLanguage => switch (key) {
        'arabic' => 'Arabic tracks'.tr,
        'english' => 'English tracks'.tr,
        _ => 'Other tracks'.tr,
      },
      LibraryGroup.artist => key == '<unknown>' ? 'Unknown Artist'.tr : key,
    };
  }

  String? _groupSubtitle(String key) {
    return switch (group.value) {
      LibraryGroup.folder => key == 'unknown-folder' ? null : key,
      LibraryGroup.titleLanguage => switch (key) {
        'arabic' => 'Tracks grouped by Arabic metadata.'.tr,
        'english' => 'Tracks grouped by English metadata.'.tr,
        _ => 'Tracks without clear Arabic or English metadata.'.tr,
      },
      LibraryGroup.artist => null,
    };
  }

  String get statsLabel {
    final totalTracks = songs.length;
    final favCount = favoriteIds.length;
    final plays = totalPlayCount;
    return '@tracks tracks - @favorites favorites - @plays plays'.trParams(
      <String, String>{
        'tracks': '$totalTracks',
        'favorites': '$favCount',
        'plays': '$plays',
      },
    );
  }

  int get totalPlayCount {
    return _playerController.playCounts.values.fold<int>(
      0,
      (int total, int item) => total + item,
    );
  }

  String get headline {
    return switch (section.value) {
      HomeSection.all => 'Fresh from your device'.tr,
      HomeSection.favorites => 'Your saved essentials'.tr,
      HomeSection.recents => 'Recently played heat'.tr,
      HomeSection.mostPlayed => 'Heavy rotation'.tr,
    };
  }

  String get sectionLabel {
    return switch (section.value) {
      HomeSection.all => 'All Songs'.tr,
      HomeSection.favorites => 'Favorites'.tr,
      HomeSection.recents => 'Recents'.tr,
      HomeSection.mostPlayed => 'Most played'.tr,
    };
  }

  String get groupLabel {
    return switch (group.value) {
      LibraryGroup.folder => 'Folder'.tr,
      LibraryGroup.titleLanguage => 'Language'.tr,
      LibraryGroup.artist => 'Artist'.tr,
    };
  }

  String get sortLabel {
    if (section.value == HomeSection.mostPlayed) {
      return 'Plays'.tr;
    }
    return switch (sort.value) {
      LibrarySort.newest => 'Newest'.tr,
      LibrarySort.title => 'Title'.tr,
      LibrarySort.artist => 'Artist'.tr,
      LibrarySort.duration => 'Duration'.tr,
    };
  }

  String get subline {
    if (!permissionGranted.value) {
      return 'Allow audio access to build your library.'.tr;
    }
    if (songs.isEmpty) {
      return 'No audio files found yet.'.tr;
    }
    if (section.value == HomeSection.mostPlayed) {
      return 'Songs ranked by how often you start them.'.tr;
    }
    return statsLabel;
  }

  void showRefreshedToast() {
    AppHelpers.showToast('Library refreshed'.tr);
  }

  Future<void> scrollToTop() async {
    if (!scrollController.hasClients) {
      return;
    }
    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    final shouldShow = scrollController.offset > 520;
    if (showScrollToTop.value != shouldShow) {
      showScrollToTop.value = shouldShow;
    }
  }

  Future<void> _cacheAndMaybeSyncLibrary(List<SongModel> librarySongs) async {
    final List<String> libraryIds = buildLibrarySongIds(librarySongs);
    _storageService.setCachedLibrarySongIds(libraryIds);

    try {
      final AppController appController = Get.find<AppController>();
      if (!appController.isOnline) {
        return;
      }

      final AuthController authController = Get.find<AuthController>();
      final String currentUid = authController.uid?.trim() ?? '';
      if (currentUid.isEmpty) {
        return;
      }

      final String signature = buildLibraryIdsSignature(libraryIds);
      if (_storageService.getLastLibrarySyncUid() == currentUid &&
          _storageService.getLastLibrarySyncSignature() == signature) {
        return;
      }

      await Get.find<UserService>().syncUserLibrary(
        uid: currentUid,
        libraryIds: libraryIds,
      );

      _storageService.setLastLibrarySyncUid(currentUid);
      _storageService.setLastLibrarySyncSignature(signature);
    } catch (_) {
      // Keep local library loading resilient even if cloud sync is unavailable.
    }
  }

  bool _hasSameSongs(List<SongModel> current, List<SongModel> next) {
    if (identical(current, next)) {
      return true;
    }
    if (current.length != next.length) {
      return false;
    }
    for (int index = 0; index < current.length; index++) {
      final SongModel a = current[index];
      final SongModel b = next[index];
      if (a.id != b.id || a.uri != b.uri || a.filePath != b.filePath) {
        return false;
      }
    }
    return true;
  }

  List<LibraryCollectionGroup> _buildCollectionGroups({
    required List<SongModel> source,
    required String Function(SongModel song) keyOf,
    required String Function(String key) titleOf,
    String? Function(String key)? subtitleOf,
  }) {
    if (source.isEmpty) {
      return const <LibraryCollectionGroup>[];
    }

    final Map<String, List<SongModel>> groupedSongs =
        <String, List<SongModel>>{};
    for (final SongModel song in source) {
      groupedSongs.putIfAbsent(keyOf(song), () => <SongModel>[]).add(song);
    }

    final List<String> orderedKeys = groupedSongs.keys.toList(growable: false)
      ..sort((String a, String b) {
        return titleOf(a).toLowerCase().compareTo(titleOf(b).toLowerCase());
      });

    return orderedKeys
        .map((String key) {
          final List<SongModel> songsForKey =
              groupedSongs[key] ?? const <SongModel>[];
          return LibraryCollectionGroup(
            key: key,
            title: titleOf(key),
            subtitle: subtitleOf?.call(key),
            songs: songsForKey.toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  List<LibraryCollectionGroup> _buildLanguageCollectionGroups(
    List<SongModel> source,
  ) {
    if (source.isEmpty) {
      return const <LibraryCollectionGroup>[];
    }

    final Map<String, List<SongModel>> groupedSongs =
        <String, List<SongModel>>{};
    for (final SongModel song in source) {
      groupedSongs
          .putIfAbsent(song.titleLanguageKey, () => <SongModel>[])
          .add(song);
    }

    const List<String> order = <String>['arabic', 'english', 'other'];
    return order
        .where(groupedSongs.containsKey)
        .map((String key) {
          final List<SongModel> songsForKey =
              groupedSongs[key] ?? const <SongModel>[];
          return LibraryCollectionGroup(
            key: key,
            title: switch (key) {
              'arabic' => 'Arabic'.tr,
              'english' => 'English'.tr,
              _ => 'Other'.tr,
            },
            subtitle: switch (key) {
              'arabic' => 'Tracks grouped by Arabic metadata.'.tr,
              'english' => 'Tracks grouped by English metadata.'.tr,
              _ => 'Tracks without clear Arabic or English metadata.'.tr,
            },
            songs: songsForKey.toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.onClose();
  }
}
