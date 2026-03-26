import 'dart:async';
import 'dart:io';

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
  final RxBool isUpdatingPhoto = false.obs;

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
      Get.snackbar('Login failed', _authErrorMessage(error));
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
    await _runEmailAuth(
      actionTitle: 'Login failed',
      email: email,
      password: password,
      request: () =>
          _authService.loginWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _runEmailAuth(
      actionTitle: 'Signup failed',
      email: email,
      password: password,
      request: () => _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> loadProfile() async {
    final User? firebaseUser = currentUser;
    if (firebaseUser == null || firebaseUser.uid.isEmpty) {
      userProfile.value = null;
      return;
    }

    isProfileLoading.value = true;
    try {
      userProfile.value = await _userService.ensureUserProfile(firebaseUser);
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

  Future<void> updateBio(String bio) async {
    final String? currentUid = uid;
    if (currentUid == null || currentUid.isEmpty) {
      return;
    }

    isLoading.value = true;
    try {
      await _userService.updateProfile(currentUid, <String, dynamic>{
        'bio': bio,
      });
      await loadProfile();
    } catch (_) {
      Get.snackbar('Error', 'Failed to update bio.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfilePhoto(String filePath) async {
    final User? firebaseUser = currentUser;
    if (firebaseUser == null ||
        filePath.trim().isEmpty ||
        isUpdatingPhoto.value) {
      return;
    }

    isUpdatingPhoto.value = true;
    try {
      userProfile.value = await _userService.updateCurrentUserPhoto(
        firebaseUser: firebaseUser,
        file: File(filePath),
      );
      await firebaseUser.reload();
      user.value = _authService.currentUser;
    } on FirebaseException catch (error) {
      Get.snackbar(
        'Photo update failed',
        error.message ?? 'Unable to update profile image right now.',
      );
    } catch (_) {
      Get.snackbar(
        'Photo update failed',
        'Unable to update profile image right now.',
      );
    } finally {
      isUpdatingPhoto.value = false;
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

  Future<void> _runEmailAuth({
    required String actionTitle,
    required String email,
    required String password,
    required Future<UserCredential> Function() request,
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
      final UserCredential credential = await request();
      final User? signedInUser = _authService.currentUser ?? credential.user;
      if (signedInUser == null) {
        Get.snackbar(actionTitle, 'Unable to continue with email/password.');
        return;
      }

      await _onLoginSuccess(signedInUser);
    } on FirebaseAuthException catch (error) {
      Get.snackbar(actionTitle, _authErrorMessage(error));
    } catch (_) {
      Get.snackbar(actionTitle, 'Unable to continue with email/password.');
    } finally {
      isLoading.value = false;
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'email-already-in-use' => 'This email is already in use.',
      'user-not-found' => 'No account was found for this email.',
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => error.message ?? 'Unable to continue right now.',
    };
  }
}
