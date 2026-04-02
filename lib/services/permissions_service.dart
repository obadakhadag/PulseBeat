import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<bool> requestAudioAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final statuses = await <Permission>[
      Permission.audio,
      Permission.storage,
    ].request();

    return statuses.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> requestPulseBeatFolderAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final PermissionStatus manageStorageStatus = await Permission
        .manageExternalStorage
        .request();
    if (manageStorageStatus.isGranted) {
      return true;
    }

    final PermissionStatus storageStatus = await Permission.storage.request();
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  Future<bool> isAudioAccessGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    return audioStatus.isGranted ||
        audioStatus.isLimited ||
        storageStatus.isGranted;
  }

  Future<void> openSettings() => openAppSettings();
}
