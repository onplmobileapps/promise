import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What stands for the user in their avatar.
sealed class ProfileFace {
  const ProfileFace();
}

/// Their initials, until they choose something else.
final class InitialsFace extends ProfileFace {
  const InitialsFace();
}

/// A photo they took or picked.
final class PhotoFace extends ProfileFace {
  const PhotoFace(this.file);

  final File file;
}

/// The colour behind an emoji avatar.
enum AvatarTint {
  jade,
  gold,
  sky,
  rose,
  sand;

  Color colorIn(AppColors colors) => switch (this) {
    jade => colors.primaryContainer,
    gold => colors.goldContainer,
    sky => colors.infoContainer,
    rose => colors.dangerContainer,
    sand => colors.surfaceMuted,
  };
}

/// An emoji they chose, on a [tint].
final class EmojiFace extends ProfileFace {
  const EmojiFace(this.emoji, {this.tint = AvatarTint.jade});

  final String emoji;
  final AvatarTint tint;
}

/// The face of each user who signs in on this phone. It is kept on the
/// phone only, never sent to the server, and outlives signing out and
/// updates of the app; each employee ID has its own.
class ProfileFaceStore extends ValueNotifier<ProfileFace> {
  ProfileFaceStore._() : super(const InitialsFace());

  static final instance = ProfileFaceStore._();

  static const _keyPrefix = 'profile_face_';
  static const _photoTag = 'photo:';
  static const _emojiTag = 'emoji:';

  String? _owner;

  /// Whose face [value] is, once it has loaded.
  String? _loadedFor;

  /// [employeeId]'s face: never anyone else's, so while theirs loads, and
  /// for someone with no ID, it is the initials.
  ProfileFace faceFor(String employeeId) =>
      employeeId.isNotEmpty && employeeId == _loadedFor
      ? value
      : const InitialsFace();

  /// Shows [employeeId]'s face, loading it the first time. Safe to call
  /// while building: the face arrives afterwards.
  void showFor(String employeeId) {
    if (employeeId == _owner) return;
    _owner = employeeId;
    unawaited(_load(employeeId));
  }

  Future<void> _load(String owner) async {
    var face = const InitialsFace() as ProfileFace;
    if (owner.isNotEmpty) {
      try {
        final saved = (await SharedPreferences.getInstance()).getString(
          _keyPrefix + owner,
        );
        if (saved != null && saved.startsWith(_emojiTag)) {
          // "emoji:<tint>:<emoji>", or before tints "emoji:<emoji>".
          final rest = saved.substring(_emojiTag.length);
          final split = rest.indexOf(':');
          final tint = split < 0
              ? null
              : AvatarTint.values.asNameMap()[rest.substring(0, split)];
          face = tint == null
              ? EmojiFace(rest)
              : EmojiFace(rest.substring(split + 1), tint: tint);
        } else if (saved != null && saved.startsWith(_photoTag)) {
          // Only the file's name is kept: on iOS the app's folder moves
          // when the app is updated.
          final file = File(
            '${(await _folder()).path}/${saved.substring(_photoTag.length)}',
          );
          if (await file.exists()) face = PhotoFace(file);
        }
      } on Exception catch (error) {
        debugPrint('Profile face unavailable: $error');
      }
    }
    if (_owner != owner) return;
    _loadedFor = owner;
    value = face;
    notifyListeners();
  }

  /// Uses [picked] as the photo, keeping a copy of it.
  Future<void> usePhoto(XFile picked) async {
    final owner = _owner;
    if (owner == null || owner.isEmpty) return;
    // A new name each time, so the old photo isn't shown from the cache.
    final name = '${_safe(owner)}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${(await _folder()).path}/$name');
    await file.writeAsBytes(await picked.readAsBytes(), flush: true);
    await _save(owner, _photoTag + name, PhotoFace(file));
  }

  /// Uses [emoji] on [tint] in place of a photo.
  Future<void> useEmoji(
    String emoji, {
    AvatarTint tint = AvatarTint.jade,
  }) async {
    final owner = _owner;
    if (owner == null || owner.isEmpty) return;
    await _save(
      owner,
      '$_emojiTag${tint.name}:$emoji',
      EmojiFace(emoji, tint: tint),
    );
  }

  /// Goes back to the initials.
  Future<void> useInitials() async {
    final owner = _owner;
    if (owner == null || owner.isEmpty) return;
    await _save(owner, null, const InitialsFace());
  }

  Future<void> _save(String owner, String? saved, ProfileFace face) async {
    final previous = value;
    final prefs = await SharedPreferences.getInstance();
    if (saved == null) {
      await prefs.remove(_keyPrefix + owner);
    } else {
      await prefs.setString(_keyPrefix + owner, saved);
    }
    if (_owner == owner) {
      _loadedFor = owner;
      value = face;
    }
    // The photo it replaces is no longer needed.
    if (previous is PhotoFace && previous.file.path != _pathOf(face)) {
      try {
        await previous.file.delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  static String? _pathOf(ProfileFace face) =>
      face is PhotoFace ? face.file.path : null;

  static String _safe(String owner) =>
      owner.replaceAll(RegExp('[^A-Za-z0-9]'), '_');

  static Future<Directory> _folder() async {
    final folder = Directory(
      '${(await getApplicationSupportDirectory()).path}/profile',
    );
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }
}
