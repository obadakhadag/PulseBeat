import 'dart:async';

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
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    await _storageService.ensureInitialized();

    final storedTheme = _storageService.getThemeMode();
    themeMode.value = switch (storedTheme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    Get.changeThemeMode(themeMode.value);
    showLyrics.value = _storageService.getShowLyrics();
    immersivePlayer.value = _storageService.getImmersivePlayer();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    await _storageService.ensureInitialized();
    themeMode.value = value;
    Get.changeThemeMode(value);
    _storageService.setThemeMode(switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    });
  }

  Future<void> setShowLyrics(bool value) async {
    await _storageService.ensureInitialized();
    showLyrics.value = value;
    _storageService.setShowLyrics(value);
  }

  Future<void> setImmersivePlayer(bool value) async {
    await _storageService.ensureInitialized();
    immersivePlayer.value = value;
    _storageService.setImmersivePlayer(value);
  }
}
