import 'package:intl/intl.dart';

/// An attendance time from the server, which sends either a full timestamp
/// or just a time of day ("09:05:00", "2026-10-02 09:05:00"); null when
/// there isn't one. A bare time is placed [on] that day, today by default.
DateTime? parseAttendanceTime(String? raw, {DateTime? on}) {
  var value = raw?.trim() ?? '';
  if (value.isEmpty || value == 'null' || value.startsWith('--')) return null;
  final full = DateTime.tryParse(value);
  if (full != null) return full.toLocal();
  // "02:15 PM" is in the afternoon; the marker goes before the time is read.
  final upper = value.toUpperCase();
  final afternoon = upper.endsWith('PM');
  final morning = upper.endsWith('AM');
  if (afternoon || morning) value = value.substring(0, value.length - 2).trim();
  final time = value.split(' ').last.split(':');
  if (time.length < 2) return null;
  int? part(String text) => int.tryParse(text.replaceAll(RegExp('[^0-9]'), ''));
  var hour = part(time[0]);
  final minute = part(time[1]);
  final second = time.length > 2 ? part(time[2]) ?? 0 : 0;
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  if (afternoon && hour < 12) hour += 12;
  if (morning && hour == 12) hour = 0;
  final day = on ?? DateTime.now();
  return DateTime(day.year, day.month, day.day, hour, minute, second);
}

/// "09:05 AM", or "--:--" when there is no time.
String formatAttendanceTime(String? raw) {
  final time = parseAttendanceTime(raw);
  return time == null ? '--:--' : DateFormat('hh:mm a').format(time);
}

/// A day as the attendance API writes it: "2026-10-05".
String apiDay(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
