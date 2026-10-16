import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

import 'package:geolocator/geolocator.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';

class CurrentLocationService {
  CurrentLocationService._privateConstructor();

  /// The longest a fix is waited for.
  static const Duration fixTimeLimit = Duration(seconds: 15);

  /// The oldest a phone's remembered location may be and still count when
  /// no fresh fix comes in time.
  static const Duration lastKnownMaxAge = Duration(minutes: 2);

  /// Where the phone is now, from GPS, Wi-Fi and cell towers together, so
  /// it also works indoors. If no fix comes within [limit], the location
  /// the phone last knew is used, but only if it is recent; an older one
  /// would place the employee where they were, not where they are.
  static Future<Position> freshFix({Duration limit = fixTimeLimit}) async {
    final LocationSettings settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: limit,
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: limit,
      ),
      _ => LocationSettings(accuracy: LocationAccuracy.high, timeLimit: limit),
    };
    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <= lastKnownMaxAge) {
        return last;
      }
      rethrow;
    }
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    // 2. Ask for location, saying why first; once refused for good, the
    // app's settings are offered instead.
    if (!await sl<PermissionGate>().request(AppPermission.location)) {
      log('Location permission not granted.');
      return Future.error('Location permission not granted.');
    }

    // 3. A fresh fix, never waiting forever indoors.
    final position = await freshFix();
    // A fake GPS app's location; the caller says so.
    if (position.isMocked) throw const LocationSpoofedException();
    return position;
  }
}
