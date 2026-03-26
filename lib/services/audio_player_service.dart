import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/song_model.dart';

class AudioPlayerService {
  AudioPlayerService();

  _PulseAudioHandler? _handler;
  Future<void>? _initialization;

  Future<void> init() async {
    await (_initialization ??= _initializeHandler());
  }

  Stream<PlayerState> get playerStateStream =>
      _requireHandler.player.playerStateStream;
  Stream<Duration> get positionStream => _requireHandler.player.positionStream;
  Stream<Duration?> get durationStream => _requireHandler.player.durationStream;
  Stream<int?> get currentIndexStream =>
      _requireHandler.player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _requireHandler.player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream =>
      _requireHandler.player.shuffleModeEnabledStream;

  PlayerState get playerState => _requireHandler.player.playerState;
  Duration get position => _requireHandler.player.position;
  Duration? get duration => _requireHandler.player.duration;
  int? get currentIndex => _requireHandler.player.currentIndex;
  LoopMode get loopMode => _requireHandler.player.loopMode;
  bool get shuffleModeEnabled => _requireHandler.player.shuffleModeEnabled;
  List<SongModel> get queue => _requireHandler.songQueue;

  Future<void> setQueue(
    List<SongModel> songs, {
    required int initialIndex,
  }) async {
    await init();
    await _requireHandler.loadQueue(songs, initialIndex: initialIndex);
  }

  Future<void> play() async {
    await init();
    await _requireHandler.play();
  }

  Future<void> pause() async {
    await init();
    await _requireHandler.pause();
  }

  Future<void> stop() async {
    await init();
    await _requireHandler.stop();
  }

  Future<void> seek(Duration position) async {
    await init();
    await _requireHandler.seek(position);
  }

  Future<void> skipToNext() async {
    await init();
    await _requireHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await init();
    await _requireHandler.skipToPrevious();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await init();
    await _requireHandler.setRepeatMode(_repeatModeFor(mode));
  }

  Future<void> setShuffleMode(bool enabled) async {
    await init();
    await _requireHandler.setShuffleMode(
      enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  Future<void> dispose() async {
    final _PulseAudioHandler? handler = _handler;
    if (handler == null) {
      return;
    }
    await handler.dispose();
    _handler = null;
    _initialization = null;
  }

  Future<void> _initializeHandler() async {
    late final _PulseAudioHandler handler;
    await AudioService.init(
      builder: () => handler = _PulseAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.shity_songs_player.channel.playback',
        androidNotificationChannelName: 'PulseBeat Playback',
        androidNotificationChannelDescription:
            'Playback controls for PulseBeat audio',
        androidStopForegroundOnPause: false,
      ),
    );
    _handler = handler;
  }

  _PulseAudioHandler get _requireHandler {
    final _PulseAudioHandler? handler = _handler;
    if (handler == null) {
      throw StateError('AudioPlayerService.init() must be awaited first.');
    }
    return handler;
  }

  AudioServiceRepeatMode _repeatModeFor(LoopMode mode) {
    return switch (mode) {
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
      LoopMode.off => AudioServiceRepeatMode.none,
    };
  }
}

class _PulseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  _PulseAudioHandler() {
    playbackState.add(PlaybackState());
    queue.add(const <MediaItem>[]);
    _init();
  }

  final AudioPlayer player = AudioPlayer();
  final List<SongModel> _songQueue = <SongModel>[];

  List<SongModel> get songQueue => List<SongModel>.unmodifiable(_songQueue);

  Future<void> _init() async {
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    player.currentIndexStream.listen(_syncCurrentMediaItem);
    player.playbackEventStream.listen(_broadcastState);
    player.loopModeStream.listen((_) => _broadcastState(player.playbackEvent));
    player.shuffleModeEnabledStream.listen(
      (_) => _broadcastState(player.playbackEvent),
    );
  }

  Future<void> loadQueue(
    List<SongModel> songs, {
    required int initialIndex,
  }) async {
    if (songs.isEmpty) {
      _songQueue.clear();
      queue.add(const <MediaItem>[]);
      mediaItem.add(null);
      await player.stop();
      _broadcastState(player.playbackEvent);
      return;
    }

    final int safeIndex = initialIndex.clamp(0, songs.length - 1).toInt();
    _songQueue
      ..clear()
      ..addAll(songs);

    final List<MediaItem> mediaItems = _songQueue
        .map(_mediaItemFromSong)
        .toList(growable: false);
    queue.add(mediaItems);

    final ConcatenatingAudioSource source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: _songQueue
          .map(
            (SongModel song) =>
                AudioSource.uri(_audioUriFor(song), tag: song.id),
          )
          .toList(growable: false),
    );
    await player.setAudioSource(source, initialIndex: safeIndex);
    _syncCurrentMediaItem(safeIndex);
    _broadcastState(player.playbackEvent);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _songQueue.length) {
      return;
    }

    final List<int>? shuffleIndices = player.shuffleIndices;
    final int resolvedIndex =
        player.shuffleModeEnabled &&
            shuffleIndices != null &&
            index < shuffleIndices.length
        ? shuffleIndices[index]
        : index;
    await player.seek(Duration.zero, index: resolvedIndex);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await player.setLoopMode(_loopModeFor(repeatMode));
    _broadcastState(player.playbackEvent);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final bool enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enabled);
    _broadcastState(player.playbackEvent);
  }

  Future<void> dispose() => player.dispose();

  MediaItem _mediaItemFromSong(SongModel song) {
    return MediaItem(
      id: _audioUriFor(song).toString(),
      album: song.album,
      title: song.title,
      artist: song.artist,
      duration: song.duration,
      artUri: _artUriFor(song),
      extras: <String, dynamic>{
        'songId': song.id,
        'filePath': song.filePath,
        'artworkId': song.artworkId,
        'artworkUri': song.artworkUri,
      },
    );
  }

  Uri _audioUriFor(SongModel song) {
    final String rawUri = song.uri.trim();
    if (rawUri.isNotEmpty) {
      return Uri.parse(rawUri);
    }
    return Uri.file(song.filePath);
  }

  Uri? _artUriFor(SongModel song) {
    final String? artworkUri = song.artworkUri?.trim();
    if (artworkUri == null || artworkUri.isEmpty) {
      return null;
    }
    return Uri.tryParse(artworkUri);
  }

  void _syncCurrentMediaItem(int? index) {
    if (index == null || index < 0 || index >= queue.value.length) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(queue.value[index]);
  }

  void _broadcastState(PlaybackEvent event) {
    final bool playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const <MediaAction>{MediaAction.seek},
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState: _processingStateFor(player.processingState),
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        repeatMode: _repeatModeFor(player.loopMode),
        shuffleMode: player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        queueIndex: event.currentIndex,
      ),
    );
  }

  AudioServiceRepeatMode _repeatModeFor(LoopMode loopMode) {
    return switch (loopMode) {
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
      LoopMode.off => AudioServiceRepeatMode.none,
    };
  }

  LoopMode _loopModeFor(AudioServiceRepeatMode repeatMode) {
    return switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      AudioServiceRepeatMode.group => LoopMode.all,
      AudioServiceRepeatMode.none => LoopMode.off,
    };
  }

  AudioProcessingState _processingStateFor(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }
}
