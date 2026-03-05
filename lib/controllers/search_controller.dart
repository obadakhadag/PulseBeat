import 'dart:async';

import 'package:get/get.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class SearchController extends GetxController {
  SearchController({required UserService userService})
    : _userService = userService;

  final UserService _userService;

  final RxList<UserModel> results = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  Timer? _debounce;
  String _lastQuery = '';

  Future<void> searchUsers(String query) async {
    final String normalized = query.trim();
    _debounce?.cancel();

    if (normalized.length < 2) {
      _lastQuery = normalized;
      results.clear();
      isLoading.value = false;
      return;
    }

    _lastQuery = normalized;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      isLoading.value = true;
      try {
        final users = await _userService.searchUsers(normalized);
        if (_lastQuery == normalized) {
          results.assignAll(users);
        }
      } catch (_) {
        if (_lastQuery == normalized) {
          results.clear();
          Get.snackbar('Search Error', 'Failed to search users.');
        }
      } finally {
        if (_lastQuery == normalized) {
          isLoading.value = false;
        }
      }
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
