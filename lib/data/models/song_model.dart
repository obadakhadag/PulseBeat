import 'package:on_audio_query/on_audio_query.dart' as audio_query;

class SongModel {
  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
    required this.uri,
    required this.artworkId,
    this.artworkUri,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String filePath;
  final String uri;
  final int artworkId;
  final String? artworkUri;

  factory SongModel.fromAudioQuery(audio_query.SongModel song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? '<unknown>',
      album: song.album ?? 'Singles',
      duration: Duration(milliseconds: song.duration ?? 0),
      filePath: song.data,
      uri: song.uri ?? '',
      artworkId: song.id,
      artworkUri: null,
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> data) {
    return SongModel(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: (data['title'] as String?) ?? 'Unknown song',
      artist: (data['artist'] as String?) ?? '<unknown>',
      album: (data['album'] as String?) ?? 'Singles',
      duration: Duration(
        milliseconds: (data['durationMs'] as num?)?.toInt() ?? 0,
      ),
      filePath: (data['filePath'] as String?) ?? '',
      uri: (data['uri'] as String?) ?? '',
      artworkId: (data['artworkId'] as num?)?.toInt() ?? 0,
      artworkUri: (data['artworkUri'] as String?)?.trim(),
    );
  }

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? filePath,
    String? uri,
    int? artworkId,
    String? artworkUri,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      uri: uri ?? this.uri,
      artworkId: artworkId ?? this.artworkId,
      artworkUri: artworkUri ?? this.artworkUri,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'filePath': filePath,
      'uri': uri,
      'artworkId': artworkId,
      'artworkUri': artworkUri,
    };
  }

  String get normalizedFilePath => filePath.replaceAll('\\', '/');

  String get folderPath {
    final normalized = normalizedFilePath;
    final separatorIndex = normalized.lastIndexOf('/');
    if (separatorIndex <= 0) {
      return '';
    }
    return normalized.substring(0, separatorIndex);
  }

  String get folderName {
    final folder = folderPath;
    if (folder.isEmpty) {
      return 'Unknown folder';
    }
    final separatorIndex = folder.lastIndexOf('/');
    return separatorIndex >= 0 ? folder.substring(separatorIndex + 1) : folder;
  }

  String get _languageSourceText =>
      <String>[title, artist, album, folderName].join(' ');

  bool get hasArabicTitle =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(_languageSourceText);

  bool get hasEnglishTitle => RegExp(r'[A-Za-z]').hasMatch(_languageSourceText);

  String get titleLanguageKey {
    if (hasArabicTitle) {
      return 'arabic';
    }
    if (hasEnglishTitle) {
      return 'english';
    }
    return 'other';
  }
}
