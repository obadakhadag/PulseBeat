import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.authProvider,
    required this.bio,
    required this.isPrivate,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
  });

  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String photoUrl;
  final String authProvider;
  final String bio;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: (map['uid'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      authProvider: (map['authProvider'] as String?) ?? 'unknown',
      bio: (map['bio'] as String?) ?? '',
      isPrivate: (map['isPrivate'] as bool?) ?? false,
      followersCount: (map['followersCount'] as int?) ?? 0,
      followingCount: (map['followingCount'] as int?) ?? 0,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      lastLogin: _toDateTime(map['lastLogin']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'bio': bio,
      'isPrivate': isPrivate,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLogin': lastLogin,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
