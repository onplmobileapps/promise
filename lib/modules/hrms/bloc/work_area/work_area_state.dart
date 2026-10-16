import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/utils/equatable.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';

enum LocationAccess {
  /// Asking for permission or waiting for the first fix.
  checking,
  ready,

  /// Location is turned off on the phone.
  serviceOff,

  /// The app may not use location.
  denied,
}

enum Presence { unknown, inside, outside }

class WorkAreaState extends Equatable {
  final bool loadingOffices;
  final List<WorkOffice> offices;
  final String? officesError;

  final LocationAccess access;
  final LatLng? position;

  /// How far off the position may be, in metres.
  final double? accuracyM;
  final DateTime? positionAt;

  /// The latest location came from a fake GPS app, so it places no one.
  final bool spoofed;

  /// A fresh fix is being found.
  final bool refreshing;

  /// When a fresh fix was last found on request.
  final DateTime? refreshedAt;

  /// The last request for a fresh fix found none.
  final bool refreshFailed;

  /// A fix less sure than this, in metres, is only roughly where they are.
  static const double roughAccuracyM = 50;

  /// The fix may be well off where the employee is.
  bool get isRough => (accuracyM ?? 0) > roughAccuracyM;

  /// A fix older than this is only where the employee was.
  static const Duration staleAfter = Duration(minutes: 1);

  /// The fix is old at [now], so it may no longer be where they are.
  bool isStale(DateTime now) {
    final at = positionAt;
    return at != null && now.difference(at) > staleAfter;
  }

  const WorkAreaState({
    this.loadingOffices = true,
    this.offices = const [],
    this.officesError,
    this.access = LocationAccess.checking,
    this.position,
    this.accuracyM,
    this.positionAt,
    this.spoofed = false,
    this.refreshing = false,
    this.refreshedAt,
    this.refreshFailed = false,
  });

  /// GPS error forgiven at the edge of an area, at most.
  static const double maxToleranceM = 30;

  double get _tolerance => math.min(accuracyM ?? 0, maxToleranceM);

  /// The office nearest the user, or the primary one while the position is
  /// unknown.
  WorkOffice? get nearestOffice {
    if (offices.isEmpty) return null;
    final at = position;
    if (at == null) {
      return offices.firstWhere(
        (o) => o.isPrimary,
        orElse: () => offices.first,
      );
    }
    return offices.reduce(
      (a, b) => a.distanceToEdgeM(at) <= b.distanceToEdgeM(at) ? a : b,
    );
  }

  /// The office the user is in, if any.
  WorkOffice? get currentOffice {
    final at = position;
    if (at == null) return null;
    for (final office in offices) {
      if (office.contains(at, toleranceM: _tolerance)) return office;
    }
    return null;
  }

  Presence get presence {
    if (position == null || offices.isEmpty) return Presence.unknown;
    return currentOffice != null ? Presence.inside : Presence.outside;
  }

  /// Metres from the user to the nearest area's edge.
  double? get distanceToEdgeM {
    final at = position;
    final office = nearestOffice;
    if (at == null || office == null) return null;
    return math.max(0, office.distanceToEdgeM(at));
  }

  static const Object _keep = Object();

  WorkAreaState copyWith({
    bool? loadingOffices,
    List<WorkOffice>? offices,
    Object? officesError = _keep,
    LocationAccess? access,
    LatLng? position,
    double? accuracyM,
    DateTime? positionAt,
    bool? spoofed,
    bool? refreshing,
    DateTime? refreshedAt,
    bool? refreshFailed,
    bool clearPosition = false,
  }) {
    return WorkAreaState(
      loadingOffices: loadingOffices ?? this.loadingOffices,
      offices: offices ?? this.offices,
      officesError: identical(officesError, _keep)
          ? this.officesError
          : officesError as String?,
      access: access ?? this.access,
      position: clearPosition ? null : position ?? this.position,
      accuracyM: clearPosition ? null : accuracyM ?? this.accuracyM,
      positionAt: clearPosition ? null : positionAt ?? this.positionAt,
      spoofed: spoofed ?? this.spoofed,
      refreshing: refreshing ?? this.refreshing,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      refreshFailed: refreshFailed ?? this.refreshFailed,
    );
  }

  @override
  List<Object?> get props => [
    loadingOffices,
    offices,
    officesError,
    access,
    position,
    accuracyM,
    positionAt,
    spoofed,
    refreshing,
    refreshedAt,
    refreshFailed,
  ];
}
