import 'package:flutter_test/flutter_test.dart';

import 'package:shity_songs_player/data/models/song_model.dart';

void main() {
  test('SongModel copyWith keeps original values when omitted', () {
    const song = SongModel(
      id: 1,
      title: 'Track',
      artist: 'Artist',
      album: 'Album',
      duration: Duration(minutes: 3),
      filePath: '/music/album/track.mp3',
      uri: 'file://track.mp3',
      artworkId: 1,
    );

    final updated = song.copyWith(title: 'Track 2');

    expect(updated.title, 'Track 2');
    expect(updated.artist, 'Artist');
    expect(updated.duration, const Duration(minutes: 3));
  });
}
