import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/utils/library_identity.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile(User firebaseUser) async {
    await ensureUserProfile(firebaseUser);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _usersCollection.doc(uid).get();
    final Map<String, dynamic>? rawData = snapshot.data();

    if (!snapshot.exists || rawData == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(rawData);
    data['uid'] = data['uid'] ?? snapshot.id;
    return UserModel.fromMap(data);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final String normalized = query.trim();
    if (normalized.isEmpty) {
      return const <UserModel>[];
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .orderBy('username')
        .startAt(<String>[normalized])
        .endAt(<String>['$normalized\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['uid'] = data['uid'] ?? doc.id;
          return UserModel.fromMap(data);
        })
        .toList(growable: false);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _usersCollection.doc(uid).set(<String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePrivacy(bool isPrivate) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No logged-in user found.');
    }

    await updateProfile(uid, <String, dynamic>{'isPrivate': isPrivate});
  }

  Future<void> syncUserLibrary({
    required String uid,
    required Iterable<String> libraryIds,
  }) {
    final List<String> normalizedIds =
        libraryIds
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort((String a, String b) => a.compareTo(b));

    return updateProfile(uid, <String, dynamic>{'userLibrary': normalizedIds});
  }

  Future<LibrarySimilarityResult> loadLibrarySimilarity({
    required String currentUid,
    required String targetUid,
    required Iterable<String> currentLibraryIds,
  }) async {
    final String normalizedTargetUid = targetUid.trim();
    final String normalizedCurrentUid = currentUid.trim();

    if (normalizedTargetUid.isEmpty) {
      return calculateLibrarySimilarity(
        currentIds: currentLibraryIds,
        targetIds: const <String>[],
      );
    }

    if (normalizedCurrentUid == normalizedTargetUid &&
        normalizedCurrentUid.isNotEmpty) {
      return calculateLibrarySimilarity(
        currentIds: currentLibraryIds,
        targetIds: currentLibraryIds,
      );
    }

    final UserModel? targetProfile = await getUserProfile(normalizedTargetUid);
    return calculateLibrarySimilarity(
      currentIds: currentLibraryIds,
      targetIds: targetProfile?.librarySongIds ?? const <String>[],
    );
  }

  Future<UserModel> ensureUserProfile(User firebaseUser) async {
    final DocumentReference<Map<String, dynamic>> userRef = _usersCollection
        .doc(firebaseUser.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();
    final Map<String, dynamic>? rawData = snapshot.data();
    final UserModel? existingProfile = rawData == null
        ? null
        : UserModel.fromMap(<String, dynamic>{
            ...rawData,
            'uid': rawData['uid'] ?? snapshot.id,
          });

    await userRef.set(
      _buildUserProfileDocument(firebaseUser, existingProfile: existingProfile),
      SetOptions(merge: true),
    );

    final UserModel? profile = await getUserProfile(firebaseUser.uid);
    if (profile != null) {
      return profile;
    }

    throw StateError('Unable to load user profile after login.');
  }

  Future<UserModel> updateCurrentUserPhoto({
    required User firebaseUser,
    required File file,
  }) async {
    final String extension = _extensionFromPath(file.path);
    final String objectName =
        '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final Reference reference = _storage
        .ref()
        .child(AppConstants.profileImagesFolder)
        .child(firebaseUser.uid)
        .child(objectName);

    await reference.putFile(
      file,
      SettableMetadata(contentType: _contentTypeForExtension(extension)),
    );

    final String downloadUrl = await reference.getDownloadURL();
    await updateProfile(firebaseUser.uid, <String, dynamic>{
      'photoUrl': downloadUrl,
    });

    await firebaseUser.updatePhotoURL(downloadUrl);
    return ensureUserProfile(firebaseUser);
  }

  Map<String, dynamic> _buildUserProfileDocument(
    User firebaseUser, {
    UserModel? existingProfile,
  }) {
    final String email = (firebaseUser.email ?? existingProfile?.email ?? '')
        .trim();
    final String username = _resolvedUsername(
      email: email,
      uid: firebaseUser.uid,
      existingUsername: existingProfile?.username,
    );
    final String displayName = _resolvedDisplayName(
      firebaseUser: firebaseUser,
      username: username,
      existingDisplayName: existingProfile?.displayName,
    );

    return <String, dynamic>{
      'uid': firebaseUser.uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': _resolvedPhotoUrl(
        firebaseUser,
        existingProfile: existingProfile,
      ),
      'authProvider': _resolvedAuthProvider(firebaseUser, existingProfile),
      'bio': existingProfile?.bio ?? '',
      'isPrivate': existingProfile?.isPrivate ?? false,
      'followersCount': existingProfile?.followersCount ?? 0,
      'followingCount': existingProfile?.followingCount ?? 0,
      'createdAt': existingProfile?.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  String _resolvedUsername({
    required String email,
    required String uid,
    String? existingUsername,
  }) {
    final String trimmedExisting = existingUsername?.trim() ?? '';
    if (trimmedExisting.isNotEmpty) {
      return trimmedExisting;
    }
    return _usernameFromEmail(email: email, uid: uid);
  }

  String _resolvedDisplayName({
    required User firebaseUser,
    required String username,
    String? existingDisplayName,
  }) {
    final String trimmedExisting = existingDisplayName?.trim() ?? '';
    if (trimmedExisting.isNotEmpty) {
      return trimmedExisting;
    }

    final String trimmedFirebaseName = firebaseUser.displayName?.trim() ?? '';
    if (trimmedFirebaseName.isNotEmpty) {
      return trimmedFirebaseName;
    }

    return username;
  }

  String _resolvedPhotoUrl(User firebaseUser, {UserModel? existingProfile}) {
    final String trimmedExisting = existingProfile?.photoUrl.trim() ?? '';
    if (trimmedExisting.isNotEmpty) {
      return trimmedExisting;
    }

    final String trimmedFirebasePhoto = firebaseUser.photoURL?.trim() ?? '';
    if (trimmedFirebasePhoto.isNotEmpty) {
      return trimmedFirebasePhoto;
    }

    return AppConstants.defaultAvatarAsset;
  }

  String _resolvedAuthProvider(User firebaseUser, UserModel? existingProfile) {
    final String explicitProvider = firebaseUser.providerData
        .map((UserInfo item) => item.providerId.trim())
        .firstWhere(
          (String item) => item.isNotEmpty && item != 'firebase',
          orElse: () => '',
        );
    if (explicitProvider.isNotEmpty) {
      return explicitProvider;
    }

    final String existingProvider = existingProfile?.authProvider.trim() ?? '';
    if (existingProvider.isNotEmpty) {
      return existingProvider;
    }

    return 'unknown';
  }

  String _usernameFromEmail({required String email, required String uid}) {
    final String raw = email.split('@').first.toLowerCase();
    final String sanitized = raw.replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    if (sanitized.isNotEmpty) {
      return sanitized;
    }
    return 'user_${uid.substring(0, 6)}';
  }

  String _extensionFromPath(String path) {
    final int dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return 'jpg';
    }

    final String extension = path.substring(dotIndex + 1).toLowerCase();
    if (extension == 'png' ||
        extension == 'webp' ||
        extension == 'jpg' ||
        extension == 'jpeg') {
      return extension == 'jpeg' ? 'jpg' : extension;
    }
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
