// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/bindings/app_bindings.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing Supabase...');

  await Supabase.initialize(
    url: 'https://iqanmrzhpxyjsqktikoe.supabase.co',
    anonKey: 'sb_publishable_VoM5e_iE0IP34AvPIIdrWQ_fYsYydpR',
  );

  print('Supabase initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      getPages: AppPages.pages,
      initialRoute: AppPages.splash,
      initialBinding: InitialBinding(),
    );
  }
}
