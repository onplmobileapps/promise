import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';

void main() {
  // 42-DN Karakoram Express, as `tracking/mobile/2108/` sends it: due out of
  // Lahore at 15:00, dispatched at 21:54.
  final detail = {
    'id': 2108,
    'device_id': 2788,
    'effective_date': '2026-10-17',
    'train': {'name': 'Karakoram Express', 'train_no': 42, 'direction': 2},
    'origin_station': {
      'id': 1174,
      'name': 'Lahore Jn',
      'latitude': '31.58',
      'longitude': '74.34',
    },
    'destination_station': {
      'id': 1057,
      'name': 'Karachi Cantt',
      'latitude': '24.84',
      'longitude': '67.04',
    },
    'dispatch': {'dispatch_time': '2026-10-17T21:54:34+05:00'},
    'schedule': {
      'stops': [
        {
          'sequence_no': 1,
          'station': {
            'id': 1174,
            'name': 'Lahore Jn',
            'latitude': '31.58',
            'longitude': '74.34',
          },
          'departure_time': '15:00:00',
          'is_stoppage': false,
        },
        {
          'sequence_no': 2,
          'station': {
            'id': 1541,
            'name': 'Qila Sheikhupura',
            'latitude': '31.71',
            'longitude': '73.98',
          },
          'departure_time': '15:38:00',
          'is_stoppage': false,
        },
        {
          'sequence_no': 3,
          'station': {
            'id': 1300,
            'name': 'Faisalabad',
            'latitude': '31.42',
            'longitude': '73.08',
          },
          'arrival_time': '17:10:00',
          'departure_time': '17:15:00',
          'is_stoppage': true,
        },
        {
          'sequence_no': 4,
          'station': {
            'id': 1057,
            'name': 'Karachi Cantt',
            'latitude': '24.84',
            'longitude': '67.04',
          },
          'arrival_time': '07:30:00',
          'is_stoppage': true,
        },
      ],
    },
  };

  test('a detail keeps every station\'s times and whether it stops', () {
    final train = LiveTrain.fromJson(detail);
    expect(train.origin!.departureTime, '15:00:00');
    expect(train.destination!.arrivalTime, '07:30:00');
    expect(train.stops.map((s) => s.halts), [false, true]);
    // Due out on the day it was dispatched, hours late.
    expect(train.departureDay, DateTime(2026, 10, 17));
  });

  test('delay: where the train is against where the timetable has it', () {
    final train = LiveTrain.fromJson(detail);
    final stops = [
      for (final (i, s) in train.journey.indexed) RouteStop(s, i * 100.0),
    ];
    final due = timetableOf(stops, train.departureDay);
    // Past midnight, the timetable runs on into the next day.
    expect(due.last, DateTime(2026, 10, 18, 7, 30));

    // Halfway from Qila Sheikhupura (due 15:38) to Faisalabad (17:10): due
    // there at 16:24. Reported there at 18:54: 2 h 30 min late.
    final late = delayAtPosition(
      stops,
      due,
      150,
      DateTime(2026, 10, 17, 18, 54),
    );
    expect(delayLabel(late!), '2 h 30 min late');

    // Seen at Qila Sheikhupura at 16:00, after it was due out of Lahore.
    final reached = reachedAt(
      stops,
      [
        (DateTime(2026, 10, 17, 14, 0), const LatLng(31.712, 73.981)),
        (DateTime(2026, 10, 17, 16, 0), const LatLng(31.712, 73.981)),
      ],
      since: DateTime(2026, 10, 17, 14, 30),
    );
    // The report before the journey began doesn't count.
    expect(reached[1], DateTime(2026, 10, 17, 16, 0));
    // The dispatch, entered at 21:54, isn't taken for leaving Lahore.
    expect(reached[0], isNull);
    expect(delayLabel(delayNow(due, reached)!), '22 min late');
  });

  test('delay in words', () {
    expect(delayLabel(const Duration(minutes: 1)), 'On time');
    expect(delayLabel(const Duration(minutes: 12)), '12 min late');
    expect(delayLabel(const Duration(minutes: -5)), '5 min early');
    expect(delayLabel(const Duration(hours: 2)), '2 h late');
  });
}
