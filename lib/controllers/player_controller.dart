import 'dart:async';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../core/utils/helpers.dart';
import '../data/models/song_model.dart';
import '../data/repositories/lyrics_repository.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';

class PlayerController extends GetxController {
  PlayerController({
    required AudioPlayerService audioService,
    required LyricsRepository lyricsRepository,
    required StorageService storageService,
  }) : _audioService = audioService,
       _lyricsRepository = lyricsRepository,
       _storageService = storageService;

  final AudioPlayerService _audioService;
  final LyricsRepository _lyricsRepository;
  final StorageService _storageService;

  Stream<Duration> get positionStream => _audioService.positionStream;
  Stream<Duration?> get durationStream => _audioService.durationStream;

  final RxList<SongModel> queue = <SongModel>[].obs;
  final Rxn<SongModel> currentSong = Rxn<SongModel>();
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> total = Duration.zero.obs;
  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final RxBool shuffleEnabled = false.obs;
  final RxBool showLyrics = true.obs;
  final RxBool isLoadingLyrics = false.obs;
  final RxString lyrics = ''.obs;
  final RxMap<int, int> playCounts = <int, int>{}.obs;

  PlayerState _latestPlayerState = PlayerState(false, ProcessingState.idle);
  int? _pendingPlayRegistrationSongId;
  int? _lyricsSongId;
  int _lyricsRequestToken = 0;
  late final Future<void> _setupFuture;

  @override
  void onInit() {
    super.onInit();
    _setupFuture = _initialize();
  }

  Future<void> _initialize() async {
    await _storageService.ensureInitialized();

    showLyrics.value = _storageService.getShowLyrics();
    playCounts.addAll(_storageService.getPlayCounts());
    await _audioService.init();
    _syncInitialPlayerState();

    ever<SongModel?>(currentSong, (SongModel? song) {
      if (song == null) {
        _clearLyricsState();
        return;
      }
      if (_lyricsSongId != song.id) {
        _clearLyricsState();
      }
      if (showLyrics.value) {
        loadLyrics(song);
      }
    });

    _audioService.playerStateStream.listen((PlayerState state) {
      _latestPlayerState = state;
      isPlaying.value = state.playing;
      isBuffering.value =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _tryRegisterPendingPlay();
    });
    _audioService.positionStream.listen((Duration value) {
      position.value = value;
      _tryRegisterPendingPlay();
    });
    _audioService.durationStream.listen(
      (Duration? value) => total.value = value ?? Duration.zero,
    );
    _audioService.currentIndexStream.listen((int? index) {
      if (index != null && index >= 0 && index < queue.length) {
        final song = queue[index];
        final previousSongId = currentSong.value?.id;
        currentSong.value = song;
        if (previousSongId != song.id) {
          _preparePlayRegistration(song.id);
        }
      }
    });
    _audioService.loopModeStream.listen(
      (LoopMode mode) => loopMode.value = mode,
    );
    _audioService.shuffleModeEnabledStream.listen(
      (bool enabled) => shuffleEnabled.value = enabled,
    );
  }

  Future<void> playFromQueue(
    List<SongModel> songs,
    SongModel selectedSong,
  ) async {
    await _setupFuture;

    if (songs.isEmpty) {
      return;
    }

    final index = songs.indexWhere(
      (SongModel item) => item.id == selectedSong.id,
    );
    if (index == -1) {
      return;
    }

    queue.assignAll(songs);
    await _audioService.setQueue(songs, initialIndex: index);
    currentSong.value = songs[index];
    _preparePlayRegistration(selectedSong.id);
    await _audioService.play();
  }

  Future<void> togglePlayback() async {
    await _setupFuture;

    if (isPlaying.value) {
      await _audioService.pause();
      return;
    }
    await _audioService.play();
  }

  Future<void> play() async {
    await _setupFuture;
    await _audioService.play();
  }

  Future<void> pause() async {
    await _setupFuture;
    await _audioService.pause();
  }

  Future<void> stop() async {
    await _setupFuture;
    await _audioService.stop();
  }

  Future<void> seek(Duration value) async {
    await _setupFuture;
    await _audioService.seek(value);
  }

  Future<void> next() async {
    await _setupFuture;
    await _audioService.skipToNext();
  }

  Future<void> previous() async {
    await _setupFuture;
    await _audioService.skipToPrevious();
  }

  Future<void> cycleLoopMode() async {
    await _setupFuture;

    final nextMode = switch (loopMode.value) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _audioService.setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() async {
    await _setupFuture;
    await _audioService.setShuffleMode(!shuffleEnabled.value);
  }

  Future<void> loadLyrics(SongModel song) async {
    final int requestToken = ++_lyricsRequestToken;
    _lyricsSongId = song.id;
    isLoadingLyrics.value = true;
    lyrics.value = '';
    final result = await _lyricsRepository.getLyrics(
      artist: song.artist,
      title: song.title,
    );
    if (requestToken != _lyricsRequestToken ||
        currentSong.value?.id != song.id) {
      return;
    }
    lyrics.value = result ?? 'No lyrics found for this track.'.tr;
    isLoadingLyrics.value = false;
  }

  Future<void> ensureLyricsLoaded(SongModel song) async {
    if (isLoadingLyrics.value && _lyricsSongId == song.id) {
      return;
    }
    if (_lyricsSongId == song.id && lyrics.value.isNotEmpty) {
      return;
    }
    await loadLyrics(song);
  }

  void setShowLyrics(bool value) {
    showLyrics.value = value;
    unawaited(_persistShowLyrics(value));
    final song = currentSong.value;
    if (value && song != null) {
      loadLyrics(song);
    } else if (!value) {
      _clearLyricsState();
    }
  }

  String get playbackLabel {
    if (isBuffering.value) {
      return 'Buffering'.tr;
    }
    if (isPlaying.value) {
      return 'Now Playing'.tr;
    }
    return 'Paused'.tr;
  }

  @override
  Future<void> onClose() async {
    await _audioService.dispose();
    super.onClose();
  }

  void announceMissingQueue() {
    AppHelpers.showToast('Scan your device library first.'.tr);
  }

  void _syncInitialPlayerState() {
    queue.assignAll(_audioService.queue);
    _latestPlayerState = _audioService.playerState;
    isPlaying.value = _latestPlayerState.playing;
    isBuffering.value =
        _latestPlayerState.processingState == ProcessingState.loading ||
        _latestPlayerState.processingState == ProcessingState.buffering;
    position.value = _audioService.position;
    total.value = _audioService.duration ?? Duration.zero;
    loopMode.value = _audioService.loopMode;
    shuffleEnabled.value = _audioService.shuffleModeEnabled;

    final int? currentIndex = _audioService.currentIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < queue.length) {
      currentSong.value = queue[currentIndex];
    }
  }

  void _preparePlayRegistration(int songId) {
    _pendingPlayRegistrationSongId = songId;
    position.value = Duration.zero;
  }

  void _tryRegisterPendingPlay() {
    final SongModel? song = currentSong.value;
    final int? pendingSongId = _pendingPlayRegistrationSongId;
    if (song == null || pendingSongId == null || pendingSongId != song.id) {
      return;
    }

    if (!_latestPlayerState.playing ||
        _latestPlayerState.processingState != ProcessingState.ready) {
      return;
    }

    final Duration threshold = _playCountThreshold(song);
    if (position.value < threshold) {
      return;
    }

    playCounts[song.id] = (playCounts[song.id] ?? 0) + 1;
    _pendingPlayRegistrationSongId = null;
    _storageService.setPlayCounts(playCounts);
  }

  Duration _playCountThreshold(SongModel song) {
    final int durationMs = song.duration.inMilliseconds;
    final int targetMs = durationMs <= 0 ? 3000 : durationMs ~/ 5;
    final int clampedTargetMs = targetMs < 3000
        ? 3000
        : targetMs > 15000
        ? 15000
        : targetMs;
    return Duration(milliseconds: clampedTargetMs);
  }

  Future<void> _persistShowLyrics(bool value) async {
    await _storageService.ensureInitialized();
    _storageService.setShowLyrics(value);
  }

  void _clearLyricsState() {
    _lyricsRequestToken++;
    _lyricsSongId = null;
    isLoadingLyrics.value = false;
    lyrics.value = '';
  }
}
