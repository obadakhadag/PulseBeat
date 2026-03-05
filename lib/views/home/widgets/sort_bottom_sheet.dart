import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Library options',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how songs are ordered and grouped.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sort',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...LibrarySort.values.map(
                  (LibrarySort value) => Obx(
                    () => ListTile(
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(value.name.capitalizeFirst ?? value.name),
                      trailing: controller.sort.value == value
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => controller.setSort(value),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Group',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...LibraryGroup.values.map(
                  (LibraryGroup value) => Obx(
                    () => ListTile(
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(switch (value) {
                        LibraryGroup.folder => 'Folder',
                        LibraryGroup.titleLanguage => 'Title language',
                        LibraryGroup.artist => 'Artist',
                      }),
                      subtitle: Text(switch (value) {
                        LibraryGroup.folder =>
                          'Show songs under device folders.',
                        LibraryGroup.titleLanguage =>
                          'Split songs into Arabic, English, and other titles.',
                        LibraryGroup.artist => 'Show songs under artist names.',
                      }),
                      trailing: controller.group.value == value
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () {
                        controller.setGroup(value);
                        Get.back<void>();
                      },
                    ),
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
