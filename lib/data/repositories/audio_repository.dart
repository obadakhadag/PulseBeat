import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart' as audio_query;

import '../models/song_model.dart';
import '../../services/storage_service.dart';

class AudioRepository {
  AudioRepository(this._audioQuery, this._storageService);

  final audio_query.OnAudioQuery _audioQuery;
  final StorageService _storageService;
  List<SongModel>? _cachedSongs;

  Future<List<SongModel>> loadDeviceSongs({
    bool forceRefresh = false,
    bool includeDeviceSongs = true,
  }) async {
    final List<SongModel>? cachedSongs = _cachedSongs;
    if (!forceRefresh && cachedSongs != null) {
      return List<SongModel>.unmodifiable(cachedSongs);
    }

    final List<SongModel> deviceSongs = includeDeviceSongs
        ? await _loadDeviceQuerySongs()
        : <SongModel>[];
    final List<SongModel> downloadedSongs = await _loadDownloadedSongs();
    final Set<String> seenPaths = <String>{};
    final List<SongModel> merged = <SongModel>[];

    for (final SongModel song in <SongModel>[
      ...downloadedSongs,
      ...deviceSongs,
    ]) {
      final String pathKey = song.normalizedFilePath.toLowerCase();
      if (pathKey.isEmpty || !seenPaths.add(pathKey)) {
        continue;
      }
      merged.add(song);
    }

    final List<SongModel> loadedSongs = List<SongModel>.unmodifiable(merged);
    _cachedSongs = loadedSongs;
    return List<SongModel>.unmodifiable(loadedSongs);
  }

  Future<List<SongModel>> _loadDeviceQuerySongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: audio_query.SongSortType.DATE_ADDED,
      orderType: audio_query.OrderType.DESC_OR_GREATER,
      uriType: audio_query.UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        .where(
          (song) => (song.isMusic ?? true) && (song.uri?.isNotEmpty ?? false),
        )
        .map(SongModel.fromAudioQuery)
        .toList(growable: false);
  }

  Future<List<SongModel>> _loadDownloadedSongs() async {
    final Map<String, SongModel> storedSongs = _storageService
        .getDownloadedSongsBySource();
    if (storedSongs.isEmpty) {
      return const <SongModel>[];
    }

    final Map<String, SongModel> existingSongs = <String, SongModel>{};
    for (final MapEntry<String, SongModel> entry in storedSongs.entries) {
      final String filePath = entry.value.filePath.trim();
      if (filePath.isEmpty) {
        continue;
      }

      final File file = File(filePath);
      if (await file.exists()) {
        existingSongs[entry.key] = entry.value;
      }
    }

    if (existingSongs.length != storedSongs.length) {
      _storageService.setDownloadedSongsBySource(existingSongs);
    }

    return existingSongs.values.toList(growable: false);
  }
}
