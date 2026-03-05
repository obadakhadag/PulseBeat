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
      final snapshot = await transaction.get(requestRef);

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
    });
  }
}
