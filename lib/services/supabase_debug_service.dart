// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseDebugService {
  static Future<String?> uploadSongDebug(String filePath) async {
    print('STEP 1: Starting song upload process');

    try {
      print('STEP 2: Checking file path');
      print('File path: $filePath');
      final File file = File(filePath);

      if (!await file.exists()) {
        print('ERROR: File does not exist');
        return null;
      }

      print('STEP 3: File exists');

      final int fileSize = await file.length();
      print('STEP 4: File size: $fileSize bytes');

      print('STEP 5: Reading file bytes');
      final Uint8List bytes = await file.readAsBytes();

      print('STEP 6: Bytes read successfully');

      final String fileName =
          'song_${DateTime.now().millisecondsSinceEpoch}.mp3';

      print('STEP 7: Uploading to Supabase bucket: songs');
      print('Generated file name: $fileName');

      final String response = await supabase.storage
          .from('songs')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('STEP 8: Upload response received');
      print(response);

      print('STEP 9: Generating public URL');

      final String publicUrl = supabase.storage
          .from('songs')
          .getPublicUrl(fileName);

      print('STEP 10: Upload successful');
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      print('SUPABASE STORAGE ERROR:');
      print(e.toString());
      print('SUPABASE STORAGE STACK TRACE:');
      print(stackTrace.toString());

      return null;
    }
  }

  static Future<String?> uploadArtworkDebug(
    Uint8List bytes, {
    String fileExtension = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      return null;
    }

    try {
      final String path =
          'covers/cover_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await supabase.storage
          .from('songs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return supabase.storage.from('songs').getPublicUrl(path);
    } catch (e, stackTrace) {
      print('SUPABASE ARTWORK UPLOAD ERROR:');
      print(e.toString());
      print('SUPABASE ARTWORK STACK TRACE:');
      print(stackTrace.toString());
      return null;
    }
  }
}
