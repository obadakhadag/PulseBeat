import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../widgets/music_page_background.dart';
import 'followers_following_list_page.dart';

class ProfilePage extends GetView<AuthController> {
  const ProfilePage({super.key});

  Future<void> _editBio(
    BuildContext context,
    String uid,
    String currentBio,
  ) async {
    final TextEditingController bioController = TextEditingController(
      text: currentBio,
    );

    final String? newBio = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit bio'.tr),
          content: TextField(
            controller: bioController,
            maxLength: 160,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: 'Write your bio'.tr),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(bioController.text.trim()),
              child: Text('Save'.tr),
            ),
          ],
        );
      },
    );

    if (newBio == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(
        <String, dynamic>{'bio': newBio},
      );
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to update bio.'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(body: Center(child: Text('Profile not found.'.tr)));
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
                return Center(child: Text('Profile not found.'.tr));
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
              final String email = (data['email'] as String?) ?? '';
              final String photoUrl = (data['photoUrl'] as String?) ?? '';
              final String bio = (data['bio'] as String?)?.trim() ?? '';
              final int followersCount =
                  (data['followersCount'] as num?)?.toInt() ?? 0;
              final int followingCount =
                  (data['followingCount'] as num?)?.toInt() ?? 0;
              final bool isPrivate = data['isPrivate'] == true;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                          'Profile'.tr,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Obx(
                        () => IconButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.logout,
                          icon: controller.isLoading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.logout_rounded),
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
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.60),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Private account'.tr,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Approve follow requests before others can see your profile.'
                                      .tr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.70),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch.adaptive(
                            value: isPrivate,
                            onChanged: (bool value) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update(<String, dynamic>{
                                      'isPrivate': value,
                                    });
                              } catch (_) {
                                Get.snackbar(
                                  'Error'.tr,
                                  'Failed to update privacy setting.'.tr,
                                );
                              }
                            },
                          ),
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
                          Row(
                            children: <Widget>[
                              Text(
                                'Bio'.tr,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => _editBio(context, uid, bio),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
