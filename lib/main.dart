import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'controllers/auth_controller.dart';
import 'controllers/follow_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/player_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'data/providers/lyrics_api_provider.dart';
import 'data/repositories/audio_repository.dart';
import 'data/repositories/lyrics_repository.dart';
import 'routes/app_pages.dart';
import 'services/audio_player_service.dart';
import 'services/auth_service.dart';
import 'services/follow_service.dart';
import 'services/permissions_service.dart';
import 'services/storage_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local storage
  await GetStorage.init(AppConstants.storageBox);

  final storage = StorageService(GetStorage(AppConstants.storageBox));
  Get.put<StorageService>(storage, permanent: true);
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<UserService>(UserService(), permanent: true);
  Get.put<FollowService>(
    FollowService(authService: Get.find<AuthService>()),
    permanent: true,
  );

  Get.put<AuthController>(
    AuthController(
      authService: Get.find<AuthService>(),
      userService: Get.find<UserService>(),
    ),
    permanent: true,
  );
  Get.put<FollowController>(
    FollowController(followService: Get.find<FollowService>()),
    permanent: true,
  );

  Get.put<PermissionsService>(PermissionsService(), permanent: true);
  Get.put<AudioRepository>(AudioRepository(OnAudioQuery()), permanent: true);

  Get.put<LyricsRepository>(
    LyricsRepository(LyricsApiProvider(Dio())),
    permanent: true,
  );

  Get.put<AudioPlayerService>(
    AudioPlayerService(AudioPlayer()),
    permanent: true,
  );

  Get.put<SettingsController>(
    SettingsController(Get.find<StorageService>()),
    permanent: true,
  );

  Get.put<PlayerController>(
    PlayerController(
      audioService: Get.find<AudioPlayerService>(),
      lyricsRepository: Get.find<LyricsRepository>(),
      storageService: Get.find<StorageService>(),
    ),
    permanent: true,
  );

  Get.put<HomeController>(
    HomeController(
      audioRepository: Get.find<AudioRepository>(),
      permissionsService: Get.find<PermissionsService>(),
      storageService: Get.find<StorageService>(),
      playerController: Get.find<PlayerController>(),
    ),
    permanent: true,
  );

  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode.value,
        getPages: AppPages.pages,
        initialRoute: AppPages.splash,
      ),
    );
  }
}
