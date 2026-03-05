import 'package:get_storage/get_storage.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  StorageService(this._box);

  final GetStorage _box;

  Set<int> getFavoriteIds() {
    return (_box.read<List<dynamic>>(AppConstants.favoritesKey) ?? <dynamic>[])
        .map((dynamic item) => item as int)
        .toSet();
  }

  void setFavoriteIds(Set<int> ids) {
    _box.write(AppConstants.favoritesKey, ids.toList(growable: false));
  }

  List<int> getRecentIds() {
    return (_box.read<List<dynamic>>(AppConstants.recentKey) ?? <dynamic>[])
        .map((dynamic item) => item as int)
        .toList(growable: false);
  }

  void setRecentIds(List<int> ids) {
    _box.write(AppConstants.recentKey, ids);
  }

  Map<int, int> getPlayCounts() {
    final raw = _box.read<dynamic>(AppConstants.playCountsKey);
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
    _box.write(
      AppConstants.playCountsKey,
      values.map(
        (int key, int value) => MapEntry<String, int>(key.toString(), value),
      ),
    );
  }

  String getSortOrder() => _box.read<String>(AppConstants.sortKey) ?? 'newest';

  void setSortOrder(String value) {
    _box.write(AppConstants.sortKey, value);
  }

  String getLibraryGroup() =>
      _box.read<String>(AppConstants.groupKey) ?? 'folder';

  void setLibraryGroup(String value) {
    _box.write(AppConstants.groupKey, value);
  }

  bool getShowLyrics() => _box.read<bool>(AppConstants.showLyricsKey) ?? true;

  void setShowLyrics(bool value) {
    _box.write(AppConstants.showLyricsKey, value);
  }

  bool getImmersivePlayer() =>
      _box.read<bool>(AppConstants.immersivePlayerKey) ?? true;

  void setImmersivePlayer(bool value) {
    _box.write(AppConstants.immersivePlayerKey, value);
  }

  String getThemeMode() =>
      _box.read<String>(AppConstants.themeModeKey) ?? 'dark';

  void setThemeMode(String value) {
    _box.write(AppConstants.themeModeKey, value);
  }
}
