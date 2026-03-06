import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null || currentUserUid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (chatDocs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chatDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final QueryDocumentSnapshot<Map<String, dynamic>> chatDoc =
                  chatDocs[index];
              final Map<String, dynamic> chatData = chatDoc.data();

              final List<String> participants =
                  ((chatData['participants'] as List<dynamic>?)
                      ?.whereType<String>()
                      .map((uid) => uid.trim())
                      .where((uid) => uid.isNotEmpty)
                      .toList()) ??
                  <String>[];

              final String otherUid = participants.firstWhere(
                (uid) => uid != currentUserUid,
                orElse: () => '',
              );
              if (otherUid.isEmpty) {
                return const SizedBox.shrink();
              }

              final String rawLastMessage =
                  (chatData['lastMessage'] as String?)?.trim() ?? '';
              final String lastMessage = rawLastMessage.isEmpty
                  ? 'No messages yet'
                  : rawLastMessage;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
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
                        builder: (_) =>
                            ChatPage(chatId: chatDoc.id, otherUid: otherUid),
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
                      '$lastMessage\n@$username',
                      maxLines: 2,
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
