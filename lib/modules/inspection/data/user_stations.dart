import 'dart:convert';

import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The stations the employee inspects, kept from the last time they came,
/// so an inspection can be started with no connection.
abstract final class UserStations {
  static const String _key = 'inspection_user_stations';

  /// The employee's stations of [section]: the server's, or those kept
  /// when it can't be reached, with why it couldn't.
  static Future<({List<StationItem> stations, String? error})> load(
    InspectionRepository repository, {
    int? section,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await repository.getUserStations(section: section);
    final failure = result.fold((e) => e, (_) => null);
    if (failure != null) {
      final kept = _kept(prefs.getString(_key));
      return (stations: kept, error: kept.isEmpty ? failure.message : null);
    }
    final stations = result.fold((_) => const <StationItem>[], (s) => s);
    await prefs.setString(
      _key,
      jsonEncode([for (final station in stations) station.toJson()]),
    );
    return (stations: stations, error: null);
  }

  static List<StationItem> _kept(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final json in jsonDecode(raw) as List)
          if (json is Map)
            StationItem.fromJson(Map<String, dynamic>.from(json)),
      ];
    } on Object {
      return const [];
    }
  }
}
