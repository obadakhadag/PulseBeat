import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/follow_controller.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = Get.find<AuthController>();
  final FollowController _followController = Get.find<FollowController>();
  final UserService _userService = Get.find<UserService>();

  late final String? _targetUid = _resolveTargetUid();
  late final bool _isOwnProfile =
      _targetUid == null || _targetUid == _authController.uid;
  late final Future<UserModel?>? _targetProfileFuture = _isOwnProfile
      ? null
      : _userService.getUserProfile(_targetUid!);

  String? _resolveTargetUid() {
    final dynamic args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      return args.trim();
    }
    if (args is Map<String, dynamic>) {
      final dynamic uidValue = args['uid'];
      if (uidValue is String && uidValue.trim().isNotEmpty) {
        return uidValue.trim();
      }
    }

    final String? paramUid = Get.parameters['uid'];
    if (paramUid != null && paramUid.trim().isNotEmpty) {
      return paramUid.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'Profile' : 'User Profile'),
        actions: _isOwnProfile
            ? <Widget>[
                Obx(() {
                  return IconButton(
                    onPressed: _authController.isLoading.value
                        ? null
                        : _authController.logout,
                    icon: _authController.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    tooltip: 'Logout',
                  );
                }),
              ]
            : const <Widget>[],
      ),
      body: _isOwnProfile
          ? _buildOwnProfileBody(context)
          : _buildOtherProfileBody(context),
    );
  }

  Widget _buildOwnProfileBody(BuildContext context) {
    return Obx(() {
      if (_authController.isProfileLoading.value &&
          _authController.userProfile.value == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final UserModel? profile = _authController.userProfile.value;
      if (profile == null) {
        return const Center(child: Text('Profile not found.'));
      }

      return _ProfileContent(
        profile: profile,
        isOwnProfile: true,
        followController: _followController,
      );
    });
  }

  Widget _buildOtherProfileBody(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _targetProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load profile.'));
        }

        final UserModel? profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text('Profile not found.'));
        }

        return _ProfileContent(
          profile: profile,
          isOwnProfile: false,
          followController: _followController,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isOwnProfile,
    required this.followController,
  });

  final UserModel profile;
  final bool isOwnProfile;
  final FollowController followController;

  @override
  Widget build(BuildContext context) {
    final String bio = profile.bio.isEmpty ? 'No bio yet.' : profile.bio;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: CircleAvatar(
            radius: 54,
            backgroundImage: profile.photoUrl.isNotEmpty
                ? NetworkImage(profile.photoUrl)
                : null,
            child: profile.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, size: 46)
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : 'No display name',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            profile.username.isNotEmpty ? '@${profile.username}' : '@unknown',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            profile.email,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (!isOwnProfile && profile.isPrivate) ...<Widget>[
          const SizedBox(height: 16),
          Obx(() {
            final bool isSending = followController.isSending.value;
            return SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSending
                    ? null
                    : () => followController.requestFollow(profile.uid),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request Follow'),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: _CounterCard(
                label: 'Followers',
                value: profile.followersCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CounterCard(
                label: 'Following',
                value: profile.followingCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Bio',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(bio, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
