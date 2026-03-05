import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserProfile(User firebaseUser) async {
    final String email = firebaseUser.email ?? '';
    final String username = _usernameFromEmail(
      email: email,
      uid: firebaseUser.uid,
    );

    final UserModel userModel = UserModel(
      uid: firebaseUser.uid,
      email: email,
      username: username,
      displayName: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : username,
      photoUrl: firebaseUser.photoURL ?? '',
      bio: '',
      isPrivate: false,
      followersCount: 0,
      followingCount: 0,
      createdAt: null,
      lastLogin: null,
    );

    await _usersCollection.doc(firebaseUser.uid).set(<String, dynamic>{
      ...userModel.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _usersCollection.doc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);
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
    return _usersCollection.doc(uid).update(data);
  }

  Future<void> updatePrivacy(bool isPrivate) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No logged-in user found.');
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).update(
      <String, dynamic>{'isPrivate': isPrivate},
    );
  }

  Future<UserModel> ensureUserProfile(User firebaseUser) async {
    final DocumentReference<Map<String, dynamic>> userRef = _usersCollection
        .doc(firebaseUser.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();

    if (!snapshot.exists) {
      await createUserProfile(firebaseUser);
    } else {
      await userRef.update(<String, dynamic>{
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    final UserModel? profile = await getUserProfile(firebaseUser.uid);
    if (profile != null) {
      return profile;
    }

    throw StateError('Unable to load user profile after login.');
  }

  String _usernameFromEmail({required String email, required String uid}) {
    final String raw = email.split('@').first.toLowerCase();
    final String sanitized = raw.replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    if (sanitized.isNotEmpty) {
      return sanitized;
    }
    return 'user_${uid.substring(0, 6)}';
  }
}
