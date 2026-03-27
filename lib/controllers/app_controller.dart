import 'package:get/get.dart';

import '../core/enums/app_mode.dart';
import '../services/storage_service.dart';

class AppController extends GetxController {
  AppController({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  final Rx<AppMode> appMode = AppMode.online.obs;

  bool get isOnline => appMode.value == AppMode.online;
  bool get isOffline => appMode.value == AppMode.offline;

  Future<void> restoreAppMode() async {
    await _storageService.ensureInitialized();
    appMode.value = _storageService.getAppMode();
  }

  Future<void> setAppMode(AppMode mode) async {
    await _storageService.ensureInitialized();
    if (appMode.value != mode) {
      appMode.value = mode;
    }
    _storageService.setAppMode(mode);
  }
}
