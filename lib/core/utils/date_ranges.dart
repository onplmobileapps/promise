import 'package:intl/intl.dart';

/// A run of days written short: "6 Oct", "6 – 7 Oct", "30 Oct – 2 Nov", or
/// with the years when they differ.
String formatDayRange(DateTime start, DateTime end, String locale) {
  final day = DateFormat.d(locale);
  final dayMonth = DateFormat('d MMM', locale);
  final dayMonthYear = DateFormat('d MMM y', locale);
  if (start.year != end.year) {
    return '${dayMonthYear.format(start)} – ${dayMonthYear.format(end)}';
  }
  if (start.month != end.month) {
    return '${dayMonth.format(start)} – ${dayMonth.format(end)}';
  }
  if (start.day != end.day) {
    return '${day.format(start)} – ${dayMonth.format(end)}';
  }
  return dayMonth.format(start);
}

/// Whole days from [start] to [end], both counted.
int daysBetweenInclusive(DateTime start, DateTime end) =>
    DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
    1;
