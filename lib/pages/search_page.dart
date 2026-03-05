import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/search_controller.dart' as app_search;
import '../models/user_model.dart';
import '../routes/app_pages.dart';

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
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _queryController,
                onChanged: _searchController.searchUsers,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                  return const Center(
                    child: Text('Type at least 2 characters to search.'),
                  );
                }
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
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
                      onTap: () => Get.toNamed(
                        AppPages.userProfile,
                        arguments: user.uid,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
