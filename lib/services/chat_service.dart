import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String buildParticipantKey(String a, String b) {
    final List<String> sorted = <String>[a.trim(), b.trim()]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> getOrCreateDirectChat({
    required String currentUid,
    required String otherUid,
  }) async {
    final String trimmedCurrentUid = currentUid.trim();
    final String trimmedOtherUid = otherUid.trim();

    if (trimmedCurrentUid.isEmpty || trimmedOtherUid.isEmpty) {
      throw ArgumentError('Both user ids are required.');
    }

    if (trimmedCurrentUid == trimmedOtherUid) {
      throw ArgumentError('Direct chat requires two different users.');
    }

    final String participantKey = buildParticipantKey(
      trimmedCurrentUid,
      trimmedOtherUid,
    );

    final QuerySnapshot<Map<String, dynamic>> existingChats = await _firestore
        .collection('chats')
        .where('participantKey', isEqualTo: participantKey)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    final List<String> participants = <String>[
      trimmedCurrentUid,
      trimmedOtherUid,
    ]..sort();

    final DocumentReference<Map<String, dynamic>> chatRef = _firestore
        .collection('chats')
        .doc();

    await chatRef.set(<String, dynamic>{
      'participants': participants,
      'participantKey': participantKey,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': null,
    });

    return chatRef.id;
  }
}
