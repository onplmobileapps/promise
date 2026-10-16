import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:railway_hrms/core/utils/date_ranges.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('runs of days are written short', () {
    expect(
      formatDayRange(DateTime(2026, 10, 6), DateTime(2026, 10, 6), 'en'),
      '6 Oct',
    );
    expect(
      formatDayRange(DateTime(2026, 10, 6), DateTime(2026, 10, 7), 'en'),
      '6 – 7 Oct',
    );
    expect(
      formatDayRange(DateTime(2026, 10, 30), DateTime(2026, 11, 2), 'en'),
      '30 Oct – 2 Nov',
    );
    expect(
      formatDayRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2), 'en'),
      '30 Dec 2026 – 2 Jan 2027',
    );
  });

  test('both ends count', () {
    expect(
      daysBetweenInclusive(DateTime(2026, 10, 6), DateTime(2026, 10, 7)),
      2,
    );
    expect(
      daysBetweenInclusive(DateTime(2026, 10, 6), DateTime(2026, 10, 6)),
      1,
    );
    // Across the clocks going back, still whole days.
    expect(
      daysBetweenInclusive(DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
      3,
    );
  });
}
