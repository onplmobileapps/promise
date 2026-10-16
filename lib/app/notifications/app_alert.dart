import 'package:flutter/foundation.dart';

/// What an alert is about, which files it under a filter.
enum AlertKind { accident, leave, attendance }

/// What an alert signals, which decides its mark and tint.
enum AlertSignal {
  /// Something has gone wrong: an accident reported.
  alarm,

  /// Something is under way, like relief on its way.
  progress,

  /// Something is done, like a case acknowledged or cleared.
  done,
}

/// One alert in the alerts list.
@immutable
class AppAlert {
  const AppAlert({
    required this.id,
    required this.kind,
    required this.signal,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.unread = false,
    this.caseStage,
  });

  final String id;
  final AlertKind kind;
  final AlertSignal signal;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool unread;

  /// For an accident that opens a case: how far the case has got, from
  /// reported (0) to cleared (3).
  final int? caseStage;

  bool get opensCase => caseStage != null;

  AppAlert read() => AppAlert(
    id: id,
    kind: kind,
    signal: signal,
    title: title,
    body: body,
    receivedAt: receivedAt,
    caseStage: caseStage,
  );
}
