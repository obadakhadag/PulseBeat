import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/search_controller.dart' as app_search;
import '../models/user_model.dart';
import '../routes/app_pages.dart';
import '../widgets/floating_music_nav_bar.dart';
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
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MusicPageBackground(
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Search',
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
                        decoration: const InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (_searchController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<UserModel> users = _searchController.results;
                        final String query = _queryController.text.trim();
                        if (query.length < 2) {
                          return _SearchStateCard(
                            icon: Icons.person_search_rounded,
                            title: 'Find people',
                            message:
                                'Type at least 2 characters to search for users.',
                          );
                        }
                        if (users.isEmpty) {
                          return _SearchStateCard(
                            icon: Icons.search_off_rounded,
                            title: 'No users found',
                            message:
                                'Try a different username or display name.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
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
                                  leading: CircleAvatar(
                                    radius: 26,
                                    backgroundImage: user.photoUrl.isNotEmpty
                                        ? NetworkImage(user.photoUrl)
                                        : null,
                                    child: user.photoUrl.isEmpty
                                        ? const Icon(Icons.person_rounded)
                                        : null,
                                  ),
                                  title: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName
                                        : 'No display name',
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
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
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
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FloatingMusicNavBar(currentRoute: AppPages.search),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
