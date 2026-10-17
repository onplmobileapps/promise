import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/models/login_response.dart';

/// The kinds of inspection, in the order they are offered.
enum InspectionKind { footplate, station, motorTrolley, locomotive, electrical }

/// One kind of inspection's share of the month: how many are to be done,
/// how many are, and how many were left over from last month.
@immutable
class InspectionQuota {
  const InspectionQuota({
    required this.kind,
    required this.done,
    required this.total,
    this.overdue = 0,
  });

  final InspectionKind kind;
  final int done;

  /// How many the month's plan asks for; none when there is no plan.
  final int total;

  /// Short of last month's plan.
  final int overdue;
}

/// How many of each kind of inspection an officer is to make a month, by
/// designation, as the schedules of safety, operation and maintenance
/// inspections set them: the mechanical department's (Annexure-A), the
/// signal cadre's footplate quotas, and the electrical proformas'
/// frequencies. A designation not listed has no monthly plan.
const Map<String, Map<InspectionKind, int>> kMonthlyPlan = {
  // 4 footplates, 20 locomotives and the shed.
  'DME': {InspectionKind.footplate: 4, InspectionKind.locomotive: 21},
  // 4 footplates, 25 locomotives and the shed.
  'AME': {InspectionKind.footplate: 4, InspectionKind.locomotive: 26},
  'WM': {InspectionKind.locomotive: 20},
  'AWM': {InspectionKind.locomotive: 25},
  // 2 night and 1 day footplates.
  'DSTE': {InspectionKind.footplate: 3},
  'DASE': {InspectionKind.footplate: 3},
  'ASE': {InspectionKind.footplate: 3},
  // 1 night and 1 day footplate.
  'SI': {InspectionKind.footplate: 2},
  // Train lighting twice a month and power every 15 days.
  'EFO': {InspectionKind.electrical: 4},
  'DEFO': {InspectionKind.electrical: 4},
  // Train lighting daily, on working days.
  'AEFO': {InspectionKind.electrical: 26},
  // Train lighting weekly and power monthly.
  'AEE': {InspectionKind.electrical: 5},
  // Train lighting twice a month.
  'DEE': {InspectionKind.electrical: 2},
  'DAEE': {InspectionKind.electrical: 2},
  'SEE': {InspectionKind.electrical: 2},
  // Train lighting monthly.
  'DY_CEE': {InspectionKind.electrical: 1},
};

/// The plan's name for [user]'s designation, as "AME" for "AME / Loco".
@visibleForTesting
String? planDesignation(User? user) {
  final words = [
    for (final word in (user?.designation ?? '').toUpperCase().split(
      RegExp('[^A-Z0-9]+'),
    ))
      if (word.isNotEmpty) word,
  ];
  if (words.contains('DY') && words.contains('CEE')) return 'DY_CEE';
  if (words.contains('SIGNAL') && words.contains('INSPECTOR')) return 'SI';
  if (words.contains('FOREMAN') || words.contains('SUB')) return 'EFO';
  for (final word in words) {
    if (kMonthlyPlan.containsKey(word)) return word;
  }
  return null;
}

/// [user]'s month to [now]: each kind's plan, those made this month by
/// [kindOf] the records finished on this phone, and last month's
/// shortfall, if the phone was inspected with last month at all. Kinds
/// with no plan and none made are left out.
List<InspectionQuota> monthlyPlan(
  User? user,
  List<Map<String, dynamic>> records,
  DateTime now, {
  required InspectionKind? Function(Map<String, dynamic> record) kindOf,
}) {
  final plan = kMonthlyPlan[planDesignation(user)] ?? const {};
  final thisMonth = <InspectionKind, int>{};
  final lastMonth = <InspectionKind, int>{};
  final previous = DateTime(now.year, now.month - 1);
  for (final record in records) {
    if (record['status'] case 'in_progress' || null) continue;
    final day = DateTime.tryParse(record['date']?.toString() ?? '');
    final kind = kindOf(record);
    if (day == null || kind == null) continue;
    if (day.year == now.year && day.month == now.month) {
      thisMonth[kind] = (thisMonth[kind] ?? 0) + 1;
    } else if (day.year == previous.year && day.month == previous.month) {
      lastMonth[kind] = (lastMonth[kind] ?? 0) + 1;
    }
  }
  final usedLastMonth = lastMonth.isNotEmpty;
  return [
    for (final kind in InspectionKind.values)
      if ((plan[kind] ?? 0) > 0 || (thisMonth[kind] ?? 0) > 0)
        InspectionQuota(
          kind: kind,
          done: thisMonth[kind] ?? 0,
          total: plan[kind] ?? 0,
          overdue: usedLastMonth
              ? ((plan[kind] ?? 0) - (lastMonth[kind] ?? 0)).clamp(
                  0,
                  plan[kind] ?? 0,
                )
              : 0,
        ),
  ];
}
