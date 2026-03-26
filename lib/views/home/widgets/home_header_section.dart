import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/app_user_avatar.dart';

class HomeHeaderSection extends GetView<AuthController> {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String photoUrl = controller.userProfile.value?.photoUrl ?? '';

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Get.toNamed(AppPages.profile),
              child: AppUserAvatar(photoUrl: photoUrl, radius: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'PulseBeat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Mix'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Requests'.tr,
              onPressed: () => Get.toNamed(AppPages.followRequests),
              icon: const Icon(Icons.person_add_alt_rounded),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.tertiary.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Settings'.tr,
              onPressed: () => Get.toNamed(AppPages.settings),
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      );
    });
  }
}
