import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    this.photoUrl,
    this.radius = 24,
    this.iconSize,
    this.backgroundColor,
  });

  final String? photoUrl;
  final double radius;
  final double? iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String resolvedPhotoUrl = _resolvedPhotoUrl;
    final ImageProvider<Object>? imageProvider = avatarImageProvider(
      resolvedPhotoUrl,
    );
    final ImageProvider<Object>? fallbackProvider = avatarImageProvider(
      AppConstants.defaultAvatarAsset,
    );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      ),
      child: ClipOval(
        child: imageProvider == null
            ? _fallbackIcon(context)
            : Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  if (resolvedPhotoUrl == AppConstants.defaultAvatarAsset ||
                      fallbackProvider == null) {
                    return _fallbackIcon(context);
                  }

                  return Image(
                    image: fallbackProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackIcon(context),
                  );
                },
              ),
      ),
    );
  }

  String get _resolvedPhotoUrl {
    final String trimmedPhotoUrl = photoUrl?.trim() ?? '';
    return trimmedPhotoUrl.isEmpty
        ? AppConstants.defaultAvatarAsset
        : trimmedPhotoUrl;
  }

  Widget _fallbackIcon(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: iconSize ?? radius * 0.9,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
    );
  }
}

ImageProvider<Object>? avatarImageProvider(String? source) {
  final String trimmedSource = source?.trim() ?? '';
  if (trimmedSource.isEmpty) {
    return null;
  }

  if (trimmedSource.startsWith('assets/')) {
    return AssetImage(trimmedSource);
  }

  final Uri? uri = Uri.tryParse(trimmedSource);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(trimmedSource);
  }

  return null;
}
