import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';

/// Round profile photo of the logged-in user (saved in the `avatars`
/// bucket). Shows [fallbackIcon] when there is no photo, and updates by
/// itself when the photo changes.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final IconData fallbackIcon;
  final Color background;
  final Color iconColor;
  final Color? borderColor;
  final double borderWidth;

  /// Small camera badge so users know the photo can be changed.
  final bool showEditBadge;

  const ProfileAvatar({
    super.key,
    required this.size,
    required this.background,
    required this.iconColor,
    this.fallbackIcon = Icons.person,
    this.borderColor,
    this.borderWidth = 0,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AuthService.avatarUrl,
      builder: (context, url, _) {
        final Widget icon = Center(
          child: Icon(fallbackIcon, color: iconColor, size: size * 0.6),
        );

        final Widget circle = Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(borderColor == null ? 0 : borderWidth),
          decoration: BoxDecoration(
            color: borderColor ?? background,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: ColoredBox(
              color: background,
              child: url == null
                  ? icon
                  : Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) =>
                progress == null
                    ? child
                    : Center(
                  child: SizedBox(
                    width: size * 0.3,
                    height: size * 0.3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  ),
                ),
                errorBuilder: (context, error, stack) => icon,
              ),
            ),
          ),
        );

        if (!showEditBadge) return circle;

        final double badgeIcon = (size * 0.14).clamp(12, 16).toDouble();
        return Stack(
          children: [
            circle,
            Positioned(
              right: 0,
              bottom: size * 0.03,
              child: Container(
                padding: EdgeInsets.all(badgeIcon * 0.45),
                decoration: BoxDecoration(
                  color: kBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: badgeIcon),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _AvatarAction { camera, gallery, remove }

/// Bottom sheet to take, choose or remove the profile photo. The photo is
/// saved to the database right away.
Future<void> showAvatarOptions(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final bool hasPhoto = AuthService.avatarUrl.value != null;

  final _AvatarAction? action = await showModalBottomSheet<_AvatarAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          // Chrome has no camera option, so only the gallery is shown there.
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera, color: kBlue),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.camera),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: kBlue),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, _AvatarAction.gallery),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.remove),
            ),
        ],
      ),
    ),
  );
  if (action == null) return;

  void show(String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  try {
    if (action == _AvatarAction.remove) {
      await AuthService.removeAvatar();
      show('Profile photo removed.');
      return;
    }

    final XFile? picked = await ImagePicker().pickImage(
      source: action == _AvatarAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    show('Saving photo...');
    await AuthService.saveAvatar(await picked.readAsBytes(), picked.name);
    show('Profile photo updated.');
  } on AuthFailure catch (e) {
    show(e.message);
  } catch (_) {
    show('Could not open the camera or gallery.');
  }
}