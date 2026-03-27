import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../controllers/app_shell_controller.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/search_controller.dart' as app_search;
import '../../controllers/settings_controller.dart';
import '../../controllers/splash_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/lyrics_api_provider.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/lyrics_repository.dart';
import '../../services/audio_player_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/follow_service.dart';
import '../../services/permissions_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppShellController>(AppShellController(), permanent: true);

    Get.put<StorageService>(
      StorageService(AppConstants.storageBox),
      permanent: true,
    );

    Get.put<AppController>(
      AppController(storageService: Get.find<StorageService>()),
      permanent: true,
    );

    Get.put<SettingsController>(
      SettingsController(Get.find<StorageService>()),
      permanent: true,
    );

    Get.put<AudioRepository>(
      AudioRepository(OnAudioQuery(), Get.find<StorageService>()),
      permanent: true,
    );

    Get.put<LyricsRepository>(
      LyricsRepository(LyricsApiProvider(Dio())),
      permanent: true,
    );

    Get.put<AudioPlayerService>(AudioPlayerService(), permanent: true);

    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
    Get.lazyPut<ChatService>(() => ChatService(), fenix: true);
    Get.lazyPut<PermissionsService>(() => PermissionsService(), fenix: true);
    Get.lazyPut<FollowService>(
      () => FollowService(authService: Get.find<AuthService>()),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(
        appController: Get.find<AppController>(),
        authService: Get.find<AuthService>(),
        userService: Get.find<UserService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<FollowController>(
      () => FollowController(followService: Get.find<FollowService>()),
      fenix: true,
    );
    Get.lazyPut<ChatController>(
      () => ChatController(chatService: Get.find<ChatService>()),
      fenix: true,
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

    Get.lazyPut<app_search.SearchController>(
      () => app_search.SearchController(userService: Get.find<UserService>()),
      fenix: true,
    );
  }
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        storageService: Get.find<StorageService>(),
        appController: Get.find<AppController>(),
      ),
    );
  }
}
