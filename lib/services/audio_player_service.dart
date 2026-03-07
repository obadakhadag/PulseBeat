import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/song_model.dart';

class AudioPlayerService {
  AudioPlayerService(this._player);

  final AudioPlayer _player;
  List<SongModel> _queue = <SongModel>[];

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  List<SongModel> get queue => List<SongModel>.unmodifiable(_queue);

  Future<void> setQueue(
    List<SongModel> songs, {
    required int initialIndex,
  }) async {
    _queue = songs;
    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs
          .map((song) => AudioSource.uri(Uri.parse(song.uri), tag: song.id))
          .toList(growable: false),
    );
    await _player.setAudioSource(source, initialIndex: initialIndex);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext() => _player.seekToNext();
  Future<void> skipToPrevious() => _player.seekToPrevious();
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _player.shuffle();
    }
  }

  Future<void> dispose() => _player.dispose();
}
