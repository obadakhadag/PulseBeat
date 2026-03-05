import '../providers/lyrics_api_provider.dart';

class LyricsRepository {
  LyricsRepository(this._provider);

  final LyricsApiProvider _provider;

  Future<String?> getLyrics({required String artist, required String title}) {
    return _provider.fetchLyrics(artist: artist, title: title);
  }
}
