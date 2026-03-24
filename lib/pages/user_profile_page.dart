import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/follow_controller.dart';
import '../widgets/music_page_background.dart';
import 'followers_following_list_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, this.uid});

  final String? uid;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthController _authController = Get.find<AuthController>();
  final ChatController _chatController = Get.find<ChatController>();
  final FollowController _followController = Get.find<FollowController>();

  late final String? _uid = _resolveUid();

  String? _resolveUid() {
    final String? constructorUid = widget.uid?.trim();
    if (constructorUid != null && constructorUid.isNotEmpty) {
      return constructorUid;
    }

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

  Future<void> _showFollowingMenu(String targetUid) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_remove_rounded),
              title: Text('Unfollow'.tr),
              onTap: () => Navigator.of(context).pop('unfollow'),
            ),
          ),
        );
      },
    );

    if (action == 'unfollow') {
      await _followController.unfollowUser(targetUid);
    }
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
      return Scaffold(body: Center(child: Text('User not found.'.tr)));
    }

    return Scaffold(
      body: MusicPageBackground(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final DocumentSnapshot<Map<String, dynamic>>? document =
                  snapshot.data;
              final Map<String, dynamic>? rawData = document?.data();
              if (document == null || !document.exists || rawData == null) {
                return Center(child: Text('User not found.'.tr));
              }

              final Map<String, dynamic> data = Map<String, dynamic>.from(
                rawData,
              );
              final String displayName =
                  (data['displayName'] as String?)?.trim().isNotEmpty == true
                  ? (data['displayName'] as String).trim()
                  : 'No display name'.tr;
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Get.back<void>(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'User Profile'.tr,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 54,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person_rounded, size: 42)
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '@$username',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.70),
                                ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _CounterCard(
                                  label: 'Followers'.tr,
                                  value: followersCount,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          FollowersListPage(profileUid: uid),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CounterCard(
                                  label: 'Following'.tr,
                                  value: followingCount,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          FollowingListPage(profileUid: uid),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isOwnProfile) ...<Widget>[
                            const SizedBox(height: 16),
                            Obx(() {
                              final String status = _followController.statusFor(
                                uid,
                              );
                              final bool isBusy =
                                  _followController.isSending.value;

                              if (status == 'following') {
                                return SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: isBusy
                                        ? null
                                        : () => _showFollowingMenu(uid),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                    label: Text('Following'.tr),
                                  ),
                                );
                              }

                              if (status == 'requested') {
                                return SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: null,
                                    child: Text('Requested'.tr),
                                  ),
                                );
                              }

                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => _followController.followUser(uid),
                                  child: Text('Follow'.tr),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            Obx(() {
                              final bool isOpeningChat =
                                  _chatController.isOpeningChat.value;

                              return SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: isOpeningChat
                                      ? null
                                      : () => _chatController.openDirectChat(
                                          otherUid: uid,
                                          otherDisplayName: displayName,
                                          otherUsername: username,
                                          otherPhotoUrl: photoUrl,
                                        ),
                                  icon: isOpeningChat
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                        ),
                                  label: Text('Message'.tr),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Bio'.tr,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            bio.isEmpty ? 'No bio yet'.tr : bio,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.70),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: child,
    );
  }
}
