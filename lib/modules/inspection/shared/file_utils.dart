import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String _kImagesSubdir = 'footplate_images';

class FootplateFileUtils {
  static Future<String> saveImagePermanently(String temporaryPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = temporaryPath.split(Platform.pathSeparator).last;
      final relativePath = '$_kImagesSubdir/$name';
      final permanentPath = '${directory.path}/$relativePath';

      final file = File(temporaryPath);
      if (!await file.exists()) return temporaryPath;

      final permanentFile = File(permanentPath);

      if (!await permanentFile.parent.exists()) {
        await permanentFile.parent.create(recursive: true);
      }

      await file.copy(permanentPath);
      return relativePath;
    } catch (e) {
      // Return original path if something goes wrong
      return temporaryPath;
    }
  }

  static Future<String> resolveAbsolutePath(String storedPath) async {
    final directory = await getApplicationDocumentsDirectory();

    if (!storedPath.startsWith('/')) {
      return '${directory.path}/$storedPath';
    }
    if (await File(storedPath).exists()) return storedPath;

    final idx = storedPath.indexOf(_kImagesSubdir);
    if (idx != -1) {
      final tail = storedPath.substring(idx); // "footplate_images/<file>"
      return '${directory.path}/$tail';
    }
    return storedPath;
  }

  static Future<bool> imageFileExists(String storedPath) async {
    try {
      final resolved = await resolveAbsolutePath(storedPath);
      return await File(resolved).exists();
    } catch (_) {
      return false;
    }
  }
}
