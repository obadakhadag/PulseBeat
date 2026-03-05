import 'package:get/get.dart';

import '../services/follow_service.dart';
import 'auth_controller.dart';

class FollowController extends GetxController {
  FollowController({required FollowService followService})
    : _followService = followService;

  final FollowService _followService;

  final RxBool isSending = false.obs;
  final RxMap<String, String> _statusByUid = <String, String>{}.obs;

  String statusFor(String toUid) => _statusByUid[toUid.trim()] ?? 'follow';

  Future<void> loadFollowStatus(String toUid) async {
    final String targetUid = toUid.trim();
    if (targetUid.isEmpty) {
      return;
    }

    try {
      _statusByUid[targetUid] = await _followService.getFollowStatus(
        toUid: targetUid,
      );
    } catch (_) {
      _statusByUid[targetUid] = 'follow';
    }
  }

  Future<void> followUser(String toUid) async {
    final String targetUid = toUid.trim();
    final String? fromUid = Get.find<AuthController>().uid;

    if (targetUid.isEmpty) {
      return;
    }

    if (fromUid == null || fromUid.isEmpty) {
      Get.snackbar('Error', 'You must be logged in to send a request.');
      return;
    }

    if (fromUid == targetUid) {
      return;
    }

    if (isSending.value) {
      return;
    }

    final String currentStatus = statusFor(targetUid);
    if (currentStatus == 'following' || currentStatus == 'requested') {
      return;
    }

    isSending.value = true;
    try {
      await _followService.sendFollowRequest(toUid: targetUid);
      _statusByUid[targetUid] = 'requested';
      Get.snackbar('Success', 'Follow request sent.');
    } catch (_) {
      Get.snackbar('Error', 'Failed to send follow request.');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> requestFollow(String toUid) => followUser(toUid);
}
