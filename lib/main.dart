import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/settings_controller.dart';
import 'core/bindings/app_bindings.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppBindings.ensureInitialized();
    final SettingsController settings = Get.find<SettingsController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode.value,
        getPages: AppPages.pages,
        initialRoute: AppPages.splash,
      ),
    );
  }
}
