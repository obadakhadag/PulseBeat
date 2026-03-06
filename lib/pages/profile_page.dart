import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'followers_following_list_page.dart';
import '../routes/app_pages.dart';

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
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bio'),
          content: TextField(
            controller: bioController,
            maxLength: 160,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write your bio'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(bioController.text.trim()),
              child: const Text('Save'),
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
      Get.snackbar('Error', 'Failed to update bio.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Profile not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            onPressed: () => Get.toNamed(AppPages.search),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
          Obx(() {
            return IconButton(
              onPressed: controller.isLoading.value ? null : controller.logout,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            );
          }),
        ],
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
            return const Center(child: Text('Profile not found.'));
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
          final String email = (data['email'] as String?) ?? '';
          final String photoUrl = (data['photoUrl'] as String?) ?? '';
          final String bio = (data['bio'] as String?)?.trim() ?? '';
          final int followersCount =
              (data['followersCount'] as num?)?.toInt() ?? 0;
          final int followingCount =
              (data['followingCount'] as num?)?.toInt() ?? 0;
          final bool isPrivate = data['isPrivate'] == true;

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
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Private Account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch.adaptive(
                    value: isPrivate,
                    onChanged: (value) async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update(<String, dynamic>{'isPrivate': value});
                      } catch (_) {
                        Get.snackbar(
                          'Error',
                          'Failed to update privacy setting.',
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CounterCard(
                      label: 'Followers',
                      value: followersCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => FollowersListPage(profileUid: uid),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterCard(
                      label: 'Following',
                      value: followingCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => FollowingListPage(profileUid: uid),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Text(
                    'Bio',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _editBio(context, uid, bio),
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit bio',
                  ),
                ],
              ),
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
  const _CounterCard({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
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

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: content,
    );
  }
}
