import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/utils/extensions.dart';
import '../../routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _routeFromAuthState();
  }

  Future<void> _routeFromAuthState() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || _didNavigate) {
      return;
    }

    _didNavigate = true;
    final bool isLoggedIn = Get.find<AuthController>().isLoggedIn;
    Get.offNamed(isLoggedIn ? AppPages.home : AppPages.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.primary.withValues(alpha: 0.92),
              colors.secondary.withValues(alpha: 0.95),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const <double>[0, 0.46, 1],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PulseBeat',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Preparing your session.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    color: Colors.white,
                    backgroundColor: Color(0x40FFFFFF),
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
