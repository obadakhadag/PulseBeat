import 'package:on_audio_query/on_audio_query.dart' as audio_query;

import '../models/song_model.dart';

class AudioRepository {
  AudioRepository(this._audioQuery);

  final audio_query.OnAudioQuery _audioQuery;

  Future<List<SongModel>> loadDeviceSongs() async {
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
}
