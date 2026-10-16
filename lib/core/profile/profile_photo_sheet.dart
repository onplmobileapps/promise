import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';
import 'package:railway_hrms/core/profile/emoji_picker.dart';
import 'package:railway_hrms/core/profile/profile_face.dart';

/// What the user can do with their profile photo.
enum _Choice { camera, gallery, avatar, remove }

/// Lets the signed-in user, [name], take or pick a profile photo, make an
/// emoji avatar, or go back to their initials. All of it stays on the
/// phone.
Future<void> showProfilePhotoSheet(
  BuildContext context, {
  required String name,
}) async {
  final l10n = context.l10n;
  final store = ProfileFaceStore.instance;
  final choice = await showAppSheet<_Choice>(
    context: context,
    title: l10n.profilePhotoTitle,
    subtitle: l10n.profilePhotoSubtitle,
    closeLabel: l10n.actionClose,
    builder: (sheet) {
      Widget row(_Choice choice, AppGlyph glyph, String title) => AppListRow(
        leading: AppToneIcon(glyph: glyph),
        title: title,
        onTap: () => Navigator.of(sheet).pop(choice),
      );
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppListGroup(
          children: [
            row(_Choice.camera, AppGlyphs.camera, l10n.profilePhotoCamera),
            row(_Choice.gallery, AppGlyphs.image, l10n.profilePhotoGallery),
            row(_Choice.avatar, AppGlyphs.smile, l10n.profilePhotoAvatar),
            if (store.value is! InitialsFace)
              row(_Choice.remove, AppGlyphs.trash, l10n.profilePhotoRemove),
          ],
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;
  try {
    switch (choice) {
      case _Choice.camera || _Choice.gallery:
        final photo = await PhotoPicker.pick(
          source: choice == _Choice.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          context: context,
          camera: CameraDevice.front,
          imageQuality: AppSizes.profilePhotoQuality,
          maxWidth: AppSizes.profilePhotoWidth,
        );
        if (photo != null) await store.usePhoto(photo);
      case _Choice.avatar:
        final now = store.value;
        final avatar = await showEmojiPicker(
          context,
          name: name,
          initial: now is EmojiFace ? (emoji: now.emoji, tint: now.tint) : null,
        );
        if (avatar != null) {
          await store.useEmoji(avatar.emoji, tint: avatar.tint);
        }
      case _Choice.remove:
        await store.useInitials();
    }
  } on Exception catch (error) {
    debugPrint('Profile photo not saved: $error');
    if (context.mounted) {
      showAppMessage(
        context,
        l10n.profilePhotoFailed,
        tone: AppDialogTone.error,
      );
    }
  }
}
