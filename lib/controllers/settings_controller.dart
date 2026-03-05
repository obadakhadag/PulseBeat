import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';

class SettingsController extends GetxController {
  SettingsController(this._storageService);

  final StorageService _storageService;

  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;
  final RxBool showLyrics = true.obs;
  final RxBool immersivePlayer = true.obs;

  @override
  void onInit() {
    super.onInit();
    final storedTheme = _storageService.getThemeMode();
    themeMode.value = switch (storedTheme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    showLyrics.value = _storageService.getShowLyrics();
    immersivePlayer.value = _storageService.getImmersivePlayer();
  }

  void setThemeMode(ThemeMode value) {
    themeMode.value = value;
    _storageService.setThemeMode(switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    });
  }

  void setShowLyrics(bool value) {
    showLyrics.value = value;
    _storageService.setShowLyrics(value);
  }

  void setImmersivePlayer(bool value) {
    immersivePlayer.value = value;
    _storageService.setImmersivePlayer(value);
  }
}
