import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../data/models/song_model.dart';
import '../data/repositories/audio_repository.dart';
import '../routes/app_pages.dart';
import '../services/permissions_service.dart';
import '../services/storage_service.dart';
import 'player_controller.dart';

enum LibrarySort { newest, title, artist, duration }

enum LibraryGroup { folder, titleLanguage, artist }

enum HomeSection { all, favorites, recents, mostPlayed }

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
  final RxList<LibraryEntry> libraryEntries = <LibraryEntry>[].obs;
  final RxBool showScrollToTop = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  Future<void> onInit() async {
    super.onInit();
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
    await loadLibrary();
  }

  Future<void> loadLibrary() async {
    isLoading.value = true;
    permissionGranted.value = await _permissionsService.requestAudioAccess();
    if (!permissionGranted.value) {
      isLoading.value = false;
      return;
    }

    try {
      final results = await _audioRepository.loadDeviceSongs();
      songs.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) => searchQuery.value = value;
  void setSection(HomeSection value) => section.value = value;

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
    return count == 1 ? '1 play' : '$count plays';
  }

  void toggleFavorite(SongModel song) {
    final updated = favoriteIds.toSet();
    if (!updated.add(song.id)) {
      updated.remove(song.id);
    }
    favoriteIds
      ..clear()
      ..addAll(updated);
    _storageService.setFavoriteIds(updated);
  }

  Future<void> playSong(SongModel song) async {
    final List<SongModel> activeQueue = visibleSongs.isNotEmpty
        ? visibleSongs.toList(growable: false)
        : songs.toList(growable: false);
    await _playerController.playFromQueue(activeQueue, song);
    _rememberRecent(song.id);
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
        key == 'unknown-folder' ? 'Unknown folder' : key.split('/').last,
      LibraryGroup.titleLanguage => switch (key) {
        'arabic' => 'Arabic titles',
        'english' => 'English titles',
        _ => 'Other titles',
      },
      LibraryGroup.artist => key == '<unknown>' ? 'Unknown Artist' : key,
    };
  }

  String? _groupSubtitle(String key) {
    return switch (group.value) {
      LibraryGroup.folder => key == 'unknown-folder' ? null : key,
      LibraryGroup.titleLanguage => switch (key) {
        'arabic' => 'Tracks with Arabic script in the title',
        'english' => 'Tracks with Latin script in the title',
        _ => 'Tracks without clear Arabic or English letters',
      },
      LibraryGroup.artist => null,
    };
  }

  String get statsLabel {
    final totalTracks = songs.length;
    final favCount = favoriteIds.length;
    final plays = totalPlayCount;
    return '$totalTracks tracks - $favCount favorites - $plays plays';
  }

  int get totalPlayCount {
    return _playerController.playCounts.values.fold<int>(
      0,
      (int total, int item) => total + item,
    );
  }

  String get headline {
    return switch (section.value) {
      HomeSection.all => 'Fresh from your device',
      HomeSection.favorites => 'Your saved essentials',
      HomeSection.recents => 'Recently played heat',
      HomeSection.mostPlayed => 'Heavy rotation',
    };
  }

  String get sectionLabel {
    return switch (section.value) {
      HomeSection.all => 'All songs',
      HomeSection.favorites => 'Favorites',
      HomeSection.recents => 'Recents',
      HomeSection.mostPlayed => 'Most played',
    };
  }

  String get groupLabel {
    return switch (group.value) {
      LibraryGroup.folder => 'Folder',
      LibraryGroup.titleLanguage => 'Title language',
      LibraryGroup.artist => 'Artist',
    };
  }

  String get sortLabel {
    if (section.value == HomeSection.mostPlayed) {
      return 'Play count';
    }
    return switch (sort.value) {
      LibrarySort.newest => 'Newest',
      LibrarySort.title => 'Title',
      LibrarySort.artist => 'Artist',
      LibrarySort.duration => 'Duration',
    };
  }

  String get subline {
    if (!permissionGranted.value) {
      return 'Allow audio access to build your library.';
    }
    if (songs.isEmpty) {
      return 'No audio files found yet.';
    }
    if (section.value == HomeSection.mostPlayed) {
      return 'Songs ranked by how often you start them.';
    }
    return statsLabel;
  }

  void showRefreshedToast() {
    AppHelpers.showToast('Library refreshed');
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

  @override
  void onClose() {
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.onClose();
  }
}
