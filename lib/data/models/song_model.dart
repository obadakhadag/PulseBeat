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
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String filePath;
  final String uri;
  final int artworkId;

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
    );
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

  bool get hasArabicTitle => RegExp(r'[\u0600-\u06FF]').hasMatch(title);

  bool get hasEnglishTitle => RegExp(r'[A-Za-z]').hasMatch(title);

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
