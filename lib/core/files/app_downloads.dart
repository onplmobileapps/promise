import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// A file the app saved for the user.
@immutable
class SavedFile {
  const SavedFile({required this.uri, required this.name, required this.mime});

  /// Where the phone keeps it: a content URI on Android, a file URL on iOS.
  final String uri;
  final String name;
  final String mime;
}

/// Why a file couldn't be saved.
enum SaveFailure {
  /// The user didn't let the app write to storage (Android 9 and older).
  permission,

  /// The phone refused the file, or ran out of room.
  failed,
}

class SaveException implements Exception {
  const SaveException(this.reason, [this.message]);

  final SaveFailure reason;
  final String? message;

  @override
  String toString() => 'SaveException($reason, $message)';
}

/// Files the app makes for the user, such as reports, saved where they
/// look for downloads: Downloads › PROMISE on Android, and the PROMISE
/// folder of the Files app on iOS. Then opened, or shared to other apps.
abstract final class AppDownloads {
  @visibleForTesting
  static MethodChannel channel = const MethodChannel('railway_hrms/downloads');

  /// Saves [bytes] as [name], numbered if the name is taken. Asks for
  /// storage on old Androids, which need it.
  static Future<SavedFile> save(
    Uint8List bytes, {
    required String name,
    required String mime,
  }) async {
    Future<String?> write() => channel.invokeMethod<String>('save', {
      'name': name,
      'mime': mime,
      'bytes': bytes,
    });
    try {
      String? uri;
      try {
        uri = await write();
      } on PlatformException catch (error) {
        if (error.code != 'permission') rethrow;
        if (!(await Permission.storage.request()).isGranted) {
          throw const SaveException(SaveFailure.permission);
        }
        uri = await write();
      }
      if (uri == null || uri.isEmpty) {
        throw const SaveException(SaveFailure.failed);
      }
      return SavedFile(uri: uri, name: name, mime: mime);
    } on PlatformException catch (error) {
      throw SaveException(
        error.code == 'permission'
            ? SaveFailure.permission
            : SaveFailure.failed,
        error.message,
      );
    }
  }

  /// Opens [file] in an app that shows it; false if none can.
  static Future<bool> open(SavedFile file) async =>
      await channel.invokeMethod<bool>('open', {
        'uri': file.uri,
        'mime': file.mime,
      }) ??
      false;

  /// Offers [file] to other apps, under [title].
  static Future<bool> share(SavedFile file, {String title = ''}) async =>
      await channel.invokeMethod<bool>('share', {
        'uri': file.uri,
        'mime': file.mime,
        'title': title,
      }) ??
      false;
}
