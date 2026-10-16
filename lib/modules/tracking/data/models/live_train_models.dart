import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/utils/equatable.dart';

/// Traccar reports speed in knots.
const double kKnotsToKmh = 1.852;

/// A fix up to this far ahead of the server's clock is taken as it is.
const Duration _clockSkewAllowed = Duration(minutes: 5);

LatLng? _parseLatLng(Object? lat, Object? lng) {
  final la = double.tryParse('${lat ?? ''}');
  final lo = double.tryParse('${lng ?? ''}');
  if (la == null || lo == null || !la.isFinite || !lo.isFinite) return null;
  if (la.abs() > 90 || lo.abs() > 180 || (la == 0 && lo == 0)) return null;
  return LatLng(la, lo);
}

int? _parseInt(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

/// A station on a train's journey. [position] is null when the API has no
/// coordinates for it.
class TrainStation extends Equatable {
  final int? id;
  final String name;
  final String? code;
  final LatLng? position;

  /// Scheduled times ("HH:mm:ss"), only for stops from a schedule.
  final String? arrivalTime;
  final String? departureTime;

  const TrainStation({
    this.id,
    required this.name,
    this.code,
    this.position,
    this.arrivalTime,
    this.departureTime,
  });

  /// `{"id", "name", "station_code", "line", "latitude", "longitude"}`;
  /// coordinates arrive as strings and may be null.
  static TrainStation? fromJson(Object? json, {Map<String, dynamic>? stop}) {
    if (json is! Map<String, dynamic>) return null;
    final stationMap = json['station'] is Map<String, dynamic>
        ? json['station'] as Map<String, dynamic>
        : json;
    final code =
        (stationMap['station_code'] ??
                stationMap['code'] ??
                json['station_code'])
            as String?;
    final name = (stationMap['name'] ?? json['name']) as String?;
    if ((name == null || name.trim().isEmpty) &&
        (code == null || code.trim().isEmpty)) {
      return null;
    }
    final arrTime =
        (json['arrival_time'] ?? stop?['arrival_time'] ?? json['arrival'])
            as String?;
    final depTime =
        (json['departure_time'] ?? stop?['departure_time'] ?? json['departure'])
            as String?;
    final lat = stationMap['latitude'] ?? json['latitude'] ?? stop?['latitude'];
    final lng =
        stationMap['longitude'] ?? json['longitude'] ?? stop?['longitude'];
    return TrainStation(
      id: _parseInt(stationMap['id'] ?? json['id']),
      name: (name == null || name.trim().isEmpty) ? code!.trim() : name.trim(),
      code: (code == null || code.trim().isEmpty) ? null : code.trim(),
      position: _parseLatLng(lat, lng),
      arrivalTime: arrTime,
      departureTime: depTime,
    );
  }

  /// A page of `tracking/station/`: a list, or an object wrapping it in
  /// `results` (with the `next` page's URL) or `data`.
  static (List<TrainStation>, String?) parsePage(Object? data) {
    var list = const <Object?>[];
    String? next;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final items = data['results'] ?? data['data'] ?? data['stations'];
      if (items is List) list = items;
      final more = data['next'];
      if (more is String && more.isNotEmpty) next = more;
    }
    return ([for (final item in list) ?TrainStation.fromJson(item)], next);
  }

  bool isSameStation(TrainStation other) =>
      (id != null && id == other.id) || (code != null && code == other.code);

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    position,
    arrivalTime,
    departureTime,
  ];
}

/// One train running today, as returned by `tracking/mobile/`.
class LiveTrain extends Equatable {
  /// Id of today's running record (unique per run).
  final String id;
  final String name;
  final int? number;

  /// 1 = UP, 2 = DN.
  final int? direction;
  final int? deviceId;
  final TrainStation? origin;
  final TrainStation? destination;

  /// Intermediate stops, when the API provides a schedule.
  final List<TrainStation> stops;
  final String? date;

  /// When the train was dispatched on this run, from the run's detail.
  final DateTime? dispatchedAt;

  /// Its locomotives, "9015 GEU40", from the run's detail.
  final List<String> locomotives;

  /// Which timetable it runs to, "WINTER", from the run's detail.
  final String? season;

  const LiveTrain({
    required this.id,
    required this.name,
    this.number,
    this.direction,
    this.deviceId,
    this.origin,
    this.destination,
    this.stops = const [],
    this.date,
    this.dispatchedAt,
    this.locomotives = const [],
    this.season,
  });

  bool get hasDevice => (deviceId ?? 0) > 0;

  /// The day this run left, from the API's `effective_date`.
  DateTime? get runDate {
    final parsed = DateTime.tryParse(date ?? '');
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// What runs of the same train share: its number and direction, or its
  /// name. A train that takes more than a day is on the move twice at once
  /// under one key, once for each day it left on.
  String get serviceKey => number != null
      ? '$number-${direction ?? 0}'
      : 'name:${name.trim().toLowerCase()}';

  /// Orders runs of a train with the latest departure first.
  static int byLatestRun(LiveTrain a, LiveTrain b) {
    final da = a.runDate;
    final db = b.runDate;
    if (da != null && db != null && da != db) return db.compareTo(da);
    if (da == null && db != null) return 1;
    if (db == null && da != null) return -1;
    return a.id.compareTo(b.id);
  }

  bool get isUp => direction == 1;
  bool get isDown => direction == 2;
  String get directionLabel => isUp ? 'UP' : (isDown ? 'DN' : '');

  /// Unnamed trains come back with the code as their name ("267-UP").
  String get displayName {
    final codeOnly = RegExp(r'^\d+\s*-?\s*(UP|DN)?$', caseSensitive: false);
    if (name.isEmpty || codeOnly.hasMatch(name)) {
      return number != null ? 'Train $number' : 'Train';
    }
    return name;
  }

  /// "48-DN"
  String get code => [
    if (number != null) '$number',
    if (directionLabel.isNotEmpty) directionLabel,
  ].join('-');

  /// Origin, stops and destination in travel order.
  List<TrainStation> get journey => [?origin, ...stops, ?destination];

  bool get hasRoute => origin != null || destination != null;

  String get routeLabel => hasRoute
      ? '${origin?.name ?? 'Unknown'} → ${destination?.name ?? 'Unknown'}'
      : 'Route not assigned';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      code,
      '${number ?? ''}',
      origin?.name ?? '',
      origin?.code ?? '',
      destination?.name ?? '',
      destination?.code ?? '',
    ].any((s) => s.toLowerCase().contains(q));
  }

  factory LiveTrain.fromJson(Map<String, dynamic> json) {
    final train = json['train'] is Map<String, dynamic>
        ? json['train'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final origin =
        TrainStation.fromJson(json['origin_station']) ??
        TrainStation.fromJson(train['origin_station']);
    final destination =
        TrainStation.fromJson(json['destination_station']) ??
        TrainStation.fromJson(train['destination_station']);

    final schedule = train['schedule'] ?? json['schedule'];
    final rawStops =
        json['stops'] ??
        json['stoppages'] ??
        (schedule is Map<String, dynamic> ? schedule['stops'] : null) ??
        train['stops'] ??
        train['stoppages'];

    final stopsJson =
        <Map<String, dynamic>>[
          if (rawStops is List) ...rawStops.whereType<Map<String, dynamic>>(),
        ]..sort(
          (a, b) =>
              (_parseInt(a['sequence_no'] ?? a['seq_no'] ?? a['order']) ?? 0)
                  .compareTo(
                    _parseInt(b['sequence_no'] ?? b['seq_no'] ?? b['order']) ??
                        0,
                  ),
        );

    final stops = <TrainStation>[
      for (final stop in stopsJson)
        if (TrainStation.fromJson(stop['station'] ?? stop, stop: stop)
            case final station?)
          if (!(origin?.isSameStation(station) ?? false) &&
              !(destination?.isSameStation(station) ?? false))
            station,
    ];

    final deviceId = _parseInt(json['device_id'] ?? train['device_id']);
    final rawName =
        train['name'] ??
        train['train_name'] ??
        json['train_name'] ??
        json['name'] ??
        '';

    return LiveTrain(
      id: '${json['id'] ?? train['id'] ?? ''}',
      name: (rawName as String).trim(),
      number: _parseInt(train['train_no'] ?? json['train_no']),
      direction: _parseInt(json['direction'] ?? train['direction']),
      deviceId: (deviceId ?? 0) > 0 ? deviceId : null,
      origin: origin,
      destination: destination,
      stops: stops,
      date: (json['effective_date'] ?? json['date']) as String?,
      dispatchedAt: switch (json['dispatch']) {
        {'dispatch_time': final String at} => DateTime.tryParse(at)?.toLocal(),
        _ => null,
      },
      locomotives: [
        if (json['formations'] case final List<Object?> formations)
          for (final formation in formations)
            if (formation case {
              'assigned_locomotives': final List<Object?> assigned,
            })
              for (final entry in assigned)
                if (entry case {'locomotive': final Map<String, dynamic> loco})
                  [
                    '${loco['de_loco_no'] ?? ''}'.trim(),
                    if (loco['class_type'] case {'name': final String kind})
                      kind.trim(),
                  ].where((part) => part.isNotEmpty).join(' '),
      ].where((loco) => loco.isNotEmpty).toList(),
      season: switch (schedule) {
        {'season': final String season} when season.trim().isNotEmpty =>
          season.trim(),
        _ => null,
      },
    );
  }

  /// Accepts a list, or an object wrapping it in `data` / `results`.
  static List<LiveTrain> parseList(Object? data) {
    final list = data is List
        ? data
        : data is Map<String, dynamic>
        ? (data['data'] ?? data['results']) as List? ?? const []
        : const [];
    final trains = <LiveTrain>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        trains.add(LiveTrain.fromJson(item));
      } catch (_) {
        // One malformed record must not hide the others.
      }
    }
    trains.sort((a, b) => (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30));
    return trains;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    number,
    direction,
    deviceId,
    origin,
    destination,
    stops,
    date,
    dispatchedAt,
    locomotives,
    season,
  ];
}

/// A position report from the tracking WebSocket (Traccar format).
class TrainPosition extends Equatable {
  final int deviceId;
  final LatLng position;
  final double speedKmh;

  /// Heading in degrees clockwise from north.
  final double course;
  final bool moving;

  /// False when the device had no GPS fix; [position] is then the last one
  /// it knew.
  final bool validFix;
  final DateTime fixTime;

  /// Nearest place, e.g. "Odero Lal Station, Matiari Taluka, …".
  final String? address;

  /// How long the train has been standing, when it is stopped.
  final Duration? stoppedFor;

  const TrainPosition({
    required this.deviceId,
    required this.position,
    required this.speedKmh,
    required this.course,
    required this.moving,
    required this.validFix,
    required this.fixTime,
    this.address,
    this.stoppedFor,
  });

  static TrainPosition? fromJson(
    Map<String, dynamic> json, {
    int? fallbackDeviceId,
  }) {
    final deviceId =
        _parseInt(json['deviceId']) ??
        _parseInt(json['device_id']) ??
        _parseInt(json['device']) ??
        fallbackDeviceId;
    final position = _parseLatLng(
      json['latitude'] ?? json['lat'],
      json['longitude'] ?? json['lng'] ?? json['lon'],
    );
    if (deviceId == null || position == null) return null;
    final attributes = json['attributes'] is Map<String, dynamic>
        ? json['attributes'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawSpeed =
        (json['speed'] as num?)?.toDouble() ??
        (attributes['speed'] as num?)?.toDouble() ??
        0.0;
    final speedKmh = rawSpeed * kKnotsToKmh;
    final motion = attributes['motion'] ?? json['motion'];
    final parking = attributes['parking'] == true;
    final deviceStatus = attributes['deviceStatus']?.toString();
    final validFix = json['valid'] != false && json['outdated'] != true;
    final moving =
        parking ||
            deviceStatus == 'offline' ||
            (motion is bool && !motion) ||
            !validFix
        ? false
        : true;

    final address =
        (json['address'] as String?)?.trim() ??
        (attributes['address'] as String?)?.trim();

    final stopMs = attributes['stopTime'] ?? json['stopTime'];
    final serverTime = DateTime.tryParse('${json['serverTime'] ?? ''}');
    var fixTime =
        DateTime.tryParse(
          '${json['fixTime'] ?? json['deviceTime'] ?? json['serverTime'] ?? json['timestamp'] ?? ''}',
        ) ??
        serverTime ??
        DateTime.now();
    // Some devices' clocks run days ahead; such a fix would look fresh for
    // days. The server's clock says when it really came in.
    if (serverTime != null &&
        fixTime.isAfter(serverTime.add(_clockSkewAllowed))) {
      fixTime = serverTime;
    }
    return TrainPosition(
      deviceId: deviceId,
      position: position,
      speedKmh: speedKmh,
      course:
          (json['course'] as num?)?.toDouble() ??
          (json['bearing'] as num?)?.toDouble() ??
          0.0,
      moving: moving,
      validFix: validFix,
      fixTime: fixTime.toLocal(),
      address: address,
      stoppedFor: !moving && stopMs is num && stopMs > 0
          ? Duration(milliseconds: stopMs.toInt())
          : null,
    );
  }

  /// First two parts of [address]: "Odero Lal Station, Matiari Taluka".
  String? get shortAddress {
    final parts = (address ?? '')
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  List<Object?> get props => [
    deviceId,
    position,
    speedKmh,
    course,
    moving,
    validFix,
    fixTime,
    address,
    stoppedFor,
  ];
}
