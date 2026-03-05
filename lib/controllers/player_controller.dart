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

  int? _lastCountedSongId;
  int? _pendingManualPlaySongId;

  @override
  Future<void> onInit() async {
    super.onInit();
    showLyrics.value = _storageService.getShowLyrics();
    playCounts.addAll(_storageService.getPlayCounts());
    await _audioService.init();

    ever<SongModel?>(currentSong, (SongModel? song) {
      if (song != null && showLyrics.value) {
        loadLyrics(song);
      }
    });

    _audioService.playerStateStream.listen((PlayerState state) {
      isPlaying.value = state.playing;
      isBuffering.value =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
    });
    _audioService.positionStream.listen(
      (Duration value) => position.value = value,
    );
    _audioService.durationStream.listen(
      (Duration? value) => total.value = value ?? Duration.zero,
    );
    _audioService.currentIndexStream.listen((int? index) {
      if (index != null && index >= 0 && index < queue.length) {
        final song = queue[index];
        final previousSongId = currentSong.value?.id;
        currentSong.value = song;
        if (_pendingManualPlaySongId == song.id) {
          _pendingManualPlaySongId = null;
          return;
        }
        if (previousSongId != song.id) {
          _registerPlay(song.id);
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
    _pendingManualPlaySongId = selectedSong.id;
    await _audioService.setQueue(songs, initialIndex: index);
    currentSong.value = songs[index];
    _registerPlay(selectedSong.id, force: true);
    await _audioService.play();
  }

  Future<void> togglePlayback() async {
    if (isPlaying.value) {
      await _audioService.pause();
      return;
    }
    await _audioService.play();
  }

  Future<void> seek(Duration value) => _audioService.seek(value);
  Future<void> next() => _audioService.skipToNext();
  Future<void> previous() => _audioService.skipToPrevious();

  Future<void> cycleLoopMode() async {
    final nextMode = switch (loopMode.value) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _audioService.setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() async {
    await _audioService.setShuffleMode(!shuffleEnabled.value);
  }

  Future<void> loadLyrics(SongModel song) async {
    isLoadingLyrics.value = true;
    lyrics.value = '';
    final result = await _lyricsRepository.getLyrics(
      artist: song.artist,
      title: song.title,
    );
    lyrics.value = result ?? 'No lyrics found for this track.';
    isLoadingLyrics.value = false;
  }

  void setShowLyrics(bool value) {
    showLyrics.value = value;
    _storageService.setShowLyrics(value);
    final song = currentSong.value;
    if (value && song != null) {
      loadLyrics(song);
    }
  }

  String get playbackLabel {
    if (isBuffering.value) {
      return 'Buffering';
    }
    if (isPlaying.value) {
      return 'Now Playing';
    }
    return 'Paused';
  }

  @override
  Future<void> onClose() async {
    await _audioService.dispose();
    super.onClose();
  }

  void announceMissingQueue() {
    AppHelpers.showToast('Scan your device library first.');
  }

  void _registerPlay(int songId, {bool force = false}) {
    if (!force && _lastCountedSongId == songId) {
      return;
    }

    playCounts[songId] = (playCounts[songId] ?? 0) + 1;
    _lastCountedSongId = songId;
    _storageService.setPlayCounts(playCounts);
  }
}
