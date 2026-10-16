import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

/// Where and when a GPS device reported.
typedef TrackFix = (DateTime time, LatLng at);

/// Keeps the day's GPS reports on the phone, so that when tracking is
/// opened again the stations a train passed while it was last open still
/// show when it passed them. Only what a station's time needs is kept —
/// when and where — and nothing older than [keep]. Reading and writing run
/// off the UI isolate, so a long day's reports never stall the map.
class TrackHistoryStore {
  TrackHistoryStore({
    Future<Directory> Function()? directory,
    this.keep = const Duration(hours: 30),
  }) : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  /// Reports older than this are dropped.
  final Duration keep;

  static const String _file = 'train_history.json';

  Future<File> _path() async => File('${(await _directory()).path}/$_file');

  /// The reports kept, by device; empty when there are none or they can't
  /// be read.
  Future<Map<int, List<TrackFix>>> load({DateTime? now}) async {
    try {
      final file = await _path();
      if (!await file.exists()) return {};
      final since = (now ?? DateTime.now()).subtract(keep);
      final rows = await Isolate.run(() => _read(file.path));
      return {
        for (final MapEntry(key: device, value: fixes) in rows.entries)
          if (_since(fixes, since) case final kept when kept.isNotEmpty)
            device: kept,
      };
    } catch (e) {
      debugPrint('⚠️ Train history unreadable: $e');
      return {};
    }
  }

  /// Keeps [history], the reports of the last [keep] only.
  Future<void> save(Map<int, List<TrackFix>> history, {DateTime? now}) async {
    try {
      final since = (now ?? DateTime.now()).subtract(keep);
      final rows = <String, List<List<num>>>{
        for (final MapEntry(key: device, value: fixes) in history.entries)
          if (_since(fixes, since) case final kept when kept.isNotEmpty)
            '$device': [
              for (final (time, at) in kept)
                [time.millisecondsSinceEpoch, at.latitude, at.longitude],
            ],
      };
      final file = await _path();
      await Isolate.run(() => _write(file.path, rows));
    } catch (e) {
      debugPrint('⚠️ Train history not saved: $e');
    }
  }

  static List<TrackFix> _since(List<TrackFix> fixes, DateTime since) => [
    for (final fix in fixes)
      if (!fix.$1.isBefore(since)) fix,
  ];

  static Map<int, List<TrackFix>> _read(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! Map<String, dynamic>) return {};
    final devices = decoded['devices'];
    if (devices is! Map<String, dynamic>) return {};
    final out = <int, List<TrackFix>>{};
    for (final MapEntry(key: key, value: rows) in devices.entries) {
      final device = int.tryParse(key);
      if (device == null || rows is! List) continue;
      final fixes = <TrackFix>[];
      for (final row in rows) {
        if (row is! List || row.length < 3) continue;
        final ms = row[0];
        final lat = row[1];
        final lng = row[2];
        if (ms is! num || lat is! num || lng is! num) continue;
        fixes.add((
          DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
          LatLng(lat.toDouble(), lng.toDouble()),
        ));
      }
      if (fixes.isNotEmpty) out[device] = fixes;
    }
    return out;
  }

  static void _write(String path, Map<String, List<List<num>>> rows) {
    final file = File(path);
    final temporary = File('$path.tmp');
    // Written aside and moved into place, so a crash mid-write never
    // leaves a broken file behind.
    temporary.writeAsStringSync(jsonEncode({'v': 1, 'devices': rows}));
    temporary.renameSync(file.path);
  }
}
