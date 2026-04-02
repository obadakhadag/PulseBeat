class AppConstants {
  const AppConstants._();

  static const String appName = 'PulseBeat';
  static const String storageBox = 'pulsebeat_box';
  static const String defaultAvatarAsset = 'assets/images/default_avatar.png';
  static const String launcherIconAsset =
      'assets/branding/pulsebeat_launcher_icon.png';
  static const String profileImagesFolder = 'profile_images';
  static const String favoritesKey = 'favorites';
  static const String recentKey = 'recent_tracks';
  static const String playCountsKey = 'play_counts';
  static const String sortKey = 'library_sort';
  static const String groupKey = 'library_group';
  static const String downloadedSongsKey = 'downloaded_songs';
  static const String downloadedSongsFolder = 'PulseBeat';
  static const String legacyDownloadedSongsFolder = 'downloaded_songs';
  static const String androidDownloadedSongsPath =
      '/storage/emulated/0/PulseBeat';
  static const String appModeKey = 'app_mode';
  static const String cachedLibrarySongIdsKey = 'cached_library_song_ids';
  static const String lastLibrarySyncSignatureKey =
      'last_library_sync_signature';
  static const String lastLibrarySyncUidKey = 'last_library_sync_uid';
  static const String themeModeKey = 'theme_mode';
  static const String languageCodeKey = 'language_code';
  static const String showLyricsKey = 'show_lyrics';
  static const String immersivePlayerKey = 'immersive_player';
  static const String lyricsBaseUrl = 'https://api.lyrics.ovh/v1';
  static const int recentLimit = 18;
}
