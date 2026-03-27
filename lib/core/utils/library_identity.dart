import '../../data/models/song_model.dart';

class LibrarySimilarityResult {
  const LibrarySimilarityResult({
    required this.matchPercentage,
    required this.sharedSongsCount,
    required this.unionSongsCount,
    required this.currentSongsCount,
    required this.targetSongsCount,
  });

  final int matchPercentage;
  final int sharedSongsCount;
  final int unionSongsCount;
  final int currentSongsCount;
  final int targetSongsCount;

  double get matchFraction => matchPercentage / 100;
  bool get hasAnyLibraryData => currentSongsCount > 0 || targetSongsCount > 0;
}

List<String> buildLibrarySongIds(Iterable<SongModel> songs) {
  final Set<String> uniqueIds = songs
      .map(buildLibrarySongId)
      .where((String id) => id.isNotEmpty)
      .toSet();

  final List<String> orderedIds = uniqueIds.toList(growable: false)
    ..sort((String a, String b) => a.compareTo(b));
  return orderedIds;
}

String buildLibrarySongId(SongModel song) {
  final String identitySource = <String>[
    _normalizeMetadata(song.title),
    _normalizeMetadata(song.artist),
    _normalizeMetadata(song.album),
    '${song.duration.inSeconds}',
  ].join('|');

  if (identitySource.replaceAll('|', '').isEmpty) {
    return '';
  }

  return _hashIdentity(identitySource);
}

String buildLibraryIdsSignature(Iterable<String> ids) {
  final List<String> orderedIds =
      ids
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort((String a, String b) => a.compareTo(b));

  if (orderedIds.isEmpty) {
    return '';
  }

  return _hashIdentity(orderedIds.join('|'));
}

LibrarySimilarityResult calculateLibrarySimilarity({
  required Iterable<String> currentIds,
  required Iterable<String> targetIds,
}) {
  final Set<String> currentLibrary = currentIds
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet();
  final Set<String> targetLibrary = targetIds
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet();

  final Set<String> union = <String>{...currentLibrary, ...targetLibrary};
  final int sharedSongsCount = currentLibrary
      .intersection(targetLibrary)
      .length;
  final int unionSongsCount = union.length;
  final int matchPercentage = unionSongsCount == 0
      ? 0
      : ((sharedSongsCount / unionSongsCount) * 100).round();

  return LibrarySimilarityResult(
    matchPercentage: matchPercentage,
    sharedSongsCount: sharedSongsCount,
    unionSongsCount: unionSongsCount,
    currentSongsCount: currentLibrary.length,
    targetSongsCount: targetLibrary.length,
  );
}

String _normalizeMetadata(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _hashIdentity(String input) {
  int hash = 0x811C9DC5;
  for (final int codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  return hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
}
