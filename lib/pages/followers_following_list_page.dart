import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_user_avatar.dart';
import '../widgets/music_page_background.dart';
import 'user_profile_page.dart';

class FollowersListPage extends StatelessWidget {
  const FollowersListPage({super.key, required this.profileUid});

  final String profileUid;

  @override
  Widget build(BuildContext context) {
    return _FollowListPage(
      profileUid: profileUid,
      mode: _FollowListMode.followers,
    );
  }
}

class FollowingListPage extends StatelessWidget {
  const FollowingListPage({super.key, required this.profileUid});

  final String profileUid;

  @override
  Widget build(BuildContext context) {
    return _FollowListPage(
      profileUid: profileUid,
      mode: _FollowListMode.following,
    );
  }
}

enum _FollowListMode { followers, following }

class _FollowListPage extends StatelessWidget {
  const _FollowListPage({required this.profileUid, required this.mode});

  final String profileUid;
  final _FollowListMode mode;

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final bool isFollowersMode = mode == _FollowListMode.followers;
    final String title = isFollowersMode ? 'Followers' : 'Following';
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final Query<Map<String, dynamic>> query = isFollowersMode
        ? firestore
              .collection('followers')
              .where('followingUid', isEqualTo: profileUid)
        : firestore
              .collection('followers')
              .where('followerUid', isEqualTo: profileUid);

    return Scaffold(
      body: MusicPageBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: firestore
                      .collection('users')
                      .doc(profileUid)
                      .snapshots(),
                  builder: (BuildContext context, profileSnapshot) {
                    final bool isOwnProfile =
                        currentUserUid.trim().isNotEmpty &&
                        currentUserUid.trim() == profileUid.trim();
                    if (!isOwnProfile &&
                        profileSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final Map<String, dynamic> profileData =
                        Map<String, dynamic>.from(
                          profileSnapshot.data?.data() ?? <String, dynamic>{},
                        );
                    final bool showFollowingList =
                        (profileData['showFollowingList'] as bool?) ?? true;

                    if (!isOwnProfile && !showFollowingList) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('$title list is hidden.'),
                            ),
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: query.snapshots(),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        docs =
                            snapshot.data?.docs ??
                            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            child: Card(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text('No $title yet.'),
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final Map<String, dynamic> relationshipData =
                                docs[index].data();
                            final String relatedUid =
                                (isFollowersMode
                                        ? relationshipData['followerUid']
                                        : relationshipData['followingUid'])
                                    as String? ??
                                '';
                            final String trimmedUid = relatedUid.trim();
                            if (trimmedUid.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: firestore
                                  .collection('users')
                                  .doc(trimmedUid)
                                  .snapshots(),
                              builder: (BuildContext context, userSnapshot) {
                                final Map<String, dynamic> userData =
                                    Map<String, dynamic>.from(
                                      userSnapshot.data?.data() ??
                                          <String, dynamic>{},
                                    );
                                final String displayName =
                                    (userData['displayName'] as String?)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? (userData['displayName'] as String).trim()
                                    : 'Unknown User';
                                final String username =
                                    (userData['username'] as String?)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? (userData['username'] as String).trim()
                                    : 'unknown';
                                final String photoUrl =
                                    (userData['photoUrl'] as String?) ?? '';

                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            UserProfilePage(uid: trimmedUid),
                                      ),
                                    ),
                                    leading: AppUserAvatar(
                                      photoUrl: photoUrl,
                                      radius: 26,
                                    ),
                                    title: Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '@$username',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
