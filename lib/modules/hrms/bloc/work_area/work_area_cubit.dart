import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone's location, behind an interface so it can be faked in tests.
abstract class PositionSource {
  Future<bool> serviceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Stream<Position> positions();

  /// One fresh fix now, rather than waiting for the stream.
  Future<Position> current();
  Stream<ServiceStatus> serviceStatus();
  Future<void> openLocationSettings();
  Future<void> openAppSettings();
}

class GeolocatorPositionSource implements PositionSource {
  const GeolocatorPositionSource();

  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() async {
    // Says why first; the system's prompt follows only if the user goes on.
    await sl<PermissionGate>().request(AppPermission.location);
    return Geolocator.checkPermission();
  }

  @override
  Stream<Position> positions() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
  @override
  Future<Position> current() => CurrentLocationService.freshFix();
  @override
  Stream<ServiceStatus> serviceStatus() => Geolocator.getServiceStatusStream();
  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}

/// The `getAuthArea` response for the signed-in employee.
Future<Object?> fetchAuthArea() async {
  final user = await StorageService.getUser();
  final empId = user?.user?.empid;
  if (empId == null) throw AppException('Please sign in again.');
  final response = await DioClient().get(
    'organization/getAuthArea',
    queryParameters: {'emp_id': empId},
  );
  return response.data;
}

/// Where the employee may mark attendance, where they are, and whether
/// they are inside. Offices are kept on the phone so the area still shows
/// offline.
class WorkAreaCubit extends SafeCubit<WorkAreaState> {
  WorkAreaCubit({
    Future<Object?> Function() fetch = fetchAuthArea,
    PositionSource location = const GeolocatorPositionSource(),
  }) : _fetch = fetch,
       _location = location,
       super(const WorkAreaState());

  final Future<Object?> Function() _fetch;
  final PositionSource _location;
  StreamSubscription<Position>? _positions;
  StreamSubscription<ServiceStatus>? _service;

  static const String _cacheKey = 'work_area_offices';

  Future<void> start() async {
    _service ??= _location.serviceStatus().listen(
      (_) => unawaited(_startLocation()),
      onError: (Object e) => debugPrint('Location service status: $e'),
    );
    await Future.wait([loadOffices(), _startLocation()]);
  }

  /// Finds where the employee is afresh: the location updates start over
  /// and one fix is asked for at once. For a refresh key, and before a
  /// check-in when the last fix is old.
  Future<void> refreshLocation() async {
    if (state.refreshing) return;
    emit(state.copyWith(refreshing: true, refreshFailed: false));
    try {
      await _startLocation(ask: false);
      if (state.access == LocationAccess.serviceOff ||
          state.access == LocationAccess.denied) {
        return;
      }
      _onPosition(await _location.current());
      if (!isClosed) emit(state.copyWith(refreshedAt: DateTime.now()));
    } catch (e) {
      debugPrint('Refreshing the location failed: $e');
      if (!isClosed) emit(state.copyWith(refreshFailed: true));
    } finally {
      if (!isClosed) emit(state.copyWith(refreshing: false));
    }
  }

  /// Swipe to refresh: the offices again, and location if it was off.
  Future<void> refresh() async {
    await Future.wait([
      loadOffices(),
      if (state.access != LocationAccess.ready) _startLocation(),
    ]);
  }

  Future<void> loadOffices() async {
    emit(state.copyWith(loadingOffices: true));
    try {
      final body = await _fetch();
      final offices = WorkOffice.parseAuthArea(body);

      final newStatus = _extractVerificationStatus(body);
      if (newStatus != null && newStatus.isNotEmpty) {
        final saved = await StorageService.getUser();
        if (saved != null && saved.user != null) {
          await StorageService.saveUser(
            saved.copyWith(
              user: saved.user!.copyWith(verificationStatus: newStatus),
            ),
          );
        }
      }

      emit(
        state.copyWith(
          loadingOffices: false,
          offices: offices,
          officesError: offices.isEmpty
              ? 'No work area is assigned to you yet.'
              : null,
        ),
      );
      unawaited(_save(body));
    } catch (e) {
      debugPrint('Loading the work area failed: $e');
      final cached = state.offices.isNotEmpty ? state.offices : await _cached();
      emit(
        state.copyWith(
          loadingOffices: false,
          offices: cached,
          officesError: cached.isEmpty ? ErrorHandler.handle(e).message : null,
        ),
      );
    }
  }

  String? _extractVerificationStatus(Object? node) {
    if (node is Map) {
      for (final key in [
        'Verification_Status',
        'verification_status',
        'verificationStatus',
        'VerificationStatus',
      ]) {
        final val = node[key]?.toString().trim();
        if (val != null && val.isNotEmpty && val != 'null') {
          return val;
        }
      }
      for (final key in ['emp', 'offices', 'data', 'user']) {
        if (node[key] != null) {
          final status = _extractVerificationStatus(node[key]);
          if (status != null) return status;
        }
      }
      for (final val in node.values) {
        if (val is Map || val is List) {
          final status = _extractVerificationStatus(val);
          if (status != null) return status;
        }
      }
    } else if (node is List && node.isNotEmpty) {
      for (final item in node) {
        final status = _extractVerificationStatus(item);
        if (status != null) return status;
      }
    }
    return null;
  }

  /// Asks for location, or opens the settings where it can be turned on.
  Future<void> enableLocation() async {
    switch (state.access) {
      case LocationAccess.serviceOff:
        await _location.openLocationSettings();
      case LocationAccess.denied:
        final permission = await _location.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          await _location.openAppSettings();
        } else {
          await _startLocation(ask: true);
        }
      case LocationAccess.checking:
      case LocationAccess.ready:
        break;
    }
  }

  /// Starting already, so a second start joins it instead of asking again.
  Future<void>? _starting;

  Future<void> _startLocation({bool ask = true}) =>
      _starting ??= _start(ask: ask).whenComplete(() => _starting = null);

  Future<void> _start({bool ask = true}) async {
    try {
      if (!await _location.serviceEnabled()) {
        await _positions?.cancel();
        _positions = null;
        emit(state.copyWith(access: LocationAccess.serviceOff));
        return;
      }
      var permission = await _location.checkPermission();
      if (permission == LocationPermission.denied && ask) {
        permission = await _location.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(access: LocationAccess.denied));
        return;
      }
      if (state.access != LocationAccess.ready) {
        emit(state.copyWith(access: LocationAccess.checking));
      }
      await _positions?.cancel();
      _positions = _location.positions().listen(
        _onPosition,
        onError: (Object e) {
          debugPrint('Location updates: $e');
          unawaited(_startLocation(ask: false));
        },
      );
    } catch (e) {
      debugPrint('Starting location failed: $e');
      emit(state.copyWith(access: LocationAccess.serviceOff));
    }
  }

  /// A stale first fix has been followed by a fresh one already.
  bool _askedFresh = false;

  void _onPosition(Position p) {
    // The first report is often the location the phone last knew, which
    // can be far from where the employee is now: ask for a fresh one.
    if (!_askedFresh &&
        DateTime.now().difference(p.timestamp) > WorkAreaState.staleAfter) {
      _askedFresh = true;
      unawaited(refreshLocation());
    }
    // A fake GPS app's location places no one in the area.
    if (p.isMocked) {
      emit(
        state.copyWith(
          access: LocationAccess.ready,
          spoofed: true,
          clearPosition: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        access: LocationAccess.ready,
        position: LatLng(p.latitude, p.longitude),
        accuracyM: p.accuracy,
        positionAt: p.timestamp,
        spoofed: false,
      ),
    );
  }

  Future<void> _save(Object? body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(body));
    } catch (_) {
      // Only a cache.
    }
  }

  Future<List<WorkOffice>> _cached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      return raw == null ? const [] : WorkOffice.parseAuthArea(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> close() async {
    await _positions?.cancel();
    await _service?.cancel();
    return super.close();
  }
}
