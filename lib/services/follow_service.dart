import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

class FollowService {
  FollowService({
    required AuthService authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  Future<String> getFollowStatus({required String toUid}) async {
    final String targetUid = toUid.trim();
    final String? fromUid = _authService.currentUser?.uid;

    if (fromUid == null || fromUid.isEmpty || targetUid.isEmpty) {
      return 'follow';
    }

    if (fromUid == targetUid) {
      return 'following';
    }

    final String docId = '${fromUid}_$targetUid';
    final DocumentSnapshot<Map<String, dynamic>> followerSnapshot =
        await _firestore.collection('followers').doc(docId).get();
    if (followerSnapshot.exists) {
      return 'following';
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('follow_requests')
        .doc(docId)
        .get();

    if (!snapshot.exists) {
      return 'follow';
    }

    final String status =
        (snapshot.data()?['status'] as String?)?.toLowerCase() ?? '';
    if (status == 'pending') {
      return 'requested';
    }

    return 'follow';
  }

  Future<String> followUser({required String toUid}) async {
    final String targetUid = toUid.trim();
    final String? fromUid = _authService.currentUser?.uid;

    if (fromUid == null || fromUid.isEmpty || targetUid.isEmpty) {
      return 'follow';
    }

    if (fromUid == targetUid) {
      return 'following';
    }

    final String docId = '${fromUid}_$targetUid';
    final DocumentReference<Map<String, dynamic>> requestRef = _firestore
        .collection('follow_requests')
        .doc(docId);
    final DocumentReference<Map<String, dynamic>> followerRef = _firestore
        .collection('followers')
        .doc(docId);
    final DocumentReference<Map<String, dynamic>> targetUserRef = _firestore
        .collection('users')
        .doc(targetUid);
    final DocumentReference<Map<String, dynamic>> currentUserRef = _firestore
        .collection('users')
        .doc(fromUid);

    String status = 'follow';

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> followerSnapshot =
          await transaction.get(followerRef);
      if (followerSnapshot.exists) {
        status = 'following';
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> targetUserSnapshot =
          await transaction.get(targetUserRef);
      if (!targetUserSnapshot.exists) {
        status = 'follow';
        return;
      }

      final bool isPrivate = targetUserSnapshot.data()?['isPrivate'] == true;
      if (isPrivate) {
        await _upsertFollowRequest(
          transaction: transaction,
          requestRef: requestRef,
          fromUid: fromUid,
          targetUid: targetUid,
        );
        status = 'requested';
        return;
      }

      transaction.set(followerRef, <String, dynamic>{
        'followerUid': fromUid,
        'followingUid': targetUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(targetUserRef, <String, dynamic>{
        'followersCount': FieldValue.increment(1),
      });
      transaction.update(currentUserRef, <String, dynamic>{
        'followingCount': FieldValue.increment(1),
      });
      transaction.delete(requestRef);
      status = 'following';
    });

    return status;
  }

  Future<void> sendFollowRequest({required String toUid}) async {
    final String targetUid = toUid.trim();
    final String? fromUid = _authService.currentUser?.uid;

    if (fromUid == null || fromUid.isEmpty || targetUid.isEmpty) {
      return;
    }

    if (fromUid == targetUid) {
      return;
    }

    final String docId = '${fromUid}_$targetUid';
    final DocumentReference<Map<String, dynamic>> requestRef = _firestore
        .collection('follow_requests')
        .doc(docId);

    await _firestore.runTransaction((transaction) async {
      await _upsertFollowRequest(
        transaction: transaction,
        requestRef: requestRef,
        fromUid: fromUid,
        targetUid: targetUid,
      );
    });
  }

  Future<void> unfollowUser({required String toUid}) async {
    final String targetUid = toUid.trim();
    final String? fromUid = _authService.currentUser?.uid;

    if (fromUid == null || fromUid.isEmpty || targetUid.isEmpty) {
      return;
    }

    if (fromUid == targetUid) {
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('followers')
        .where('followerUid', isEqualTo: fromUid)
        .where('followingUid', isEqualTo: targetUid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final WriteBatch batch = _firestore.batch();
      batch.delete(snapshot.docs.first.reference);
      batch.update(
        _firestore.collection('users').doc(targetUid),
        <String, dynamic>{'followersCount': FieldValue.increment(-1)},
      );
      batch.update(
        _firestore.collection('users').doc(fromUid),
        <String, dynamic>{'followingCount': FieldValue.increment(-1)},
      );
      await batch.commit();
      return;
    }

    final DocumentReference<Map<String, dynamic>> directFollowerRef = _firestore
        .collection('followers')
        .doc('${fromUid}_$targetUid');
    final DocumentSnapshot<Map<String, dynamic>> directSnapshot =
        await directFollowerRef.get();
    if (!directSnapshot.exists) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> txSnapshot =
          await transaction.get(directFollowerRef);
      if (!txSnapshot.exists) {
        return;
      }

      transaction.delete(directFollowerRef);
      transaction.update(
        _firestore.collection('users').doc(targetUid),
        <String, dynamic>{'followersCount': FieldValue.increment(-1)},
      );
      transaction.update(
        _firestore.collection('users').doc(fromUid),
        <String, dynamic>{'followingCount': FieldValue.increment(-1)},
      );
    });
  }

  Future<void> _upsertFollowRequest({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> requestRef,
    required String fromUid,
    required String targetUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
        .get(requestRef);

    if (!snapshot.exists) {
      transaction.set(requestRef, <String, dynamic>{
        'fromUid': fromUid,
        'toUid': targetUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final String status =
        (snapshot.data()?['status'] as String?)?.toLowerCase() ?? '';
    if (status == 'pending') {
      transaction.update(requestRef, <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.update(requestRef, <String, dynamic>{
      'fromUid': fromUid,
      'toUid': targetUid,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
