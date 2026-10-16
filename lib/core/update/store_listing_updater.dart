import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/update/app_info.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/core/update/update_available_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compares the app with its App Store listing and, when the listing is
/// newer, asks the user to update from the store, at most once a day. This
/// is how iOS updates, having no in-app update. On Android, Google Play
/// itself knows of updates (see `PlayAppUpdater`), so this finds none.
class StoreListingUpdater implements AppUpdater {
  StoreListingUpdater({
    Future<AppInfo?> Function()? appInfo,
    Future<Map<String, Object?>?> Function(String bundleId)? lookUp,
  }) : _appInfo = appInfo ?? AppInfo.load,
       _lookUp = lookUp ?? _appStoreLookUp;

  final Future<AppInfo?> Function() _appInfo;
  final Future<Map<String, Object?>?> Function(String bundleId) _lookUp;

  /// The country whose App Store lists the app.
  static const _country = 'pk';
  static const _askedKey = 'update_asked_at';
  static const _askAgainAfter = Duration(days: 1);

  @override
  Future<AppUpdate?> check() async {
    if (!Platform.isIOS) return null;
    try {
      final app = await _appInfo();
      if (app == null || app.id.isEmpty) return null;
      final listing = await _lookUp(app.id);
      final version = listing?['version']?.toString();
      final page = listing?['trackViewUrl']?.toString();
      if (version == null || !app.isOlderThan(version)) return null;
      if (!await _timeToAsk()) return null;
      return StoreUpdate(version: version, storeUrl: page);
    } on Exception catch (error) {
      debugPrint('Store version check failed: $error');
      return null;
    }
  }

  /// Not asked in the last day; noted as asked now.
  static Future<bool> _timeToAsk() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final last = prefs.getInt(_askedKey);
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            _askAgainAfter) {
      return false;
    }
    await prefs.setInt(_askedKey, now.millisecondsSinceEpoch);
    return true;
  }

  /// The app's App Store listing, from Apple's lookup service.
  static Future<Map<String, Object?>?> _appStoreLookUp(String bundleId) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(
        Uri.https('itunes.apple.com', '/lookup', {
          'bundleId': bundleId,
          'country': _country,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response.transform(utf8.decoder).join();
      final results = (jsonDecode(body) as Map)['results'] as List?;
      if (results == null || results.isEmpty) return null;
      return (results.first as Map).cast<String, Object?>();
    } finally {
      client.close(force: true);
    }
  }
}

/// A newer version in the store: the sheet that offers it, and the store
/// page it opens.
class StoreUpdate implements AppUpdate {
  const StoreUpdate({this.version, this.storeUrl});

  final String? version;

  /// The App Store page; on Android, null for the app's Play page.
  final String? storeUrl;

  @override
  Future<void> start(BuildContext context) => showUpdateAvailableSheet(
    context: context,
    version: version,
    onUpdate: () => AppInfo.openStore(storeUrl),
  );
}
