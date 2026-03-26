import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/search_controller.dart' as app_search;
import '../models/user_model.dart';
import '../routes/app_pages.dart';
import '../widgets/app_user_avatar.dart';
import '../widgets/music_page_background.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final app_search.SearchController _searchController =
      Get.find<app_search.SearchController>();
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MusicPageBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search'.tr,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: TextField(
                  controller: _queryController,
                  onChanged: _searchController.searchUsers,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search users...'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_searchController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<UserModel> users = _searchController.results;
                  final String query = _queryController.text.trim();
                  if (query.length < 2) {
                    return _SearchStateCard(
                      icon: Icons.person_search_rounded,
                      title: 'Find people'.tr,
                      message:
                          'Type at least 2 characters to search for users.'.tr,
                    );
                  }
                  if (users.isEmpty) {
                    return _SearchStateCard(
                      icon: Icons.search_off_rounded,
                      title: 'No users found'.tr,
                      message: 'Try a different username or display name.'.tr,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: users.length,
                    itemBuilder: (BuildContext context, int index) {
                      final UserModel user = users[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: AppUserAvatar(
                              photoUrl: user.photoUrl,
                              radius: 26,
                            ),
                            title: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName
                                  : 'No display name'.tr,
                            ),
                            subtitle: Text(
                              user.username.isNotEmpty
                                  ? '@${user.username}'
                                  : '@unknown',
                            ),
                            trailing: FilledButton(
                              onPressed: () => Get.toNamed(
                                AppPages.userProfile,
                                arguments: user.uid,
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded),
                            ),
                            onTap: () => Get.toNamed(
                              AppPages.userProfile,
                              arguments: user.uid,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchStateCard extends StatelessWidget {
  const _SearchStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 40),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
