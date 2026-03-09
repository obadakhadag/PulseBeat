import 'package:get_storage/get_storage.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  StorageService(this._boxName);

  final String _boxName;
  GetStorage? _box;
  Future<void>? _initialization;

  Future<void> ensureInitialized() {
    _initialization ??= _initialize();
    return _initialization!;
  }

  Future<void> _initialize() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
  }

  GetStorage? get _maybeBox => _box;

  Set<int> getFavoriteIds() {
    final GetStorage? box = _maybeBox;
    if (box == null) {
      return <int>{};
    }

    return (box.read<List<dynamic>>(AppConstants.favoritesKey) ?? <dynamic>[])
        .map((dynamic item) => item as int)
        .toSet();
  }

  void setFavoriteIds(Set<int> ids) {
    _maybeBox?.write(AppConstants.favoritesKey, ids.toList(growable: false));
  }

  List<int> getRecentIds() {
    final GetStorage? box = _maybeBox;
    if (box == null) {
      return const <int>[];
    }

    return (box.read<List<dynamic>>(AppConstants.recentKey) ?? <dynamic>[])
        .map((dynamic item) => item as int)
        .toList(growable: false);
  }

  void setRecentIds(List<int> ids) {
    _maybeBox?.write(AppConstants.recentKey, ids);
  }

  Map<int, int> getPlayCounts() {
    final GetStorage? box = _maybeBox;
    if (box == null) {
      return <int, int>{};
    }

    final raw = box.read<dynamic>(AppConstants.playCountsKey);
    if (raw is! Map<dynamic, dynamic>) {
      return <int, int>{};
    }

    final values = <int, int>{};
    raw.forEach((dynamic key, dynamic value) {
      final songId = int.tryParse(key.toString());
      final count = switch (value) {
        int count => count,
        num count => count.toInt(),
        _ => int.tryParse(value.toString()) ?? 0,
      };
      if (songId != null && songId > 0 && count > 0) {
        values[songId] = count;
      }
    });
    return values;
  }

  void setPlayCounts(Map<int, int> values) {
    _maybeBox?.write(
      AppConstants.playCountsKey,
      values.map(
        (int key, int value) => MapEntry<String, int>(key.toString(), value),
      ),
    );
  }

  String getSortOrder() =>
      _maybeBox?.read<String>(AppConstants.sortKey) ?? 'newest';

  void setSortOrder(String value) {
    _maybeBox?.write(AppConstants.sortKey, value);
  }

  String getLibraryGroup() =>
      _maybeBox?.read<String>(AppConstants.groupKey) ?? 'folder';

  void setLibraryGroup(String value) {
    _maybeBox?.write(AppConstants.groupKey, value);
  }

  bool getShowLyrics() =>
      _maybeBox?.read<bool>(AppConstants.showLyricsKey) ?? true;

  void setShowLyrics(bool value) {
    _maybeBox?.write(AppConstants.showLyricsKey, value);
  }

  bool getImmersivePlayer() =>
      _maybeBox?.read<bool>(AppConstants.immersivePlayerKey) ?? true;

  void setImmersivePlayer(bool value) {
    _maybeBox?.write(AppConstants.immersivePlayerKey, value);
  }

  String getThemeMode() =>
      _maybeBox?.read<String>(AppConstants.themeModeKey) ?? 'dark';

  void setThemeMode(String value) {
    _maybeBox?.write(AppConstants.themeModeKey, value);
  }
}
