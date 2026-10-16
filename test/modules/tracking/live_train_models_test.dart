import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';

// Trimmed records in the shape `tracking/mobile/` returns.
final _rehmanBaba = {
  'id': 1377,
  'train': {
    'id': 410,
    'name': 'Rehman Baba Express',
    'train_no': 48,
    'direction': 2,
    'train_type': 2,
    'train_name': '48-DN Rehman Baba Express',
  },
  'effective_date': '2026-10-01',
  'cops_approval_status': 3,
  'device_id': 2524,
  'origin_station': {
    'id': 1242,
    'name': 'Peshawar Cantt',
    'station_code': 'PSC',
    'line': 10,
    'latitude': '34.00',
    'longitude': '71.55',
  },
  'destination_station': {
    'id': 1,
    'name': 'Karachi Cantt',
    'station_code': 'KC',
    'line': 1,
    'latitude': '24.84',
    'longitude': '67.04',
  },
};

final _unnamed = {
  'id': 1347,
  'train': {
    'name': '267-UP',
    'train_no': 267,
    'direction': 1,
    'train_name': '267-UP 267-UP',
  },
  'device_id': null,
  'origin_station': {
    'id': 5,
    'name': 'Rawalpindi',
    'station_code': 'RWP',
    'latitude': '33.60',
    'longitude': '73.05',
  },
  'destination_station': {
    'id': 9,
    'name': 'Havelian',
    'station_code': 'HVN',
    'latitude': null,
    'longitude': null,
  },
};

// A report from the tracking WebSocket (Traccar format).
final _report = {
  'id': 520428338,
  'attributes': {'motion': true, 'stopTime': 0, 'deviceStatus': 'online'},
  'deviceId': 2665,
  'fixTime': '2026-10-01T12:44:23.000+00:00',
  'outdated': false,
  'valid': true,
  'latitude': 29.7279366,
  'longitude': 71.46517,
  'speed': 53.9957,
  'course': 143.0,
  'address': 'Lodhran-Shuajabad Road, Gilawala, Lodhran Tehsil, Punjab',
};

void main() {
  test('parses a running train', () {
    final train = LiveTrain.fromJson(_rehmanBaba);
    expect(train.id, '1377');
    expect(train.displayName, 'Rehman Baba Express');
    expect(train.code, '48-DN');
    expect(train.isDown, isTrue);
    expect(train.deviceId, 2524);
    expect(train.origin!.code, 'PSC');
    expect(train.origin!.position, const LatLng(34.00, 71.55));
    expect(train.journey.map((s) => s.code), ['PSC', 'KC']);
  });

  test('handles unnamed trains, missing devices and coordinates', () {
    final train = LiveTrain.fromJson(_unnamed);
    expect(train.displayName, 'Train 267');
    expect(train.hasDevice, isFalse);
    expect(train.destination!.name, 'Havelian');
    // The API has no coordinates for Havelian, and the app adds none.
    expect(train.destination!.position, isNull);
    final abad = TrainStation.fromJson({
      'name': 'Abad',
      'station_code': 'AAD',
      'latitude': null,
      'longitude': null,
    });
    expect(abad!.position, isNull);
  });

  test('reads schedule stops in order when present', () {
    final train = LiveTrain.fromJson({
      ..._rehmanBaba,
      'train': {
        ...(_rehmanBaba['train'] as Map<String, dynamic>),
        'schedule': {
          'stops': [
            {
              'sequence_no': 2,
              'station': {
                'id': 30,
                'name': 'Multan Cantt',
                'station_code': 'MUL',
              },
              'arrival_time': '09:10:00',
            },
            {
              'sequence_no': 1,
              'station': {'id': 20, 'name': 'Lahore Jn', 'station_code': 'LHR'},
            },
            {
              'sequence_no': 0,
              'station': {'id': 1242, 'name': 'Peshawar Cantt'},
            },
          ],
        },
      },
    });
    // The origin repeated as a stop is dropped; the rest keep their order.
    expect(train.journey.map((s) => s.name), [
      'Peshawar Cantt',
      'Lahore Jn',
      'Multan Cantt',
      'Karachi Cantt',
    ]);
    expect(train.stops.last.arrivalTime, '09:10:00');
  });

  test('reads a page of stations, as a list or wrapped with the next page', () {
    final (plain, none) = TrainStation.parsePage([
      {
        'id': 1,
        'name': 'Rawalpindi',
        'station_code': 'RWP',
        'latitude': '33.60',
        'longitude': '73.05',
      },
      'junk',
    ]);
    expect(plain.single.code, 'RWP');
    expect(plain.single.position, const LatLng(33.60, 73.05));
    expect(none, isNull);

    final (paged, next) = TrainStation.parsePage({
      'count': 2,
      'next': 'https://example.org/stations/?page=2',
      'results': [
        {'id': 2, 'name': 'Multan Cantt', 'station_code': 'MUL'},
      ],
    });
    expect(paged.single.name, 'Multan Cantt');
    expect(next, 'https://example.org/stations/?page=2');
  });

  test('parses a list, skipping malformed records and sorting by number', () {
    final trains = LiveTrain.parseList([_rehmanBaba, 'bad', _unnamed]);
    expect(trains.map((t) => t.number), [48, 267]);
    expect(
      LiveTrain.parseList({
        'data': [_unnamed],
      }),
      hasLength(1),
    );
  });

  test('converts a WebSocket report, with speed from knots to km/h', () {
    final p = TrainPosition.fromJson(_report)!;
    expect(p.deviceId, 2665);
    expect(p.speedKmh, closeTo(100.0, 0.1));
    expect(p.moving, isTrue);
    expect(p.validFix, isTrue);
    expect(p.shortAddress, 'Lodhran-Shuajabad Road, Gilawala');
    expect(p.fixTime.isUtc, isFalse);
  });

  test('flags a report without a GPS fix', () {
    final p = TrainPosition.fromJson({
      ..._report,
      'valid': false,
      'speed': 0.0,
      'attributes': {'motion': false, 'stopTime': 136306000},
    })!;
    expect(p.validFix, isFalse);
    expect(p.moving, isFalse);
    expect(p.stoppedFor, const Duration(milliseconds: 136306000));
  });
}
