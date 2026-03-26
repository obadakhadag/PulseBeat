import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String displayName = _displayNameController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Missing fields', 'Email and password are required.');
      return;
    }

    if (_isSignUpMode && confirmPassword != password) {
      Get.snackbar('Password mismatch', 'Passwords do not match.');
      return;
    }

    if (_isSignUpMode) {
      await _authController.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      return;
    }

    await _authController.loginWithEmail(email: email, password: password);
  }

  void _toggleMode(bool value) {
    if (_isSignUpMode == value) {
      return;
    }

    setState(() {
      _isSignUpMode = value;
      _confirmPasswordController.clear();
      _obscureConfirmPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.primary.withValues(alpha: 0.24),
              theme.scaffoldBackgroundColor,
              colors.secondary.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppHelpers.glowShadows(context),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                    ),
                  ),
                  child: Obx(() {
                    final bool isLoading = _authController.isLoading.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                colors.primary,
                                colors.tertiary,
                                colors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.multitrack_audio_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isSignUpMode
                              ? 'Create your PulseBeat account'
                              : 'Welcome back to PulseBeat',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUpMode
                              ? 'Create your new account in pulse beat and enjoy the beat .'
                              : 'Sign in with email or Google .',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _AuthModeToggle(
                          isSignUpMode: _isSignUpMode,
                          onChanged: _toggleMode,
                        ),
                        const SizedBox(height: 22),
                        AutofillGroup(
                          child: Column(
                            children: <Widget>[
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: !_isSignUpMode
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        key: const ValueKey<String>(
                                          'display-name-field',
                                        ),
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: TextField(
                                          controller: _displayNameController,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const <String>[
                                            AutofillHints.name,
                                            AutofillHints.username,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'Display name',
                                            prefixIcon: const Icon(
                                              Icons.person_rounded,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.email,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: _isSignUpMode
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                autofillHints: <String>[
                                  _isSignUpMode
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                onSubmitted: (_) =>
                                    !_isSignUpMode ? _submit() : null,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.password_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: !_isSignUpMode
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        key: const ValueKey<String>(
                                          'confirm-password-field',
                                        ),
                                        padding: const EdgeInsets.only(top: 16),
                                        child: TextField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const <String>[
                                            AutofillHints.newPassword,
                                          ],
                                          onSubmitted: (_) => _submit(),
                                          decoration: InputDecoration(
                                            labelText: 'Confirm password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                            ),
                                            suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons
                                                          .visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(
                                    _isSignUpMode
                                        ? 'Create account'
                                        : 'Sign in',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _toggleMode(!_isSignUpMode),
                            child: Text(
                              _isSignUpMode
                                  ? 'Already have an account? Sign in'
                                  : 'Need an account? Create one',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Divider(
                                color: colors.onSurface.withValues(alpha: 0.18),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'or continue with',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.60,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: colors.onSurface.withValues(alpha: 0.18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _authController.loginWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 26,
                                  ),
                            label: const Text('Google'),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({required this.isSignUpMode, required this.onChanged});

  final bool isSignUpMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    Widget option({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      colors: <Color>[
                        colors.primary,
                        colors.tertiary,
                        colors.secondary,
                      ],
                    )
                  : null,
              color: selected ? null : colors.onSurface.withValues(alpha: 0.04),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? colors.onPrimary
                    : colors.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          option(
            label: 'Sign in',
            selected: !isSignUpMode,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 6),
          option(
            label: 'Create account',
            selected: isSignUpMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}
