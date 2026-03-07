import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;

import '../controllers/home_controller.dart';
import '../controllers/player_controller.dart';
import '../data/models/song_model.dart';
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

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController _homeController = Get.find<HomeController>();
  final PlayerController _playerController = Get.find<PlayerController>();
  final audio_query.OnAudioQuery _audioQuery = audio_query.OnAudioQuery();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _selectedMessageId;

  static const List<String> _reactionOptions = <String>[
    '\u2764\uFE0F',
    '\uD83D\uDE02',
    '\uD83D\uDC4D',
    '\uD83D\uDD25',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
    } catch (_) {
      Get.snackbar('Error', 'Failed to send message.');
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
      final DocumentReference<Map<String, dynamic>> chatRef = _firestore
          .collection('chats')
          .doc(chatId);

      await chatRef.collection('messages').add(<String, dynamic>{
        'senderUid': currentUserUid,
        'type': 'song',
        'songId': song.id,
        'title': song.title,
        'artist': song.artist,
        'coverUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await chatRef.update(<String, dynamic>{
        'lastMessage': '\uD83C\uDFB5 ${song.title}',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      Get.snackbar('Error', 'Failed to send song.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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
          return const SizedBox(
            height: 220,
            child: Center(child: Text('No songs available.')),
          );
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: ListView.separated(
            itemCount: songs.length,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final SongModel song = songs[index];
              return ListTile(
                onTap: () => Navigator.of(context).pop(song),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: Theme.of(context).cardColor,
                leading: SongArtwork(
                  songId: song.artworkId,
                  width: 46,
                  height: 46,
                  borderRadius: BorderRadius.circular(10),
                  fallback: Container(
                    width: 46,
                    height: 46,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.music_note_rounded),
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

    final SongModel? localSong = _homeController.findSongById(songId);
    if (localSong != null) {
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
          return SongModel.fromAudioQuery(rawSong);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _toggleSongPlayback({
    required int songId,
    required String songTitle,
  }) async {
    final SongModel? song = await _findSongById(songId);
    if (song == null) {
      Get.snackbar('Error', 'Song not found on device.');
      return;
    }

    final int? currentSongId = _playerController.currentSong.value?.id;
    if (currentSongId == song.id) {
      if (_playerController.isPlaying.value) {
        await _playerController.pause();
      } else {
        await _playerController.play();
      }
      return;
    }

    try {
      if (currentSongId != null) {
        await _playerController.stop();
      }

      final List<SongModel> baseQueue = _homeController.songs.isNotEmpty
          ? _homeController.songs.toList(growable: false)
          : <SongModel>[song];

      final bool queueContainsSong = baseQueue.any(
        (SongModel item) => item.id == song.id,
      );
      final List<SongModel> queue = queueContainsSong
          ? baseQueue
          : <SongModel>[song, ...baseQueue];

      await _playerController.playFromQueue(queue, song);
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to play ${songTitle.trim().isEmpty ? 'song' : songTitle}.',
      );
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
      await Future<void>.delayed(Duration.zero);
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

        return InkWell(
          borderRadius: BorderRadius.circular(20),
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
                radius: 16,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
    final Widget fallback = Container(
      width: 52,
      height: 52,
      color: isMine
          ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.18)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.music_note,
        color: isMine ? Theme.of(context).colorScheme.onPrimary : null,
      ),
    );

    if (coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          coverUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    if (songId > 0) {
      return SongArtwork(
        songId: songId,
        width: 52,
        height: 52,
        borderRadius: BorderRadius.circular(10),
        fallback: fallback,
      );
    }

    return ClipRRect(borderRadius: BorderRadius.circular(10), child: fallback);
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
    required int songId,
    required String songTitle,
    required Duration fallbackDuration,
  }) {
    return Obx(() {
      final bool isCurrentSong =
          _playerController.currentSong.value?.id == songId;
      final bool isPlayingThisSong =
          isCurrentSong && _playerController.isPlaying.value;

      if (!isCurrentSong) {
        return _buildPlaybackBody(
          context: context,
          isMine: isMine,
          songId: songId,
          songTitle: songTitle,
          isPlayingThisSong: isPlayingThisSong,
          position: Duration.zero,
          total: fallbackDuration,
          canSeek: false,
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
                songId: songId,
                songTitle: songTitle,
                isPlayingThisSong: isPlayingThisSong,
                position: position,
                total: total,
                canSeek: total.inMilliseconds > 0,
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
    required int songId,
    required String songTitle,
    required bool isPlayingThisSong,
    required Duration position,
    required Duration total,
    required bool canSeek,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filled(
              onPressed: songId <= 0
                  ? null
                  : () => _toggleSongPlayback(
                      songId: songId,
                      songTitle: songTitle,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: buttonBackground,
                foregroundColor: buttonForeground,
                minimumSize: const Size(36, 36),
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
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: max,
                  value: sliderValue,
                  onChanged: songId <= 0 || !canSeek
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
            color: isMine
                ? Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.85)
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSongMessageCard({
    required BuildContext context,
    required bool isMine,
    required String coverUrl,
    required int songId,
    required String songTitle,
    required String songArtist,
  }) {
    final Duration fallbackDuration =
        _homeController.findSongById(songId)?.duration ?? Duration.zero;

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
                      color: isMine
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    songArtist.isEmpty ? 'Unknown artist' : songArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMine
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.82)
                          : Theme.of(context).textTheme.bodySmall?.color,
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
          songId: songId,
          songTitle: songTitle,
          fallbackDuration: fallbackDuration,
        ),
      ],
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

    return Scaffold(
      appBar: AppBar(
        title: resolvedOtherUid.isEmpty
            ? Text(titleFallback)
            : _buildChatHeader(
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
          : Column(
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('chats')
                        .doc(resolvedChatId)
                        .collection('messages')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      docs =
                          snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                      if (docs.isEmpty) {
                        return const Center(child: Text('No messages yet'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final QueryDocumentSnapshot<Map<String, dynamic>>
                          doc = docs[index];
                          final Map<String, dynamic> data = doc.data();
                          final String messageType =
                              (data['type'] as String?)?.trim().toLowerCase() ??
                              'text';
                          final String senderUid =
                              (data['senderUid'] as String?)?.trim() ?? '';
                          final String text =
                              (data['text'] as String?)?.trim() ?? '';
                          final String songTitle =
                              (data['title'] as String?)?.trim() ?? '';
                          final String songArtist =
                              (data['artist'] as String?)?.trim() ?? '';
                          final String coverUrl =
                              (data['coverUrl'] as String?)?.trim() ?? '';
                          final int songId =
                              (data['songId'] as num?)?.toInt() ?? 0;
                          final bool isSongMessage = messageType == 'song';

                          if (!isSongMessage && text.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final bool isMine = senderUid == currentUserUid;
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

                          final bool isSelected = _selectedMessageId == doc.id;

                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  _selectedMessageId = doc.id;
                                });
                              },
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.74,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMine
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: <Widget>[
                                            if (isSongMessage)
                                              _buildSongMessageCard(
                                                context: context,
                                                isMine: isMine,
                                                coverUrl: coverUrl,
                                                songId: songId,
                                                songTitle: songTitle,
                                                songArtist: songArtist,
                                              )
                                            else
                                              Text(
                                                text,
                                                style: TextStyle(
                                                  color: isMine
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary
                                                      : null,
                                                ),
                                              ),
                                            if (!isSongMessage &&
                                                isEdited) ...<Widget>[
                                              const SizedBox(height: 4),
                                              Text(
                                                '(edited)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: isMine
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .onPrimary
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                )
                                                          : Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.color,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (reactions.isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: reactions
                                              .map(
                                                (emoji) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(
                                                      context,
                                                    ).cardColor,
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
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
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
                                                      _selectedMessageId = null;
                                                    });
                                                  }
                                                },
                                                child: const Text('Edit'),
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
                                                      _selectedMessageId = null;
                                                    });
                                                  }
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            Builder(
                                              builder: (buttonContext) {
                                                return TextButton(
                                                  onPressed: () async {
                                                    await _openReactionPicker(
                                                      buttonContext:
                                                          buttonContext,
                                                      chatId: resolvedChatId,
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
                                                  child: const Text('React'),
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
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: _isSending
                              ? null
                              : () => _openSongSelector(
                                  chatId: resolvedChatId,
                                  currentUserUid: currentUserUid,
                                ),
                          icon: const Icon(Icons.music_note),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSending
                              ? null
                              : () => _sendMessage(
                                  chatId: resolvedChatId,
                                  currentUserUid: currentUserUid,
                                ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
