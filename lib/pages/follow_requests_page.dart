import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/music_page_background.dart';
import 'user_profile_page.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _processingRequestIds = <String>{};

  String? get _currentUserUid => FirebaseAuth.instance.currentUser?.uid;

  void _openUserProfile(String uid) {
    final String trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      return;
    }

    Get.to<void>(() => UserProfilePage(uid: trimmedUid));
  }

  Future<void> _acceptRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    if (_processingRequestIds.contains(requestId)) {
      return;
    }

    setState(() => _processingRequestIds.add(requestId));

    try {
      await _firestore.runTransaction((transaction) async {
        final DocumentReference<Map<String, dynamic>> requestRef = _firestore
            .collection('follow_requests')
            .doc(requestId);
        final DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          return;
        }

        final String status =
            (requestSnapshot.data()?['status'] as String?)?.toLowerCase() ?? '';
        if (status != 'pending') {
          return;
        }

        transaction.update(requestRef, <String, dynamic>{
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final DocumentReference<Map<String, dynamic>> followerRef = _firestore
            .collection('followers')
            .doc('${fromUid}_$toUid');
        transaction.set(followerRef, <String, dynamic>{
          'followerUid': fromUid,
          'followingUid': toUid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(
          _firestore.collection('users').doc(toUid),
          <String, dynamic>{'followersCount': FieldValue.increment(1)},
        );
        transaction.update(
          _firestore.collection('users').doc(fromUid),
          <String, dynamic>{'followingCount': FieldValue.increment(1)},
        );
      });

      Get.snackbar('Success'.tr, 'Follow request accepted.'.tr);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to accept follow request.'.tr);
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(requestId));
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    if (_processingRequestIds.contains(requestId)) {
      return;
    }

    setState(() => _processingRequestIds.add(requestId));

    try {
      await _firestore.collection('follow_requests').doc(requestId).delete();
      Get.snackbar('Done'.tr, 'Follow request declined.'.tr);
    } catch (_) {
      Get.snackbar('Error'.tr, 'Failed to decline follow request.'.tr);
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(requestId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = _currentUserUid;
    if (currentUserUid == null || currentUserUid.isEmpty) {
      return Scaffold(
        body: MusicPageBackground(
          child: SafeArea(
            child: Center(child: Text('You must be logged in.'.tr)),
          ),
        ),
      );
    }

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
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Follow Requests'.tr,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('follow_requests')
                      .where('toUid', isEqualTo: currentUserUid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    docs =
                        snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No pending requests.'.tr,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final QueryDocumentSnapshot<Map<String, dynamic>>
                        request = docs[index];
                        final Map<String, dynamic> data = request.data();
                        final String fromUid =
                            (data['fromUid'] as String?)?.trim() ?? '';
                        final String toUid =
                            (data['toUid'] as String?)?.trim() ?? '';
                        if (fromUid.isEmpty || toUid.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final bool isProcessing = _processingRequestIds
                            .contains(request.id);

                        return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>
                        >(
                          future: _firestore
                              .collection('users')
                              .doc(fromUid)
                              .get(),
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
                                : 'Unknown User'.tr;
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
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () => _openUserProfile(fromUid),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundImage: photoUrl.isNotEmpty
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl.isEmpty
                                            ? const Icon(Icons.person_rounded)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _openUserProfile(fromUid),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '@$username',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: 0.60,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _declineRequest(request.id),
                                      child: Text('Decline'.tr),
                                    ),
                                    const SizedBox(width: 4),
                                    FilledButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _acceptRequest(
                                              requestId: request.id,
                                              fromUid: fromUid,
                                              toUid: toUid,
                                            ),
                                      child: Text('Accept'.tr),
                                    ),
                                  ],
                                ),
                              ),
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
