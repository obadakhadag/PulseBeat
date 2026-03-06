import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import '../services/chat_service.dart';

class ChatController extends GetxController {
  ChatController({required ChatService chatService})
    : _chatService = chatService;

  final ChatService _chatService;

  final RxBool isOpeningChat = false.obs;

  Future<void> openDirectChat({
    required String otherUid,
    required String otherDisplayName,
    required String otherUsername,
    String? otherPhotoUrl,
  }) async {
    final String targetUid = otherUid.trim();
    if (targetUid.isEmpty) {
      return;
    }

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) {
      Get.snackbar('Error', 'You must be logged in to open chat.');
      return;
    }

    if (currentUid == targetUid || isOpeningChat.value) {
      return;
    }

    isOpeningChat.value = true;
    try {
      final String chatId = await _chatService.getOrCreateDirectChat(
        currentUid: currentUid,
        otherUid: targetUid,
      );

      await Get.toNamed(
        AppPages.chat,
        arguments: <String, dynamic>{
          'chatId': chatId,
          'otherUid': targetUid,
          'otherDisplayName': otherDisplayName.trim(),
          'otherUsername': otherUsername.trim(),
          'otherPhotoUrl': (otherPhotoUrl ?? '').trim(),
        },
      );
    } catch (_) {
      Get.snackbar('Error', 'Failed to open chat.');
    } finally {
      isOpeningChat.value = false;
    }
  }
}
