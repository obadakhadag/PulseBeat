import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => UserProfilePage(uid: trimmedUid)),
    );
  }

  Future<void> _acceptRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    if (_processingRequestIds.contains(requestId)) {
      return;
    }

    setState(() {
      _processingRequestIds.add(requestId);
    });

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

      Get.snackbar('Success', 'Follow request accepted.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to accept follow request.');
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(requestId);
        });
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    if (_processingRequestIds.contains(requestId)) {
      return;
    }

    setState(() {
      _processingRequestIds.add(requestId);
    });

    try {
      await _firestore.collection('follow_requests').doc(requestId).delete();
      Get.snackbar('Done', 'Follow request declined.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to decline follow request.');
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestIds.remove(requestId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = _currentUserUid;
    if (currentUserUid == null || currentUserUid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Follow Requests')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Follow Requests')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('follow_requests')
            .where('toUid', isEqualTo: currentUserUid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final requestDoc = docs[index];
              final data = requestDoc.data();
              final String fromUid = (data['fromUid'] as String?)?.trim() ?? '';
              final String toUid = (data['toUid'] as String?)?.trim() ?? '';
              if (fromUid.isEmpty || toUid.isEmpty) {
                return const SizedBox.shrink();
              }

              final bool isProcessing = _processingRequestIds.contains(
                requestDoc.id,
              );

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _firestore.collection('users').doc(fromUid).get(),
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

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => _openUserProfile(fromUid),
                          child: CircleAvatar(
                            radius: 24,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => _declineRequest(requestDoc.id),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _acceptRequest(
                                  requestId: requestDoc.id,
                                  fromUid: fromUid,
                                  toUid: toUid,
                                ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
