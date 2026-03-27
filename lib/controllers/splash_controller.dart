import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'app_controller.dart';
import '../firebase_options.dart';
import '../routes/app_pages.dart';
import '../services/storage_service.dart';

class SplashController extends GetxController {
  SplashController({
    required StorageService storageService,
    required AppController appController,
  }) : _storageService = storageService,
       _appController = appController;

  final StorageService _storageService;
  final AppController _appController;

  bool _didNavigate = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await initializeApp();
      if (_appController.isOffline) {
        _routeNext(isLoggedIn: true);
        return;
      }

      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
      _routeNext(isLoggedIn: isLoggedIn);
    } catch (_) {
      _routeNext(isLoggedIn: false);
    }
  }

  Future<void> initializeApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _storageService.ensureInitialized();
    await _appController.restoreAppMode();
    if (_appController.isOnline) {
      await _initializeFirebase();
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _routeNext({required bool isLoggedIn}) {
    if (_didNavigate || isClosed) {
      return;
    }

    _didNavigate = true;
    Get.offAllNamed(isLoggedIn ? AppPages.home : AppPages.login);
  }
}
