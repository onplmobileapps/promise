import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/utils/equatable.dart';

/// An office the employee may mark attendance at: a circle around it, from
/// `organization/getAuthArea`.
class WorkOffice extends Equatable {
  final int id;

  /// The office itself, e.g. "ONE Network".
  final String name;

  /// The unit it belongs to, e.g. "Islamabad".
  final String unit;
  final LatLng center;
  final double radiusM;
  final bool isPrimary;

  const WorkOffice({
    required this.id,
    required this.name,
    required this.unit,
    required this.center,
    required this.radiusM,
    this.isPrimary = false,
  });

  /// "ONE Network, Islamabad".
  String get address =>
      [name, unit].where((s) => s.isNotEmpty).toSet().join(', ');

  /// Metres from [point] to the edge of the area; zero or less inside it.
  double distanceToEdgeM(LatLng point) =>
      distanceMeters(center, point) - radiusM;

  /// Whether [point] is inside the area, allowing [toleranceM] for GPS
  /// error near the edge.
  bool contains(LatLng point, {double toleranceM = 0}) =>
      distanceToEdgeM(point) <= toleranceM;

  /// The point on the area's edge closest to [from].
  LatLng nearestEdgePoint(LatLng from) {
    final d = distanceMeters(center, from);
    if (d < 1) return center;
    final f = radiusM / d;
    return LatLng(
      center.latitude + (from.latitude - center.latitude) * f,
      center.longitude + (from.longitude - center.longitude) * f,
    );
  }

  /// The area's edge as a closed ring of [points].
  List<LatLng> ring({int points = 96}) {
    const earth = 6378137.0;
    final latRad = center.latitude * math.pi / 180;
    return [
      for (var i = 0; i <= points; i++)
        () {
          final a = 2 * math.pi * i / points;
          final dLat = radiusM * math.sin(a) / earth;
          final dLng = radiusM * math.cos(a) / (earth * math.cos(latRad));
          return LatLng(
            center.latitude + dLat * 180 / math.pi,
            center.longitude + dLng * 180 / math.pi,
          );
        }(),
    ];
  }

  /// The active offices in a `getAuthArea` response: a list of employees
  /// with their `offices`, an object with `data` or `offices`, or a bare
  /// office. Entries without coordinates are skipped.
  static List<WorkOffice> parseAuthArea(Object? body) {
    final offices = <WorkOffice>[];
    void visit(Object? node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
      } else if (node is Map) {
        if (node['data'] != null) return visit(node['data']);
        if (node['offices'] is List) return visit(node['offices']);
        final office = _office(node);
        if (office != null) offices.add(office);
      }
    }

    visit(body);
    final seen = <int>{};
    return [
      for (final office in offices)
        if (seen.add(office.id)) office,
    ];
  }

  static WorkOffice? _office(Map<dynamic, dynamic> json) {
    double? number(Object? v) => v is num
        ? v.toDouble()
        : (v is String ? double.tryParse(v.trim()) : null);
    String text(Object? v) {
      final s = v?.toString().trim() ?? '';
      return s == 'null' ? '' : s;
    }

    if (json['is_active'] == false) return null;
    final lat = number(json['latitude'] ?? json['lat']);
    final lng = number(json['longitude'] ?? json['lng'] ?? json['lon']);
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    final radius = number(json['radius']);
    final name = text(json['location_name']);
    final unit = text(json['unit_name'] ?? json['name']);
    return WorkOffice(
      id: number(json['id'])?.toInt() ?? Object.hash(lat, lng),
      name: name.isNotEmpty ? name : (unit.isNotEmpty ? unit : 'Work area'),
      unit: name.isNotEmpty ? unit : '',
      center: LatLng(lat, lng),
      radiusM: radius != null && radius > 0 ? radius : 200,
      isPrimary: json['is_primary'] == true,
    );
  }

  @override
  List<Object?> get props => [id, name, unit, center, radiusM, isPrimary];
}

/// Great-circle distance between two points, in metres.
double distanceMeters(LatLng a, LatLng b) {
  const d2r = math.pi / 180;
  final sLat = math.sin((b.latitude - a.latitude) * d2r / 2);
  final sLng = math.sin((b.longitude - a.longitude) * d2r / 2);
  final h =
      sLat * sLat +
      math.cos(a.latitude * d2r) * math.cos(b.latitude * d2r) * sLng * sLng;
  return 2 * 6371000.0 * math.asin(math.min(1.0, math.sqrt(h)));
}

/// "45 m", "1.2 km", "38 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  if (meters < 10000) return '${(meters / 1000).toStringAsFixed(1)} km';
  return '${(meters / 1000).round()} km';
}
