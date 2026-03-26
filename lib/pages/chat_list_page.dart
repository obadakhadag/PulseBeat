import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import '../widgets/app_user_avatar.dart';
import '../widgets/main_section_scaffold.dart';
import '../widgets/music_page_background.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
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
      body: MainSectionScaffold(
        currentRoute: AppPages.chatList,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Chats'.tr,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: currentUserUid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    chats =
                        snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (chats.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No chats yet.'.tr,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        MainSectionScaffold.bodyBottomInset(
                          withMiniPlayer: true,
                        ),
                      ),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final QueryDocumentSnapshot<Map<String, dynamic>>
                        chatDoc = chats[index];
                        final Map<String, dynamic> chatData = chatDoc.data();
                        final List<String> participants =
                            ((chatData['participants'] as List<dynamic>?)
                                ?.whereType<String>()
                                .map((String uid) => uid.trim())
                                .where((String uid) => uid.isNotEmpty)
                                .toList()) ??
                            <String>[];
                        final String otherUid = participants.firstWhere(
                          (String uid) => uid != currentUserUid,
                          orElse: () => '',
                        );
                        if (otherUid.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final String rawLastMessage =
                            (chatData['lastMessage'] as String?)?.trim() ?? '';
                        final String lastMessage = rawLastMessage.isEmpty
                            ? 'No messages yet'.tr
                            : rawLastMessage;

                        return FutureBuilder<
                          DocumentSnapshot<Map<String, dynamic>>
                        >(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(otherUid)
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

                            final Map<String, dynamic> chatArgs =
                                <String, dynamic>{
                                  'chatId': chatDoc.id,
                                  'otherUid': otherUid,
                                  'otherDisplayName': displayName,
                                  'otherUsername': username,
                                  'otherPhotoUrl': photoUrl,
                                };

                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                onTap: () => Get.toNamed(
                                  AppPages.chat,
                                  arguments: chatArgs,
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
                                  '$lastMessage\n@$username',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: FilledButton(
                                  onPressed: () => Get.toNamed(
                                    AppPages.chat,
                                    arguments: chatArgs,
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                  ),
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
