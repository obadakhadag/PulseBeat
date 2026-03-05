import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/follow_controller.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthController _authController = Get.find<AuthController>();
  final FollowController _followController = Get.find<FollowController>();

  late final String? _uid = _resolveUid();

  String? _resolveUid() {
    final dynamic args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      return args.trim();
    }
    if (args is Map<String, dynamic>) {
      final dynamic uidValue = args['uid'];
      if (uidValue is String && uidValue.trim().isNotEmpty) {
        return uidValue.trim();
      }
    }
    final String? param = Get.parameters['uid'];
    if (param != null && param.trim().isNotEmpty) {
      return param.trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final String? uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      _followController.loadFollowStatus(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('User not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
        title: const Text('User Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final Map<String, dynamic> data = Map<String, dynamic>.from(
            snapshot.data!.data() ?? <String, dynamic>{},
          );
          final String displayName =
              (data['displayName'] as String?)?.trim().isNotEmpty == true
              ? (data['displayName'] as String).trim()
              : 'No display name';
          final String username =
              (data['username'] as String?)?.trim().isNotEmpty == true
              ? (data['username'] as String).trim()
              : 'unknown';
          final String photoUrl = (data['photoUrl'] as String?) ?? '';
          final String bio = (data['bio'] as String?)?.trim() ?? '';
          final int followersCount =
              (data['followersCount'] as num?)?.toInt() ?? 0;
          final int followingCount =
              (data['followingCount'] as num?)?.toInt() ?? 0;
          final bool isOwnProfile = _authController.uid == uid;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 54,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 46)
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '@$username',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (!isOwnProfile) ...<Widget>[
                const SizedBox(height: 14),
                Obx(() {
                  final String status = _followController.statusFor(uid);
                  final bool disabled =
                      _followController.isSending.value ||
                      status == 'requested' ||
                      status == 'following';
                  final String label = status == 'following'
                      ? 'Following'
                      : status == 'requested'
                      ? 'Requested'
                      : 'Follow';

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: disabled
                          ? null
                          : () => _followController.followUser(uid),
                      child: Text(label),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CounterCard(
                      label: 'Followers',
                      value: followersCount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterCard(
                      label: 'Following',
                      value: followingCount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Bio',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  bio.isEmpty ? 'No bio yet' : bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
