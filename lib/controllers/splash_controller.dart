import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import '../firebase_options.dart';
import '../routes/app_pages.dart';
import '../services/storage_service.dart';

class SplashController extends GetxController {
  SplashController({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  bool _didNavigate = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await initializeApp();
      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
      _routeNext(isLoggedIn: isLoggedIn);
    } catch (_) {
      _routeNext(isLoggedIn: false);
    }
  }

  Future<void> initializeApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _initializeFirebase();
    await _storageService.ensureInitialized();
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
