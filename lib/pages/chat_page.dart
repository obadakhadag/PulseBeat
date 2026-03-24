// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;
import 'package:path_provider/path_provider.dart';

import '../controllers/home_controller.dart';
import '../controllers/player_controller.dart';
import '../core/constants/app_constants.dart';
import '../data/models/song_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_debug_service.dart';
import '../widgets/music_page_background.dart';
import '../widgets/song_artwork.dart';
import 'user_profile_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.chatId,
    this.otherUid,
    this.otherDisplayName,
    this.otherUsername,
    this.otherPhotoUrl,
  });

  final String? chatId;
  final String? otherUid;
  final String? otherDisplayName;
  final String? otherUsername;
  final String? otherPhotoUrl;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _AnimatedChatMessage extends StatelessWidget {
  const _AnimatedChatMessage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController _homeController = Get.find<HomeController>();
  final PlayerController _playerController = Get.find<PlayerController>();
  final StorageService _storageService = Get.find<StorageService>();
  final audio_query.OnAudioQuery _audioQuery = audio_query.OnAudioQuery();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _messageListController = ScrollController();
  final Map<int, SongModel?> _songLookupCache = <int, SongModel?>{};
  final Map<String, String> _sharedAudioFileCache = <String, String>{};
  final Set<String> _savingSongMessageIds = <String>{};
  final Set<String> _savedSongMessageIds = <String>{};
  final Map<String, String> _songSaveErrors = <String, String>{};
  bool _isSending = false;
  bool _isComposerFocused = false;
  bool _isTyping = false;
  String? _selectedMessageId;
  String? _activeChatId;
  String? _typingUserUid;
  Timer? _typingTimer;

  static const List<String> _reactionOptions = <String>[
    '\u2764\uFE0F',
    '\uD83D\uDE02',
    '\uD83D\uDC4D',
    '\uD83D\uDD25',
  ];
  static const int _maxFirestoreAudioBytes = 700 * 1024;
  static const int _maxFirestoreAudioBase64Length = 950000;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_handleComposerFocusChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    final String? activeChatId = _activeChatId;
    final String? typingUserUid = _typingUserUid;
    if (activeChatId != null && typingUserUid != null && _isTyping) {
      unawaited(
        _setTypingState(
          chatId: activeChatId,
          currentUserUid: typingUserUid,
          isTyping: false,
        ),
      );
    }
    _messageController.dispose();
    _messageFocusNode
      ..removeListener(_handleComposerFocusChanged)
      ..dispose();
    _messageListController.dispose();
    super.dispose();
  }

  void _handleComposerFocusChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isComposerFocused = _messageFocusNode.hasFocus;
    });
  }

  void _syncTypingContext({
    required String chatId,
    required String currentUserUid,
  }) {
    if (_activeChatId == chatId && _typingUserUid == currentUserUid) {
      return;
    }

    final String? previousChatId = _activeChatId;
    final String? previousUserUid = _typingUserUid;
    _activeChatId = chatId;
    _typingUserUid = currentUserUid;

    if (previousChatId != null && previousUserUid != null && _isTyping) {
      unawaited(
        _setTypingState(
          chatId: previousChatId,
          currentUserUid: previousUserUid,
          isTyping: false,
        ),
      );
    }
  }

  Future<void> _setTypingState({
    required String chatId,
    required String currentUserUid,
    required bool isTyping,
  }) async {
    if (chatId.trim().isEmpty ||
        currentUserUid.trim().isEmpty ||
        _isTyping == isTyping) {
      return;
    }

    _isTyping = isTyping;
    try {
      await _firestore.collection('chats').doc(chatId).update(<String, dynamic>{
        'typing.$currentUserUid': isTyping,
      });
    } catch (_) {
      _isTyping = !isTyping;
    }
  }

  void _handleTypingChanged({
    required String chatId,
    required String currentUserUid,
    required String value,
  }) {
    final String trimmedValue = value.trim();
    _typingTimer?.cancel();

    if (trimmedValue.isEmpty) {
      unawaited(
        _setTypingState(
          chatId: chatId,
          currentUserUid: currentUserUid,
          isTyping: false,
        ),
      );
      return;
    }

    unawaited(
      _setTypingState(
        chatId: chatId,
        currentUserUid: currentUserUid,
        isTyping: true,
      ),
    );

    _typingTimer = Timer(const Duration(seconds: 2), () {
      unawaited(
        _setTypingState(
          chatId: chatId,
          currentUserUid: currentUserUid,
          isTyping: false,
        ),
      );
    });
  }

  DateTime? _resolveMessageDateTime(dynamic rawValue) {
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }
    if (rawValue is DateTime) {
      return rawValue;
    }
    return null;
  }

  String _formatMessageTime(BuildContext context, DateTime? value) {
    if (value == null) {
      return '';
    }

    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(value.toLocal()));
  }

  String _buildSharedSongSourceKey({
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String audioUrl,
  }) {
    final String trimmedUrl = audioUrl.trim();
    if (trimmedUrl.isNotEmpty) {
      return 'url:$trimmedUrl';
    }

    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return 'chat_song:${songId > 0 ? songId : 0}'
        '|${normalize(songTitle)}'
        '|${normalize(songArtist)}'
        '|${normalize(songName)}';
  }

  Future<Directory> _ensureDownloadedSongsDirectory() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final Directory downloadDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}${AppConstants.downloadedSongsFolder}',
    );
    if (!await downloadDirectory.exists()) {
      await downloadDirectory.create(recursive: true);
    }
    return downloadDirectory;
  }

  String _resolveSongFileExtension({
    required String songName,
    required String songTitle,
    required String audioUrl,
  }) {
    String? extensionFrom(String value) {
      final String trimmedValue = value.trim();
      final int dotIndex = trimmedValue.lastIndexOf('.');
      if (dotIndex <= 0 || dotIndex == trimmedValue.length - 1) {
        return null;
      }

      final String candidate = trimmedValue.substring(dotIndex).toLowerCase();
      if (!RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(candidate)) {
        return null;
      }
      return candidate;
    }

    return extensionFrom(songName) ??
        extensionFrom(songTitle) ??
        extensionFrom(Uri.tryParse(audioUrl)?.pathSegments.last ?? '') ??
        '.mp3';
  }

  Future<String> _buildDownloadedSongPath({
    required Directory directory,
    required String songName,
    required String songTitle,
    required String audioUrl,
  }) async {
    final String rawName = songName.trim().isNotEmpty
        ? songName.trim()
        : songTitle.trim().isNotEmpty
        ? songTitle.trim()
        : 'shared_song';
    final String extension = _resolveSongFileExtension(
      songName: songName,
      songTitle: songTitle,
      audioUrl: audioUrl,
    );
    final String safeBaseName = _sanitizeFileName(
      rawName.replaceAll(RegExp(r'\.[a-zA-Z0-9]{2,5}$'), ''),
    );

    int suffix = 0;
    while (true) {
      final String fileName = suffix == 0
          ? '$safeBaseName$extension'
          : '${safeBaseName}_$suffix$extension';
      final String filePath =
          '${directory.path}${Platform.pathSeparator}$fileName';
      if (!await File(filePath).exists()) {
        return filePath;
      }
      suffix += 1;
    }
  }

  Future<void> _saveReceivedSong({
    required String messageId,
    required String cacheKey,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
  }) async {
    final String normalizedMessageId = messageId.trim();
    final String normalizedCoverUrl = coverUrl.trim();
    if (normalizedMessageId.isNotEmpty &&
        (_savingSongMessageIds.contains(normalizedMessageId) ||
            _savedSongMessageIds.contains(normalizedMessageId))) {
      return;
    }

    if (mounted && normalizedMessageId.isNotEmpty) {
      setState(() {
        _savingSongMessageIds.add(normalizedMessageId);
        _savedSongMessageIds.remove(normalizedMessageId);
        _songSaveErrors.remove(normalizedMessageId);
      });
    }

    final String sourceKey = _buildSharedSongSourceKey(
      songId: songId,
      songTitle: songTitle,
      songArtist: songArtist,
      songName: songName,
      audioUrl: audioUrl,
    );
    final SongModel? existingSong = _storageService.getDownloadedSongBySource(
      sourceKey,
    );
    if (existingSong != null && existingSong.filePath.trim().isNotEmpty) {
      final File existingFile = File(existingSong.filePath);
      if (await existingFile.exists()) {
        if (normalizedCoverUrl.isNotEmpty &&
            (existingSong.artworkUri?.trim().isEmpty ?? true)) {
          _storageService.saveDownloadedSong(
            sourceKey: sourceKey,
            song: existingSong.copyWith(artworkUri: normalizedCoverUrl),
          );
        }
        _sharedAudioFileCache[cacheKey] = existingSong.filePath;
        _sharedAudioFileCache[sourceKey] = existingSong.filePath;
        await _homeController.loadLibrary(forceRefresh: true);
        if (mounted && normalizedMessageId.isNotEmpty) {
          setState(() {
            _savingSongMessageIds.remove(normalizedMessageId);
            _savedSongMessageIds.add(normalizedMessageId);
            _songSaveErrors.remove(normalizedMessageId);
          });
        }
        Get.snackbar('Done'.tr, 'Song saved to your library'.tr);
        return;
      }
    }

    try {
      final Directory downloadDirectory =
          await _ensureDownloadedSongsDirectory();
      final String outputPath = await _buildDownloadedSongPath(
        directory: downloadDirectory,
        songName: songName,
        songTitle: songTitle,
        audioUrl: audioUrl,
      );

      final String? cachedPath = _sharedAudioFileCache[cacheKey];
      if (cachedPath != null && cachedPath.trim().isNotEmpty) {
        final File cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          await cachedFile.copy(outputPath);
        }
      }

      final File outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        if (audioData.trim().isNotEmpty) {
          final String? decodedPath = await _decodeAudioToLocalFile(
            cacheKey: sourceKey,
            audioData: audioData,
            songName: songName,
          );
          if (decodedPath == null || decodedPath.trim().isEmpty) {
            throw StateError('Shared song data is unavailable.');
          }
          await File(decodedPath).copy(outputPath);
        } else if (audioUrl.trim().isNotEmpty) {
          final String? tempPath = await _downloadSongFromUrlToLocalFile(
            cacheKey: sourceKey,
            songUrl: audioUrl,
            songName: songName,
          );
          if (tempPath == null || tempPath.trim().isEmpty) {
            throw StateError('Shared song download is unavailable.');
          }
          await File(tempPath).copy(outputPath);
        } else {
          final SongModel? localSong = await _findSongById(songId);
          final String localPath = localSong?.filePath.trim() ?? '';
          if (localPath.isEmpty) {
            throw StateError('Song file is unavailable.');
          }

          final File localFile = File(localPath);
          if (!await localFile.exists()) {
            throw StateError('Song file is missing on this device.');
          }
          await localFile.copy(outputPath);
        }
      }

      final Duration duration =
          _homeController.findSongById(songId)?.duration ?? Duration.zero;
      final SongModel savedSong = SongModel(
        id:
            existingSong?.id ??
            DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
        title: songTitle.trim().isNotEmpty
            ? songTitle.trim()
            : (songName.trim().isNotEmpty ? songName.trim() : 'Unknown song'),
        artist: songArtist.trim().isNotEmpty
            ? songArtist.trim()
            : 'Unknown artist',
        album: 'Downloads',
        duration: duration,
        filePath: outputPath,
        uri: Uri.file(outputPath).toString(),
        artworkId: 0,
        artworkUri: normalizedCoverUrl.isEmpty ? null : normalizedCoverUrl,
      );

      _storageService.saveDownloadedSong(sourceKey: sourceKey, song: savedSong);
      _sharedAudioFileCache[cacheKey] = outputPath;
      _sharedAudioFileCache[sourceKey] = outputPath;

      await _homeController.loadLibrary(forceRefresh: true);
      if (mounted && normalizedMessageId.isNotEmpty) {
        setState(() {
          _savingSongMessageIds.remove(normalizedMessageId);
          _savedSongMessageIds.add(normalizedMessageId);
          _songSaveErrors.remove(normalizedMessageId);
        });
      }
      Get.snackbar('Done'.tr, 'Song saved to your library'.tr);
    } on StateError catch (error) {
      if (mounted && normalizedMessageId.isNotEmpty) {
        setState(() {
          _savingSongMessageIds.remove(normalizedMessageId);
          _savedSongMessageIds.remove(normalizedMessageId);
          _songSaveErrors[normalizedMessageId] = error.message.toString();
        });
      }
      Get.snackbar('Error', error.message.toString());
    } catch (_) {
      if (mounted && normalizedMessageId.isNotEmpty) {
        setState(() {
          _savingSongMessageIds.remove(normalizedMessageId);
          _savedSongMessageIds.remove(normalizedMessageId);
          _songSaveErrors[normalizedMessageId] = 'Failed to save song.'.tr;
        });
      }
      Get.snackbar('Error'.tr, 'Failed to save song.'.tr);
    }
  }

  Future<void> _sendMessage({
    required String chatId,
    required String currentUserUid,
  }) async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final DocumentReference<Map<String, dynamic>> chatRef = _firestore
          .collection('chats')
          .doc(chatId);

      await chatRef.collection('messages').add(<String, dynamic>{
        'senderUid': currentUserUid,
        'text': messageText,
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await chatRef.update(<String, dynamic>{
        'lastMessage': messageText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      _typingTimer?.cancel();
      await _setTypingState(
        chatId: chatId,
        currentUserUid: currentUserUid,
        isTyping: false,
      );
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to send message.'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendSongMessage({
    required String chatId,
    required String currentUserUid,
    required SongModel song,
  }) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final String filePath = song.filePath.trim();
      if (filePath.isEmpty) {
        throw StateError('Song file path is missing.');
      }

      print('Sending song...');
      print('Selected song path: $filePath');

      final String? songUrl = await SupabaseDebugService.uploadSongDebug(
        filePath,
      );

      if (songUrl != null) {
        print('Song uploaded successfully');
        final String coverUrl = await _resolveSongCoverUrl(song);
        await _sendSongMessageToFirestore(
          chatId: chatId,
          currentUserUid: currentUserUid,
          song: song,
          songUrl: songUrl,
          coverUrl: coverUrl,
        );
      } else {
        print('Song upload failed');
        Get.snackbar('Error'.tr, 'Failed to send song.'.tr);
        return;
      }

      print('Song send pipeline completed');
    } on StateError catch (error, stackTrace) {
      print('SONG SEND STATE ERROR:');
      print(error.toString());
      print(stackTrace.toString());
      Get.snackbar('Error', error.message.toString());
    } catch (error, stackTrace) {
      print('SONG SEND ERROR:');
      print(error.toString());
      print(stackTrace.toString());
      Get.snackbar('Error'.tr, 'Failed to send song.'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendSongMessageToFirestore({
    required String chatId,
    required String currentUserUid,
    required SongModel song,
    required String songUrl,
    required String coverUrl,
  }) async {
    print('STEP 11: Preparing Firestore song message');

    final DocumentReference<Map<String, dynamic>> chatRef = _firestore
        .collection('chats')
        .doc(chatId);
    final String songName = _resolveSongFileName(song);

    print('STEP 12: Writing song message document');

    await chatRef.collection('messages').add(<String, dynamic>{
      'senderUid': currentUserUid,
      'senderId': currentUserUid,
      'type': 'song',
      'songId': song.id,
      'title': song.title,
      'artist': song.artist,
      'songName': songName,
      'coverUrl': coverUrl.trim(),
      'songUrl': songUrl,
      'audioUrl': songUrl,
      'audioData': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('STEP 13: Song message document created');
    print('STEP 14: Updating chat last message');

    await chatRef.update(<String, dynamic>{
      'lastMessage': '\uD83C\uDFB5 ${song.title}',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    print('STEP 15: Chat last message updated');
  }

  Future<String> _resolveSongCoverUrl(SongModel song) async {
    final String existingArtworkUri = song.artworkUri?.trim() ?? '';
    if (existingArtworkUri.isNotEmpty) {
      return existingArtworkUri;
    }
    if (song.artworkId <= 0) {
      return '';
    }

    try {
      final Uint8List? artworkData = await _audioQuery.queryArtwork(
        song.artworkId,
        audio_query.ArtworkType.AUDIO,
        format: audio_query.ArtworkFormat.JPEG,
        size: 700,
        quality: 85,
      );
      if (artworkData == null || artworkData.isEmpty) {
        return '';
      }

      return await SupabaseDebugService.uploadArtworkDebug(
            artworkData,
            fileExtension: 'jpg',
          ) ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openSongSelector({
    required String chatId,
    required String currentUserUid,
  }) async {
    final List<SongModel> songs = _homeController.songs.toList(growable: false);

    final SongModel? selectedSong = await showModalBottomSheet<SongModel>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        if (songs.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(child: Text('No songs available.'.tr)),
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: ListView.separated(
            itemCount: songs.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final SongModel song = songs[index];
              return ListTile(
                onTap: () => Navigator.of(context).pop(song),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: SongArtwork(
                  songId: song.artworkId,
                  artworkUri: song.artworkUri,
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.circular(14),
                  fallback: SongArtworkPlaceholder(
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedSong == null) {
      return;
    }

    await _sendSongMessage(
      chatId: chatId,
      currentUserUid: currentUserUid,
      song: selectedSong,
    );
  }

  Future<SongModel?> _findSongById(int songId) async {
    if (songId <= 0) {
      return null;
    }

    if (_songLookupCache.containsKey(songId)) {
      return _songLookupCache[songId];
    }

    final SongModel? localSong = _homeController.findSongById(songId);
    if (localSong != null) {
      _songLookupCache[songId] = localSong;
      return localSong;
    }

    try {
      final List<audio_query.SongModel> deviceSongs = await _audioQuery
          .querySongs(
            sortType: audio_query.SongSortType.DATE_ADDED,
            orderType: audio_query.OrderType.DESC_OR_GREATER,
            uriType: audio_query.UriType.EXTERNAL,
            ignoreCase: true,
          );

      for (final audio_query.SongModel rawSong in deviceSongs) {
        if (rawSong.id != songId) {
          continue;
        }

        if ((rawSong.uri?.isNotEmpty ?? false) && (rawSong.isMusic ?? true)) {
          final SongModel song = SongModel.fromAudioQuery(rawSong);
          _songLookupCache[songId] = song;
          return song;
        }
      }
    } catch (_) {
      _songLookupCache[songId] = null;
      return null;
    }

    _songLookupCache[songId] = null;
    return null;
  }

  String _resolveSongFileName(SongModel song) {
    final String normalizedPath = song.filePath.replaceAll('\\', '/');
    final List<String> segments = normalizedPath.split('/');
    final String lastSegment = segments.isNotEmpty ? segments.last.trim() : '';
    if (lastSegment.isNotEmpty) {
      return lastSegment;
    }
    return 'song_${song.id}.mp3';
  }

  String _sanitizeFileName(String value) {
    final String sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.trim().isNotEmpty) {
      return sanitized;
    }
    return 'shared_song.mp3';
  }

  Future<String?> _decodeAudioToLocalFile({
    required String cacheKey,
    required String audioData,
    required String songName,
  }) async {
    final String trimmedData = audioData.trim();
    if (trimmedData.isEmpty) {
      return null;
    }
    if (trimmedData.length > _maxFirestoreAudioBase64Length) {
      throw StateError('Shared song data is too large for Firestore limits.');
    }

    final String normalizedKey = cacheKey.trim().isNotEmpty
        ? cacheKey.trim()
        : '${songName.hashCode.abs()}_${trimmedData.length}';
    final String? cachedPath = _sharedAudioFileCache[normalizedKey];
    if (cachedPath != null && cachedPath.isNotEmpty) {
      final File cachedFile = File(cachedPath);
      if (await cachedFile.exists()) {
        return cachedPath;
      }
    }

    late final List<int> bytes;
    try {
      bytes = base64Decode(trimmedData);
    } catch (_) {
      throw StateError('Unable to decode shared song data.');
    }

    if (bytes.isEmpty) {
      throw StateError('Shared song data is empty.');
    }
    if (bytes.length > _maxFirestoreAudioBytes) {
      throw StateError('Shared song is too large to decode.');
    }

    final Directory sharedDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}pulsebeat_chat_audio',
    );
    if (!await sharedDir.exists()) {
      await sharedDir.create(recursive: true);
    }

    final String safeName = _sanitizeFileName(
      songName.trim().isEmpty ? 'shared_song.mp3' : songName.trim(),
    );
    final int dataHash = trimmedData.hashCode.abs();
    final String filePath =
        '${sharedDir.path}${Platform.pathSeparator}${normalizedKey.hashCode.abs()}_${dataHash}_$safeName';
    final File outputFile = File(filePath);

    if (!await outputFile.exists()) {
      await outputFile.writeAsBytes(bytes, flush: true);
    }

    _sharedAudioFileCache[normalizedKey] = filePath;
    return filePath;
  }

  Future<String?> _downloadSongFromUrlToLocalFile({
    required String cacheKey,
    required String songUrl,
    required String songName,
  }) async {
    final String trimmedUrl = songUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }

    final String normalizedKey = cacheKey.trim().isNotEmpty
        ? cacheKey.trim()
        : '${songName.hashCode.abs()}_${trimmedUrl.hashCode.abs()}';
    final String? cachedPath = _sharedAudioFileCache[normalizedKey];
    if (cachedPath != null && cachedPath.isNotEmpty) {
      final File cachedFile = File(cachedPath);
      if (await cachedFile.exists()) {
        return cachedPath;
      }
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmedUrl);
    } catch (_) {
      throw StateError('Invalid shared song URL.');
    }

    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Failed to download shared song.');
      }

      final List<int> bytes = await response.fold<List<int>>(<int>[], (
        List<int> previous,
        List<int> element,
      ) {
        previous.addAll(element);
        return previous;
      });
      if (bytes.isEmpty) {
        throw StateError('Downloaded shared song is empty.');
      }

      final Directory sharedDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}pulsebeat_chat_audio',
      );
      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }

      final String safeName = _sanitizeFileName(
        songName.trim().isEmpty ? 'shared_song.mp3' : songName.trim(),
      );
      final String filePath =
          '${sharedDir.path}${Platform.pathSeparator}${normalizedKey.hashCode.abs()}_${trimmedUrl.hashCode.abs()}_$safeName';
      final File outputFile = File(filePath);

      if (!await outputFile.exists()) {
        await outputFile.writeAsBytes(bytes, flush: true);
      }

      _sharedAudioFileCache[normalizedKey] = filePath;
      return filePath;
    } finally {
      client.close(force: true);
    }
  }

  SongModel _buildLocalSongFromMessage({
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String localPath,
    String coverUrl = '',
  }) {
    final int resolvedId = songId > 0 ? songId : localPath.hashCode.abs();
    final String resolvedTitle = songTitle.trim().isNotEmpty
        ? songTitle.trim()
        : (songName.trim().isNotEmpty ? songName.trim() : 'Unknown song');

    return SongModel(
      id: resolvedId,
      title: resolvedTitle,
      artist: songArtist.trim().isNotEmpty
          ? songArtist.trim()
          : 'Unknown artist',
      album: 'Shared in chat',
      duration: Duration.zero,
      filePath: localPath,
      uri: Uri.file(localPath).toString(),
      artworkId: songId > 0 ? songId : 0,
      artworkUri: coverUrl.trim().isEmpty ? null : coverUrl.trim(),
    );
  }

  SongModel? _buildRemoteSongFromMessage({
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String audioUrl,
    String coverUrl = '',
  }) {
    final String trimmedUrl = audioUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }

    final int resolvedId = songId > 0 ? songId : trimmedUrl.hashCode.abs();
    return SongModel(
      id: resolvedId,
      title: songTitle.trim().isNotEmpty
          ? songTitle.trim()
          : (songName.trim().isNotEmpty ? songName.trim() : 'Unknown song'),
      artist: songArtist.trim().isEmpty ? 'Unknown artist' : songArtist.trim(),
      album: 'Shared in chat',
      duration: Duration.zero,
      filePath: '',
      uri: trimmedUrl,
      artworkId: songId > 0 ? songId : 0,
      artworkUri: coverUrl.trim().isEmpty ? null : coverUrl.trim(),
    );
  }

  Future<void> _toggleSongPlayback({
    required String cacheKey,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
  }) async {
    await _playSongForChat(
      cacheKey: cacheKey,
      songId: songId,
      songTitle: songTitle,
      songArtist: songArtist,
      songName: songName,
      coverUrl: coverUrl,
      audioUrl: audioUrl,
      audioData: audioData,
      toggleIfCurrent: true,
    );
  }

  Future<void> _playSongForChat({
    required String cacheKey,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
    required bool toggleIfCurrent,
  }) async {
    final String trimmedAudioData = audioData.trim();
    final String trimmedAudioUrl = audioUrl.trim();
    SongModel? localSong;
    SongModel? song;

    if (trimmedAudioData.isNotEmpty) {
      try {
        final String? decodedPath = await _decodeAudioToLocalFile(
          cacheKey: cacheKey,
          audioData: trimmedAudioData,
          songName: songName,
        );
        if (decodedPath != null && decodedPath.isNotEmpty) {
          song = _buildLocalSongFromMessage(
            songId: songId,
            songTitle: songTitle,
            songArtist: songArtist,
            songName: songName,
            localPath: decodedPath,
            coverUrl: coverUrl,
          );
        }
      } on StateError catch (error) {
        Get.snackbar('Error', error.message.toString());
        return;
      }
    }

    if (song == null && trimmedAudioUrl.isNotEmpty) {
      try {
        final String? downloadedPath = await _downloadSongFromUrlToLocalFile(
          cacheKey: cacheKey,
          songUrl: trimmedAudioUrl,
          songName: songName,
        );
        if (downloadedPath != null && downloadedPath.isNotEmpty) {
          song = _buildLocalSongFromMessage(
            songId: songId,
            songTitle: songTitle,
            songArtist: songArtist,
            songName: songName,
            localPath: downloadedPath,
            coverUrl: coverUrl,
          );
        }
      } on StateError catch (error) {
        Get.snackbar('Error', error.message.toString());
      }
    }

    if (song == null) {
      localSong = await _findSongById(songId);
    }

    song ??=
        localSong ??
        _buildRemoteSongFromMessage(
          songId: songId,
          songTitle: songTitle,
          songArtist: songArtist,
          songName: songName,
          coverUrl: coverUrl,
          audioUrl: audioUrl,
        );
    if (song == null) {
      Get.snackbar('Error', 'Song unavailable.');
      return;
    }

    final SongModel? currentSong = _playerController.currentSong.value;
    final bool isCurrentSong =
        currentSong?.id == song.id && currentSong?.uri == song.uri;

    if (isCurrentSong) {
      if (toggleIfCurrent) {
        if (_playerController.isPlaying.value) {
          await _playerController.pause();
        } else {
          await _playerController.play();
        }
      } else if (!_playerController.isPlaying.value) {
        await _playerController.play();
      }
      return;
    }

    try {
      final int? currentSongId = currentSong?.id;
      if (currentSongId != null) {
        await _playerController.stop();
      }

      final List<SongModel> queue;
      if (localSong != null && trimmedAudioData.isEmpty) {
        final SongModel selectedLocalSong = localSong;
        final List<SongModel> baseQueue = _homeController.songs.isNotEmpty
            ? _homeController.songs.toList(growable: false)
            : <SongModel>[selectedLocalSong];
        final bool queueContainsSong = baseQueue.any(
          (SongModel item) => item.id == selectedLocalSong.id,
        );
        queue = queueContainsSong
            ? baseQueue
            : <SongModel>[selectedLocalSong, ...baseQueue];
      } else {
        queue = <SongModel>[song];
      }

      await _playerController.playFromQueue(queue, song);
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to play ${songTitle.trim().isNotEmpty ? songTitle.trim() : (songName.trim().isNotEmpty ? songName.trim() : 'song')}.',
      );
    }
  }

  Future<void> _startListeningSession({
    required String chatId,
    required String currentUserUid,
    required int songId,
    required String title,
    required String artist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
  }) async {
    final String trimmedAudioUrl = audioUrl.trim();
    final String trimmedAudioData = audioData.trim();
    if (songId <= 0 && trimmedAudioUrl.isEmpty && trimmedAudioData.isEmpty) {
      Get.snackbar('Error', 'Song is not available for session.');
      return;
    }
    final int resolvedSongId = songId > 0
        ? songId
        : (trimmedAudioUrl.isNotEmpty
              ? trimmedAudioUrl.hashCode.abs()
              : trimmedAudioData.hashCode.abs());

    try {
      final DocumentReference<Map<String, dynamic>> sessionRef = _firestore
          .collection('shared_sessions')
          .doc();
      await sessionRef.set(<String, dynamic>{
        'sessionId': sessionRef.id,
        'chatId': chatId,
        'songId': resolvedSongId,
        'title': title.trim().isEmpty ? 'Unknown song' : title.trim(),
        'artist': artist.trim().isEmpty ? 'Unknown artist' : artist.trim(),
        'songName': songName.trim(),
        'coverUrl': coverUrl.trim(),
        'songUrl': trimmedAudioUrl,
        'audioUrl': trimmedAudioUrl,
        'audioData': trimmedAudioData,
        'hostUid': currentUserUid,
        'participants': <String>[currentUserUid],
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Listening session', 'Session started.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to start listening session.');
    }
  }

  Future<void> _joinListeningSession({
    required String sessionId,
    required String currentUserUid,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
  }) async {
    if (sessionId.trim().isEmpty) {
      return;
    }

    try {
      await _firestore.collection('shared_sessions').doc(sessionId).update(
        <String, dynamic>{
          'participants': FieldValue.arrayUnion(<String>[currentUserUid]),
        },
      );
      await _playSongForChat(
        cacheKey: 'session_$sessionId',
        songId: songId,
        songTitle: songTitle,
        songArtist: songArtist,
        songName: songName,
        coverUrl: coverUrl,
        audioUrl: audioUrl,
        audioData: audioData,
        toggleIfCurrent: false,
      );
    } catch (_) {
      Get.snackbar('Error', 'Failed to join listening session.');
    }
  }

  Future<void> _deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete message.');
    }
  }

  Future<void> _editMessage({
    required String chatId,
    required String messageId,
    required String currentText,
  }) async {
    final TextEditingController textController = TextEditingController(
      text: currentText,
    );
    String? newText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: textController,
            minLines: 1,
            maxLines: 4,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                newText = textController.text.trim();
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    final String updatedText = (newText ?? '').trim();
    if (updatedText.isEmpty || updatedText == currentText.trim()) {
      return;
    }

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(<String, dynamic>{'text': updatedText, 'edited': true});
    } catch (_) {
      Get.snackbar('Error', 'Failed to edit message.');
    }
  }

  Future<void> _setReaction({
    required String chatId,
    required String messageId,
    required String currentUserUid,
    required String reaction,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(<String, dynamic>{'reactions.$currentUserUid': reaction});
    } catch (_) {
      Get.snackbar('Error', 'Failed to react to message.');
    }
  }

  Future<void> _openReactionPicker({
    required BuildContext buttonContext,
    required String chatId,
    required String messageId,
    required String currentUserUid,
  }) async {
    final RenderBox? overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RenderBox? buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (overlayBox == null || buttonBox == null) {
      return;
    }

    final Offset topLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Offset bottomRight = buttonBox.localToGlobal(
      buttonBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    final String? reaction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlayBox.size.width - bottomRight.dx,
        overlayBox.size.height - topLeft.dy,
      ),
      items: _reactionOptions
          .map(
            (emoji) => PopupMenuItem<String>(
              value: emoji,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          )
          .toList(growable: false),
    );

    if (!mounted || reaction == null || reaction.trim().isEmpty) {
      return;
    }

    await _setReaction(
      chatId: chatId,
      messageId: messageId,
      currentUserUid: currentUserUid,
      reaction: reaction.trim(),
    );
  }

  String _resolveStringArg({
    required dynamic args,
    required String key,
    required String? localValue,
  }) {
    if (localValue != null && localValue.trim().isNotEmpty) {
      return localValue.trim();
    }

    if (args is Map<String, dynamic>) {
      return ((args[key] as String?) ?? '').trim();
    }

    return '';
  }

  Widget _buildChatHeader({
    required String chatId,
    required String otherUid,
    required String fallbackDisplayName,
    required String fallbackUsername,
    required String fallbackPhotoUrl,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(otherUid).snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          snapshot.data?.data() ?? <String, dynamic>{},
        );

        final String displayName =
            (userData['displayName'] as String?)?.trim().isNotEmpty == true
            ? (userData['displayName'] as String).trim()
            : fallbackDisplayName.isNotEmpty
            ? fallbackDisplayName
            : fallbackUsername.isNotEmpty
            ? fallbackUsername
            : 'User';
        final String photoUrl =
            (userData['photoUrl'] as String?)?.trim().isNotEmpty == true
            ? (userData['photoUrl'] as String).trim()
            : fallbackPhotoUrl;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('chats').doc(chatId).snapshots(),
          builder: (context, chatSnapshot) {
            final Map<String, dynamic> chatData = Map<String, dynamic>.from(
              chatSnapshot.data?.data() ?? <String, dynamic>{},
            );
            final Map<String, dynamic> typingMap = chatData['typing'] is Map
                ? Map<String, dynamic>.from(
                    chatData['typing'] as Map<dynamic, dynamic>,
                  )
                : <String, dynamic>{};
            final bool isOtherUserTyping = typingMap[otherUid] == true;

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UserProfilePage(uid: otherUid),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isOtherUserTyping
                              ? 'Typing...'
                              : fallbackUsername.isNotEmpty
                              ? '@$fallbackUsername'
                              : 'Online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isOtherUserTyping
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.60),
                                fontWeight: isOtherUserTyping
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongCover({
    required BuildContext context,
    required String coverUrl,
    required int songId,
    required bool isMine,
  }) {
    final Widget fallback = SongArtworkPlaceholder(
      width: 52,
      height: 52,
      borderRadius: BorderRadius.circular(14),
      icon: Icons.music_note_rounded,
      gradientColors: <Color>[
        isMine
            ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.34)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.92),
        isMine
            ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.16)
            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.88),
      ],
      iconColor: isMine
          ? Theme.of(context).colorScheme.onPrimary
          : Colors.white,
    );

    return SongArtwork(
      songId: songId,
      artworkUri: coverUrl,
      width: 52,
      height: 52,
      borderRadius: BorderRadius.circular(14),
      fallback: fallback,
    );
  }

  String _formatDuration(Duration value) {
    final Duration safe = value.isNegative ? Duration.zero : value;
    final int hours = safe.inHours;
    final int minutes = safe.inMinutes.remainder(60);
    final int seconds = safe.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${safe.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildSongPlaybackControls({
    required BuildContext context,
    required bool isMine,
    required String cacheKey,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
    required Duration fallbackDuration,
    required Color messageTextColor,
  }) {
    return Obx(() {
      final SongModel? currentSong = _playerController.currentSong.value;
      final String trimmedAudioUrl = audioUrl.trim();
      final String? cachedPath = _sharedAudioFileCache[cacheKey.trim()];
      final String cachedUri = cachedPath == null || cachedPath.isEmpty
          ? ''
          : Uri.file(cachedPath).toString();
      final bool isCurrentSong =
          currentSong != null &&
          ((songId > 0 && currentSong.id == songId) ||
              (trimmedAudioUrl.isNotEmpty &&
                  currentSong.uri == trimmedAudioUrl) ||
              (cachedUri.isNotEmpty && currentSong.uri == cachedUri));
      final bool isPlayingThisSong =
          isCurrentSong && _playerController.isPlaying.value;

      if (!isCurrentSong) {
        return _buildPlaybackBody(
          context: context,
          isMine: isMine,
          cacheKey: cacheKey,
          songId: songId,
          songTitle: songTitle,
          songArtist: songArtist,
          songName: songName,
          coverUrl: coverUrl,
          audioUrl: audioUrl,
          audioData: audioData,
          isPlayingThisSong: isPlayingThisSong,
          position: Duration.zero,
          total: fallbackDuration,
          canSeek: false,
          messageTextColor: messageTextColor,
        );
      }

      return StreamBuilder<Duration?>(
        stream: _playerController.durationStream,
        initialData: _playerController.total.value,
        builder: (context, durationSnapshot) {
          final Duration streamTotal = durationSnapshot.data ?? Duration.zero;
          final Duration total = streamTotal.inMilliseconds > 0
              ? streamTotal
              : fallbackDuration;

          return StreamBuilder<Duration>(
            stream: _playerController.positionStream,
            initialData: _playerController.position.value,
            builder: (context, positionSnapshot) {
              final Duration rawPosition =
                  positionSnapshot.data ?? Duration.zero;
              final Duration position =
                  total.inMilliseconds > 0 &&
                      rawPosition.inMilliseconds > total.inMilliseconds
                  ? total
                  : rawPosition;

              return _buildPlaybackBody(
                context: context,
                isMine: isMine,
                cacheKey: cacheKey,
                songId: songId,
                songTitle: songTitle,
                songArtist: songArtist,
                songName: songName,
                coverUrl: coverUrl,
                audioUrl: audioUrl,
                audioData: audioData,
                isPlayingThisSong: isPlayingThisSong,
                position: position,
                total: total,
                canSeek: total.inMilliseconds > 0,
                messageTextColor: messageTextColor,
              );
            },
          );
        },
      );
    });
  }

  Widget _buildPlaybackBody({
    required BuildContext context,
    required bool isMine,
    required String cacheKey,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
    required bool isPlayingThisSong,
    required Duration position,
    required Duration total,
    required bool canSeek,
    required Color messageTextColor,
  }) {
    final Color activeColor = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;
    final Color buttonBackground = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;
    final Color buttonForeground = isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onPrimary;

    final double max = total.inMilliseconds > 0
        ? total.inMilliseconds.toDouble()
        : 1.0;
    final int clampedPosition = position.inMilliseconds.clamp(0, max.toInt());
    final double sliderValue = clampedPosition.toDouble();
    final bool canPlay =
        songId > 0 || audioUrl.trim().isNotEmpty || audioData.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filled(
              onPressed: !canPlay
                  ? null
                  : () => _toggleSongPlayback(
                      cacheKey: cacheKey,
                      songId: songId,
                      songTitle: songTitle,
                      songArtist: songArtist,
                      songName: songName,
                      coverUrl: coverUrl,
                      audioUrl: audioUrl,
                      audioData: audioData,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: buttonBackground,
                foregroundColor: buttonForeground,
                minimumSize: const Size(42, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                isPlayingThisSong
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: activeColor.withValues(alpha: 0.30),
                  thumbColor: activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.16),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: max,
                  value: sliderValue,
                  onChanged: !canSeek
                      ? null
                      : (double value) {
                          _playerController.seek(
                            Duration(milliseconds: value.toInt()),
                          );
                        },
                ),
              ),
            ),
          ],
        ),
        Text(
          '${_formatDuration(position)} / ${_formatDuration(total)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: messageTextColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildSongMessageCard({
    required BuildContext context,
    required String chatId,
    required String currentUserUid,
    required String messageId,
    required bool isMine,
    required String coverUrl,
    required String audioUrl,
    required String audioData,
    required int songId,
    required String songTitle,
    required String songArtist,
    required String songName,
    required Color messageTextColor,
  }) {
    final Duration fallbackDuration =
        _homeController.findSongById(songId)?.duration ?? Duration.zero;
    final bool canUseSong =
        songId > 0 || audioUrl.trim().isNotEmpty || audioData.trim().isNotEmpty;
    final bool isSavePending = _savingSongMessageIds.contains(messageId);
    final bool isSaveCompleted = _savedSongMessageIds.contains(messageId);
    final String? saveError = _songSaveErrors[messageId];

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildSongCover(
              context: context,
              coverUrl: coverUrl,
              songId: songId,
              isMine: isMine,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    songTitle.isEmpty ? 'Unknown song' : songTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: messageTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    songArtist.isEmpty ? 'Unknown artist' : songArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: messageTextColor.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSongPlaybackControls(
          context: context,
          isMine: isMine,
          cacheKey: messageId,
          songId: songId,
          songTitle: songTitle,
          songArtist: songArtist,
          songName: songName,
          coverUrl: coverUrl,
          audioUrl: audioUrl,
          audioData: audioData,
          fallbackDuration: fallbackDuration,
          messageTextColor: messageTextColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (!isMine)
              OutlinedButton.icon(
                onPressed: !canUseSong || isSavePending || isSaveCompleted
                    ? null
                    : () => _saveReceivedSong(
                        messageId: messageId,
                        cacheKey: messageId,
                        songId: songId,
                        songTitle: songTitle,
                        songArtist: songArtist,
                        songName: songName,
                        coverUrl: coverUrl,
                        audioUrl: audioUrl,
                        audioData: audioData,
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isMine
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: isMine
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.35)
                        : Theme.of(context).dividerColor,
                  ),
                ),
                icon: isSavePending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isSaveCompleted
                            ? Icons.check_circle_rounded
                            : Icons.download_rounded,
                      ),
                label: Text(
                  isSavePending
                      ? 'Saving...'.tr
                      : isSaveCompleted
                      ? 'Saved'.tr
                      : 'Save'.tr,
                ),
              ),
            OutlinedButton.icon(
              onPressed: !canUseSong
                  ? null
                  : () => _startListeningSession(
                      chatId: chatId,
                      currentUserUid: currentUserUid,
                      songId: songId,
                      title: songTitle,
                      artist: songArtist,
                      songName: songName,
                      coverUrl: coverUrl,
                      audioUrl: audioUrl,
                      audioData: audioData,
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isMine
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: isMine
                      ? Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.35)
                      : Theme.of(context).dividerColor,
                ),
              ),
              icon: const Icon(Icons.headphones_rounded),
              label: const Text('Listen Together'),
            ),
          ],
        ),
        if (!isMine && isSaveCompleted) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Song saved to your library'.tr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: messageTextColor.withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (!isMine && saveError != null && saveError.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            saveError,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.red.shade200,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveSessionBanner({
    required BuildContext context,
    required String chatId,
    required String currentUserUid,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('shared_sessions')
          .where('chatId', isEqualTo: chatId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs.first;
        final Map<String, dynamic> data = doc.data();
        final String sessionId =
            (data['sessionId'] as String?)?.trim().isNotEmpty == true
            ? (data['sessionId'] as String).trim()
            : doc.id;
        final String title = (data['title'] as String?)?.trim() ?? '';
        final String artist = (data['artist'] as String?)?.trim() ?? '';
        final String songName = (data['songName'] as String?)?.trim() ?? '';
        final String coverUrl = (data['coverUrl'] as String?)?.trim() ?? '';
        final String songUrl = (data['songUrl'] as String?)?.trim() ?? '';
        final String audioUrl = songUrl.isNotEmpty
            ? songUrl
            : (data['audioUrl'] as String?)?.trim() ?? '';
        final String audioData = (data['audioData'] as String?)?.trim() ?? '';
        final int songId = (data['songId'] as num?)?.toInt() ?? 0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '\uD83C\uDFA7 Listening together',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                title.isEmpty ? 'Unknown song' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                artist.isEmpty ? 'Unknown artist' : artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed:
                      songId <= 0 && audioUrl.isEmpty && audioData.isEmpty
                      ? null
                      : () => _joinListeningSession(
                          sessionId: sessionId,
                          currentUserUid: currentUserUid,
                          songId: songId,
                          songTitle: title,
                          songArtist: artist,
                          songName: songName.isNotEmpty ? songName : title,
                          coverUrl: coverUrl,
                          audioUrl: audioUrl,
                          audioData: audioData,
                        ),
                  child: const Text('Join Listening'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;

    final String resolvedChatId = _resolveStringArg(
      args: args,
      key: 'chatId',
      localValue: widget.chatId,
    );
    final String resolvedOtherUid = _resolveStringArg(
      args: args,
      key: 'otherUid',
      localValue: widget.otherUid,
    );
    final String resolvedDisplayName = _resolveStringArg(
      args: args,
      key: 'otherDisplayName',
      localValue: widget.otherDisplayName,
    );
    final String resolvedUsername = _resolveStringArg(
      args: args,
      key: 'otherUsername',
      localValue: widget.otherUsername,
    );
    final String resolvedPhotoUrl = _resolveStringArg(
      args: args,
      key: 'otherPhotoUrl',
      localValue: widget.otherPhotoUrl,
    );

    final String titleFallback = resolvedDisplayName.isNotEmpty
        ? resolvedDisplayName
        : resolvedUsername.isNotEmpty
        ? '@$resolvedUsername'
        : 'Chat';
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (resolvedChatId.isNotEmpty && currentUserUid != null) {
      _syncTypingContext(
        chatId: resolvedChatId,
        currentUserUid: currentUserUid,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: resolvedOtherUid.isEmpty
            ? Text(titleFallback)
            : _buildChatHeader(
                chatId: resolvedChatId,
                otherUid: resolvedOtherUid,
                fallbackDisplayName: resolvedDisplayName,
                fallbackUsername: resolvedUsername,
                fallbackPhotoUrl: resolvedPhotoUrl,
              ),
      ),
      body:
          resolvedChatId.isEmpty ||
              currentUserUid == null ||
              currentUserUid.isEmpty
          ? const Center(child: Text('Chat unavailable.'))
          : MusicPageBackground(
              child: Column(
                children: <Widget>[
                  _buildActiveSessionBanner(
                    context: context,
                    chatId: resolvedChatId,
                    currentUserUid: currentUserUid,
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('chats')
                          .doc(resolvedChatId)
                          .collection('messages')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        docs =
                            snapshot.data?.docs ??
                            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                        if (docs.isEmpty) {
                          return Center(child: Text('No messages yet'.tr));
                        }

                        return ListView.builder(
                          controller: _messageListController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final QueryDocumentSnapshot<Map<String, dynamic>>
                            doc = docs[index];
                            final Map<String, dynamic> data = doc.data();
                            final String messageType =
                                (data['type'] as String?)
                                    ?.trim()
                                    .toLowerCase() ??
                                'text';
                            final String senderUid =
                                ((data['senderUid'] as String?) ??
                                        (data['senderId'] as String?) ??
                                        '')
                                    .trim();
                            final String text =
                                (data['text'] as String?)?.trim() ?? '';
                            final String songTitle =
                                (data['title'] as String?)?.trim() ?? '';
                            final String songArtist =
                                (data['artist'] as String?)?.trim() ?? '';
                            final String songName =
                                (data['songName'] as String?)?.trim() ?? '';
                            final String coverUrl =
                                (data['coverUrl'] as String?)?.trim() ?? '';
                            final String songUrl =
                                (data['songUrl'] as String?)?.trim() ?? '';
                            final String audioUrl = songUrl.isNotEmpty
                                ? songUrl
                                : (data['audioUrl'] as String?)?.trim() ?? '';
                            final String audioData =
                                (data['audioData'] as String?)?.trim() ?? '';
                            final int songId =
                                (data['songId'] as num?)?.toInt() ?? 0;
                            final String resolvedSongTitle =
                                songTitle.isNotEmpty ? songTitle : songName;
                            final bool isSongMessage = messageType == 'song';

                            if (!isSongMessage && text.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final String previousSenderUid = index > 0
                                ? ((docs[index - 1].data()['senderUid']
                                              as String?) ??
                                          (docs[index - 1].data()['senderId']
                                              as String?) ??
                                          '')
                                      .trim()
                                : '';
                            final String nextSenderUid = index + 1 < docs.length
                                ? ((docs[index + 1].data()['senderUid']
                                              as String?) ??
                                          (docs[index + 1].data()['senderId']
                                              as String?) ??
                                          '')
                                      .trim()
                                : '';
                            final bool groupedWithPrevious =
                                previousSenderUid.isNotEmpty &&
                                previousSenderUid == senderUid;
                            final bool groupedWithNext =
                                nextSenderUid.isNotEmpty &&
                                nextSenderUid == senderUid;
                            final DateTime? sentAt = _resolveMessageDateTime(
                              data['createdAt'],
                            );
                            final String timeLabel = _formatMessageTime(
                              context,
                              sentAt,
                            );
                            final bool isMine = senderUid == currentUserUid;
                            final ThemeData theme = Theme.of(context);
                            final Color bubbleColor = isMine
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.94,
                                  )
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.82);
                            final Color bubbleTextColor = isMine
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface;
                            final bool isEdited = data['edited'] == true;
                            final bool canEdit = isMine && !isSongMessage;
                            final Map<String, dynamic> reactionMap =
                                data['reactions'] is Map
                                ? Map<String, dynamic>.from(
                                    data['reactions'] as Map<dynamic, dynamic>,
                                  )
                                : <String, dynamic>{};
                            final List<String> reactions = reactionMap.values
                                .whereType<String>()
                                .map((emoji) => emoji.trim())
                                .where((emoji) => emoji.isNotEmpty)
                                .toList(growable: false);

                            final bool isSelected =
                                _selectedMessageId == doc.id;

                            return _AnimatedChatMessage(
                              key: ValueKey<String>('message-${doc.id}'),
                              child: Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: isSelected
                                      ? () {
                                          setState(() {
                                            _selectedMessageId = null;
                                          });
                                        }
                                      : null,
                                  onLongPress: () {
                                    setState(() {
                                      _selectedMessageId = doc.id;
                                    });
                                  },
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.80,
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: groupedWithPrevious ? 3 : 12,
                                        bottom: groupedWithNext ? 3 : 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMine
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                              15,
                                              12,
                                              15,
                                              10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bubbleColor,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                  isMine
                                                      ? 24
                                                      : groupedWithPrevious
                                                      ? 12
                                                      : 24,
                                                ),
                                                topRight: Radius.circular(
                                                  isMine
                                                      ? groupedWithPrevious
                                                            ? 12
                                                            : 24
                                                      : 24,
                                                ),
                                                bottomLeft: Radius.circular(
                                                  isMine
                                                      ? 24
                                                      : groupedWithNext
                                                      ? 12
                                                      : 8,
                                                ),
                                                bottomRight: Radius.circular(
                                                  isMine
                                                      ? groupedWithNext
                                                            ? 12
                                                            : 8
                                                      : 24,
                                                ),
                                              ),
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.05),
                                              ),
                                              boxShadow: <BoxShadow>[
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: isMine
                                                            ? 0.16
                                                            : 0.08,
                                                      ),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMine
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: <Widget>[
                                                if (isSongMessage)
                                                  _buildSongMessageCard(
                                                    context: context,
                                                    chatId: resolvedChatId,
                                                    currentUserUid:
                                                        currentUserUid,
                                                    messageId: doc.id,
                                                    isMine: isMine,
                                                    coverUrl: coverUrl,
                                                    audioUrl: audioUrl,
                                                    audioData: audioData,
                                                    songId: songId,
                                                    songTitle:
                                                        resolvedSongTitle,
                                                    songArtist: songArtist,
                                                    songName: songName,
                                                    messageTextColor:
                                                        bubbleTextColor,
                                                  )
                                                else
                                                  Text(
                                                    text,
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color:
                                                              bubbleTextColor,
                                                          height: 1.52,
                                                        ),
                                                  ),
                                                if (timeLabel.isNotEmpty ||
                                                    isEdited) ...<Widget>[
                                                  SizedBox(
                                                    height: isSongMessage
                                                        ? 10
                                                        : 8,
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      if (isEdited)
                                                        Text(
                                                          'Edited'.tr,
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: bubbleTextColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.74,
                                                                    ),
                                                              ),
                                                        ),
                                                      if (isEdited &&
                                                          timeLabel.isNotEmpty)
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                      if (timeLabel.isNotEmpty)
                                                        Text(
                                                          timeLabel,
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: bubbleTextColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.74,
                                                                    ),
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (reactions.isNotEmpty) ...<Widget>[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: reactions
                                                  .map(
                                                    (emoji) => Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(emoji),
                                                    ),
                                                  )
                                                  .toList(growable: false),
                                            ),
                                          ],
                                          if (isSelected) ...<Widget>[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: <Widget>[
                                                if (canEdit)
                                                  TextButton(
                                                    onPressed: () async {
                                                      await _editMessage(
                                                        chatId: resolvedChatId,
                                                        messageId: doc.id,
                                                        currentText: text,
                                                      );
                                                      if (mounted) {
                                                        setState(() {
                                                          _selectedMessageId =
                                                              null;
                                                        });
                                                      }
                                                    },
                                                    child: Text('Edit'.tr),
                                                  ),
                                                if (isMine)
                                                  TextButton(
                                                    onPressed: () async {
                                                      await _deleteMessage(
                                                        chatId: resolvedChatId,
                                                        messageId: doc.id,
                                                      );
                                                      if (mounted) {
                                                        setState(() {
                                                          _selectedMessageId =
                                                              null;
                                                        });
                                                      }
                                                    },
                                                    child: Text('Delete'.tr),
                                                  ),
                                                Builder(
                                                  builder: (buttonContext) {
                                                    return TextButton(
                                                      onPressed: () async {
                                                        await _openReactionPicker(
                                                          buttonContext:
                                                              buttonContext,
                                                          chatId:
                                                              resolvedChatId,
                                                          messageId: doc.id,
                                                          currentUserUid:
                                                              currentUserUid,
                                                        );
                                                        if (mounted) {
                                                          setState(() {
                                                            _selectedMessageId =
                                                                null;
                                                          });
                                                        }
                                                      },
                                                      child: Text('React'.tr),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _isComposerFocused
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.36)
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.08),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color:
                                  (_isComposerFocused
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.black)
                                      .withValues(
                                        alpha: _isComposerFocused ? 0.16 : 0.08,
                                      ),
                              blurRadius: _isComposerFocused ? 24 : 14,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            IconButton.filledTonal(
                              onPressed: _isSending
                                  ? null
                                  : () => _openSongSelector(
                                      chatId: resolvedChatId,
                                      currentUserUid: currentUserUid,
                                    ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(46, 46),
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.music_note_rounded),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                onChanged: (String value) =>
                                    _handleTypingChanged(
                                      chatId: resolvedChatId,
                                      currentUserUid: currentUserUid,
                                      value: value,
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...'.tr,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: _isSending
                                  ? null
                                  : () => _sendMessage(
                                      chatId: resolvedChatId,
                                      currentUserUid: currentUserUid,
                                    ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
