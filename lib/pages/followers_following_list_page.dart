import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

    final Query<Map<String, dynamic>> query = isFollowersMode
        ? firestore
              .collection('followers')
              .where('followingUid', isEqualTo: profileUid)
        : firestore
              .collection('followers')
              .where('followerUid', isEqualTo: profileUid);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return Center(child: Text('No $title yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final Map<String, dynamic> relationshipData = docs[index].data();
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

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestore
                    .collection('users')
                    .doc(trimmedUid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  final Map<String, dynamic> userData =
                      Map<String, dynamic>.from(
                        userSnapshot.data?.data() ?? <String, dynamic>{},
                      );
                  final String displayName =
                      (userData['displayName'] as String?)?.trim().isNotEmpty ==
                          true
                      ? (userData['displayName'] as String).trim()
                      : 'Unknown User';
                  final String username =
                      (userData['username'] as String?)?.trim().isNotEmpty ==
                          true
                      ? (userData['username'] as String).trim()
                      : 'unknown';
                  final String photoUrl =
                      (userData['photoUrl'] as String?) ?? '';

                  return ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfilePage(uid: trimmedUid),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: Theme.of(context).cardColor,
                    leading: CircleAvatar(
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person_rounded)
                          : null,
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
