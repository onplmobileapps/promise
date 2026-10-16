import 'package:railway_hrms/app/notifications/app_alert.dart';

/// Sample alerts, shown until alerts come from the server: the life of one
/// accident case, timed back from [now].
List<AppAlert> demoAlerts(DateTime now) => [
  AppAlert(
    id: 'accident-reported',
    kind: AlertKind.accident,
    signal: AlertSignal.alarm,
    title: 'ACCIDENT REPORTED — 1UP Khyber Mail',
    body:
        'Major severity Derailment reported for 1UP Khyber Mail (Loco 6012). '
        'Location: KM 1280/04 past Lahore Junction on 13-Aug-2026 at 17:15.',
    receivedAt: now.subtract(const Duration(minutes: 2)),
    unread: true,
    caseStage: 2,
  ),
  AppAlert(
    id: 'accident-acknowledged',
    kind: AlertKind.accident,
    signal: AlertSignal.done,
    title: 'Accident Acknowledgement',
    body: '1UP Khyber Mail accident acknowledged by COPS.',
    receivedAt: now.subtract(const Duration(hours: 14)),
  ),
  AppAlert(
    id: 'relief-dispatched',
    kind: AlertKind.accident,
    signal: AlertSignal.progress,
    title: 'Relief Train Dispatched',
    body: 'Relief train dispatched for 1UP Khyber Mail.',
    receivedAt: now.subtract(const Duration(hours: 14, minutes: 5)),
  ),
  AppAlert(
    id: 'relief-reached',
    kind: AlertKind.accident,
    signal: AlertSignal.done,
    title: 'Relief Train Reached On Site',
    body:
        'Relief train reached at KM 1280/04 (Loco 6012 / 1UP Khyber Mail). '
        'Track clearance started.',
    receivedAt: now.subtract(const Duration(hours: 14, minutes: 10)),
  ),
  AppAlert(
    id: 'site-cleared',
    kind: AlertKind.accident,
    signal: AlertSignal.done,
    title: 'SITE CLEARED — KM 1280/04',
    body:
        'Track cleared and declared fit for 1UP Khyber Mail. '
        'Operations resumed.',
    receivedAt: now.subtract(const Duration(hours: 14, minutes: 15)),
  ),
];
