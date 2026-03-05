import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController extends GetxController {
  AuthController({
    required AuthService authService,
    required UserService userService,
  }) : _authService = authService,
       _userService = userService;

  final AuthService _authService;
  final UserService _userService;

  final Rxn<User> user = Rxn<User>();
  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isProfileLoading = false.obs;
  final RxBool isUpdatingPrivacy = false.obs;

  StreamSubscription<User?>? _authSubscription;

  User? get currentUser => user.value;
  String get displayName => userProfile.value?.displayName ?? 'No display name';
  String get email => userProfile.value?.email ?? '';
  String get photoUrl => userProfile.value?.photoUrl ?? '';
  String get username => userProfile.value?.username ?? '';
  String get bio => userProfile.value?.bio ?? '';
  bool get isPrivate => userProfile.value?.isPrivate ?? false;
  int get followersCount => userProfile.value?.followersCount ?? 0;
  int get followingCount => userProfile.value?.followingCount ?? 0;
  String? get uid => user.value?.uid;
  bool get isLoggedIn => user.value != null;

  @override
  void onInit() {
    super.onInit();
    user.value = _authService.currentUser;
    if (user.value != null) {
      unawaited(loadProfile());
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? firebaseUser,
    ) {
      user.value = firebaseUser;
      if (firebaseUser == null) {
        userProfile.value = null;
      } else {
        unawaited(loadProfile());
      }
    });
  }

  Future<void> loginWithGoogle() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      final UserCredential? credential = await _authService.signInWithGoogle();
      final User? firebaseUser = credential?.user;

      if (firebaseUser == null) {
        Get.snackbar('Login canceled', 'Google sign-in was canceled.');
        return;
      }

      await _onLoginSuccess(firebaseUser);
    } on FirebaseAuthException catch (error) {
      Get.snackbar(
        'Login failed',
        error.message ?? 'Unable to authenticate with Google.',
      );
    } catch (_) {
      Get.snackbar('Login failed', 'Unable to authenticate with Google.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isLoading.value) {
      return;
    }

    if (email.trim().isEmpty || password.isEmpty) {
      Get.snackbar('Missing fields', 'Email and password are required.');
      return;
    }

    isLoading.value = true;
    try {
      final UserCredential credential = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        Get.snackbar('Login failed', 'Unable to login with email/password.');
        return;
      }
      await _onLoginSuccess(credential.user!);
    } on FirebaseAuthException catch (error) {
      Get.snackbar(
        'Login failed',
        error.message ?? 'Unable to login with email/password.',
      );
    } catch (_) {
      Get.snackbar('Login failed', 'Unable to login with email/password.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (isLoading.value) {
      return;
    }

    if (email.trim().isEmpty || password.isEmpty) {
      Get.snackbar('Missing fields', 'Email and password are required.');
      return;
    }

    isLoading.value = true;
    try {
      final UserCredential credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        Get.snackbar('Signup failed', 'Unable to create account.');
        return;
      }
      await _onLoginSuccess(credential.user!);
    } on FirebaseAuthException catch (error) {
      Get.snackbar(
        'Signup failed',
        error.message ?? 'Unable to create account.',
      );
    } catch (_) {
      Get.snackbar('Signup failed', 'Unable to create account.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProfile() async {
    final User? firebaseUser = currentUser;
    final String? userId = firebaseUser?.uid;
    if (userId == null || userId.isEmpty) {
      userProfile.value = null;
      return;
    }

    isProfileLoading.value = true;
    try {
      final UserModel? existing = await _userService.getUserProfile(userId);
      userProfile.value =
          existing ?? await _userService.ensureUserProfile(firebaseUser!);
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<UserModel?> loadProfileByUid(String userId) {
    return _userService.getUserProfile(userId);
  }

  Future<void> updatePrivacy(bool isPrivate) async {
    if (isUpdatingPrivacy.value) {
      return;
    }

    isUpdatingPrivacy.value = true;
    try {
      await _userService.updatePrivacy(isPrivate);
      await loadProfile();
    } catch (_) {
      Get.snackbar('Error', 'Failed to update privacy setting.');
    } finally {
      isUpdatingPrivacy.value = false;
    }
  }

  Future<void> logout() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      await _authService.logout();
      user.value = null;
      userProfile.value = null;
      Get.offAllNamed(AppPages.login);
    } catch (_) {
      Get.snackbar('Logout failed', 'Unable to sign out right now.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> _onLoginSuccess(User firebaseUser) async {
    user.value = firebaseUser;
    userProfile.value = await _userService.ensureUserProfile(firebaseUser);
    Get.offAllNamed(AppPages.home);
  }
}
