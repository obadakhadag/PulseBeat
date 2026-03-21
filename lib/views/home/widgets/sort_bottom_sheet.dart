import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    Widget option({
      required String title,
      String? subtitle,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        tileColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected ? const Icon(Icons.check_rounded) : null,
      );
    }

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Library options',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tune the way songs are sorted and grouped without changing your library.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sort',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...LibrarySort.values.map((LibrarySort value) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Obx(
                      () => option(
                        title: value.name.capitalizeFirst ?? value.name,
                        selected: controller.sort.value == value,
                        onTap: () => controller.setSort(value),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Text(
                  'Group',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...LibraryGroup.values.map((LibraryGroup value) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Obx(
                      () => option(
                        title: switch (value) {
                          LibraryGroup.folder => 'Folder',
                          LibraryGroup.titleLanguage => 'Title language',
                          LibraryGroup.artist => 'Artist',
                        },
                        subtitle: switch (value) {
                          LibraryGroup.folder =>
                            'Show songs under device folders.',
                          LibraryGroup.titleLanguage =>
                            'Split songs into Arabic, English, and other titles.',
                          LibraryGroup.artist =>
                            'Show songs under artist names.',
                        },
                        selected: controller.group.value == value,
                        onTap: () {
                          controller.setGroup(value);
                          Get.back<void>();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
