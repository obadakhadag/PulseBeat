// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/bindings/app_bindings.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'controllers/app_shell_controller.dart';
import 'localization/app_translations.dart';
import 'routes/app_pages.dart';
import 'services/storage_service.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing Supabase...');

  await Supabase.initialize(
    url: 'https://iqanmrzhpxyjsqktikoe.supabase.co',
    anonKey: 'sb_publishable_VoM5e_iE0IP34AvPIIdrWQ_fYsYydpR',
  );

  print('Supabase initialized successfully');

  final StorageService storageService = StorageService(AppConstants.storageBox);
  await storageService.ensureInitialized();
  final ThemeMode initialThemeMode = switch (storageService.getThemeMode()) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
  final Locale initialLocale = AppTranslations.resolveLocale(
    storageService.getLanguageCode(),
  );

  runApp(
    MyApp(initialThemeMode: initialThemeMode, initialLocale: initialLocale),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialThemeMode,
    required this.initialLocale,
  });

  final ThemeMode initialThemeMode;
  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: AppTranslations.fallbackLocale,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      getPages: AppPages.pages,
      initialRoute: AppPages.splash,
      initialBinding: InitialBinding(),
      navigatorObservers: <NavigatorObserver>[AppShellNavigatorObserver()],
      builder: (BuildContext context, Widget? child) {
        return AppShell(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
