import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/profile/profile_face.dart';

/// How a [UserAvatar] is set on the page; see [AppAvatar].
enum UserAvatarStyle { ring, key }

/// The signed-in user's avatar: their initials, or the photo or emoji they
/// chose for [employeeId] on this phone.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.employeeId,
    this.style = UserAvatarStyle.ring,
    this.size,
    this.onTap,
    this.semanticLabel,
    this.badge,
  });

  final String name;
  final String employeeId;
  final UserAvatarStyle style;
  final double? size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// A key on its corner showing what a tap does; see [AppAvatar.badge].
  final AppGlyph? badge;

  @override
  Widget build(BuildContext context) {
    final store = ProfileFaceStore.instance..showFor(employeeId);
    return ValueListenableBuilder<ProfileFace>(
      valueListenable: store,
      builder: (context, _, _) {
        final face = store.faceFor(employeeId);
        final photo = face is PhotoFace ? FileImage(face.file) : null;
        final emoji = face is EmojiFace ? face.emoji : null;
        final emojiBackground = face is EmojiFace
            ? face.tint.colorIn(context.colors)
            : null;
        return switch (style) {
          UserAvatarStyle.ring => AppAvatar(
            name: name,
            size: size ?? AppSizes.headerControl,
            onTap: onTap,
            semanticLabel: semanticLabel,
            photo: photo,
            emoji: emoji,
            emojiBackground: emojiBackground,
            badge: badge,
          ),
          UserAvatarStyle.key => AppAvatar.key(
            name: name,
            size: size ?? AppSizes.profileAvatar,
            onTap: onTap,
            semanticLabel: semanticLabel,
            photo: photo,
            emoji: emoji,
            emojiBackground: emojiBackground,
            badge: badge,
          ),
        };
      },
    );
  }
}
