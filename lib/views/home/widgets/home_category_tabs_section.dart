import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../core/utils/extensions.dart';

class HomeCategoryTabsSection extends StatelessWidget {
  const HomeCategoryTabsSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Obx(() {
        final HomeBrowseCategory activeCategory =
            controller.browseCategory.value;
        final List<({HomeBrowseCategory category, String label})> categories =
            <({HomeBrowseCategory category, String label})>[
              (category: HomeBrowseCategory.allSongs, label: 'All Songs'.tr),
              (category: HomeBrowseCategory.folders, label: 'Folders'.tr),
              (category: HomeBrowseCategory.language, label: 'Language'.tr),
              (category: HomeBrowseCategory.artist, label: 'Artist'.tr),
            ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories
                .map((item) {
                  final bool active = item.category == activeCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => controller.setBrowseCategory(item.category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: active
                              ? LinearGradient(
                                  colors: <Color>[
                                    context.colors.secondary,
                                    context.colors.tertiary,
                                  ],
                                )
                              : null,
                          color: active
                              ? null
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: active
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.70),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        );
      }),
    );
  }
}
