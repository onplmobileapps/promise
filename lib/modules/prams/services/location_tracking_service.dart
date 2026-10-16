import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

/// Where the phone is when an accident is reported.
class LocationTrackingService {
  /// The phone's position, or null when location is off, not allowed, or
  /// takes longer than ten seconds.
  Future<LatLng?> getCurrentPosition() async {
    try {
      if (!await _hasPermission()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) print('Error getting current position: $e');
      return null;
    }
  }

  Future<bool> _hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (kDebugMode) print('Location services are disabled.');
      return false;
    }
    // Says why first; once refused for good, offers the app's settings.
    return sl<PermissionGate>().request(AppPermission.location);
  }
}
