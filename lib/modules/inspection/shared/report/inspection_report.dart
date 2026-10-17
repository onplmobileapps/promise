import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';

/// How an answer on a report reads at a glance.
enum ReportTone {
  /// In order: yes, working, satisfactory.
  good,

  /// Wrong: no, faulty, out of limit.
  bad,

  /// Neither, as a reading or a name.
  plain,

  /// Left blank.
  missing;

  static final RegExp _bad = RegExp(
    r'\b(no|not|non|unsatisfactory|faulty|defective|poor|bad|broken|damaged|'
    r'incomplete|overdue|'
    r'missing|out of (limit|order)|fail(ed)?|leak(ing)?|worn|nil|absent|'
    r'unavailable|not available|not working|non-functional|inoperative)\b',
    caseSensitive: false,
  );
  static final RegExp _good = RegExp(
    r'^(yes|ok|okay|good|satisfactory|functional|working|available|fine|'
    r'normal|clean|intact|present|done|pass(ed)?|within limit|in order|'
    r'excellent|prime|complete)$',
    caseSensitive: false,
  );

  /// The tone [value] reads in.
  static ReportTone of(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text == '—') return missing;
    if (_good.hasMatch(text)) return good;
    if (_bad.hasMatch(text)) return bad;
    return plain;
  }
}

/// One answer on a report: a question and what was found, in the [tone]
/// it reads in, from the value unless given.
@immutable
class ReportRow {
  ReportRow(this.label, String? value, {ReportTone? tone})
    : value = value?.trim() ?? '',
      tone = tone ?? ReportTone.of(value);

  final String label;
  final String value;
  final ReportTone tone;

  bool get answered => value.isNotEmpty;
}

/// A part of a report, as a form's section: its answers, a note, and the
/// photos taken for it.
@immutable
class ReportSection {
  const ReportSection({
    required this.title,
    this.rows = const [],
    this.note,
    this.photos = const [],
    this.step,
  });

  final String title;
  final List<ReportRow> rows;

  /// The form's step its answers are given on, counted from 0, so a tap
  /// on one of them opens it to change; the step of the same title if
  /// not given.
  final int? step;

  /// Free text written for the section, such as remarks.
  final String? note;

  /// Paths of the section's photos, as the forms store them.
  final List<String> photos;

  bool get isEmpty =>
      rows.isEmpty && (note?.trim().isEmpty ?? true) && photos.isEmpty;
}

/// An inspection as it is read before it is submitted, and as its PDF is
/// drawn: what was inspected, by whom and when, every section's answers,
/// and the face checks it is signed with.
@immutable
class InspectionReport {
  const InspectionReport({
    required this.title,
    required this.date,
    this.subtitle,
    this.facts = const [],
    this.sections = const [],
    this.inspector,
    this.signatures = const InspectionSignatures(),
  });

  /// The kind of inspection, as "Station inspection".
  final String title;

  /// What was inspected, as a station's or a train's name.
  final String? subtitle;
  final DateTime date;

  /// The key facts at the top, as the station, section or train.
  final List<ReportRow> facts;
  final List<ReportSection> sections;

  /// Who inspected, as their name and designation.
  final String? inspector;
  final InspectionSignatures signatures;

  /// Questions left blank.
  int get unanswered => sections.fold(
    0,
    (sum, section) => sum + section.rows.where((row) => !row.answered).length,
  );

  /// Answers that read as something wrong.
  int get findings => sections.fold(
    0,
    (sum, section) =>
        sum + section.rows.where((row) => row.tone == ReportTone.bad).length,
  );

  InspectionReport copyWith({
    String? inspector,
    InspectionSignatures? signatures,
  }) => InspectionReport(
    title: title,
    subtitle: subtitle,
    date: date,
    facts: facts,
    sections: sections,
    inspector: inspector ?? this.inspector,
    signatures: signatures ?? this.signatures,
  );
}

/// A section's rows from answers kept by key, as most forms keep them:
/// [fields] in order, labelled, with what [values] holds for each.
List<ReportRow> rowsOf(
  Iterable<({String key, String label})> fields,
  Map<String, Object?> values,
) => [
  for (final field in fields)
    ReportRow(field.label, displayValue(values[field.key])),
];

/// How a stored answer reads on a report: booleans as Yes/No, lists
/// joined, dates as dates.
String displayValue(Object? value) => switch (value) {
  null => '',
  true => 'Yes',
  false => 'No',
  final DateTime at =>
    '${at.day.toString().padLeft(2, '0')}/'
        '${at.month.toString().padLeft(2, '0')}/${at.year}',
  final Iterable<Object?> list =>
    list.map(displayValue).where((v) => v.isNotEmpty).join(', '),
  final Map<Object?, Object?> map =>
    map.entries
        .where((e) => displayValue(e.value).isNotEmpty)
        .map((e) => '${e.key}: ${displayValue(e.value)}')
        .join(', '),
  _ => value.toString().trim(),
};
