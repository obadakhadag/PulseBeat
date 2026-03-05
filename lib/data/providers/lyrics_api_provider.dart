import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';

class LyricsApiProvider {
  LyricsApiProvider(this._dio);

  final Dio _dio;

  Future<String?> fetchLyrics({
    required String artist,
    required String title,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '${AppConstants.lyricsBaseUrl}/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final lyrics = data['lyrics'] as String?;
        if (lyrics != null && lyrics.trim().isNotEmpty) {
          return lyrics.trim();
        }
      }
    } on DioException {
      return null;
    }
    return null;
  }
}
