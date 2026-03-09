import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../controllers/search_controller.dart' as app_search;
import '../../controllers/settings_controller.dart';
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

class AppBindings {
  AppBindings._();

  static bool _registered = false;

  static void ensureInitialized() {
    if (_registered) {
      return;
    }
    _registered = true;

    Get.put<StorageService>(
      StorageService(AppConstants.storageBox),
      permanent: true,
    );

    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
    Get.lazyPut<ChatService>(() => ChatService(), fenix: true);
    Get.lazyPut<PermissionsService>(() => PermissionsService(), fenix: true);
    Get.lazyPut<AudioRepository>(
      () => AudioRepository(OnAudioQuery()),
      fenix: true,
    );
    Get.lazyPut<LyricsRepository>(
      () => LyricsRepository(LyricsApiProvider(Dio())),
      fenix: true,
    );
    Get.lazyPut<AudioPlayerService>(
      () => AudioPlayerService(AudioPlayer()),
      fenix: true,
    );
    Get.lazyPut<FollowService>(
      () => FollowService(authService: Get.find<AuthService>()),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(
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
    Get.lazyPut<app_search.SearchController>(
      () => app_search.SearchController(userService: Get.find<UserService>()),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(Get.find<StorageService>()),
      fenix: true,
    );
    Get.lazyPut<PlayerController>(
      () => PlayerController(
        audioService: Get.find<AudioPlayerService>(),
        lyricsRepository: Get.find<LyricsRepository>(),
        storageService: Get.find<StorageService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(
        audioRepository: Get.find<AudioRepository>(),
        permissionsService: Get.find<PermissionsService>(),
        storageService: Get.find<StorageService>(),
        playerController: Get.find<PlayerController>(),
      ),
      fenix: true,
    );
  }
}
