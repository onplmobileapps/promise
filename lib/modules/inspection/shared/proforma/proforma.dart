import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';

/// An answer a proforma's item can be given: the [code] the server is sent
/// and the [label] the inspector reads, as "O" and "Okay".
@immutable
class ProformaOption {
  const ProformaOption(this.code, [String? label]) : label = label ?? code;

  final String code;
  final String label;
}

/// One check of a proforma, as the paper form has it: a part and what it
/// was found to be, with whatever else the form asks of it.
@immutable
class ProformaItem {
  const ProformaItem(
    this.no,
    this.label, {
    this.options = const [],
    this.faults = const {},
    this.note,
    this.group,
    this.reading = false,
    this.unit,
    this.readingOn = const {},
    this.expiry = false,
    this.causes = const [],
    this.action,
    this.counts = false,
    this.record = false,
    this.recordHint,
    this.checks = const [],
  });

  /// Its number within its section, as the server keys its answer.
  final String no;
  final String label;

  /// The answers to pick from, the first the one that says all is well.
  final List<ProformaOption> options;

  /// The codes of [options] that report something wrong.
  final Set<String> faults;

  /// What it is held to or what to check, as "600–700 KPA".
  final String? note;

  /// The heading it sits under, as "Solar System" over its parts.
  final String? group;

  /// A reading is noted, in [unit]; only once one of [readingOn] is
  /// picked, if any are given.
  final bool reading;
  final String? unit;
  final Set<String> readingOn;

  /// An expiry date is asked, as a fire extinguisher's.
  final bool expiry;

  /// The likely causes asked once it is at fault.
  final List<String> causes;

  /// What is to be done once it is at fault.
  final String? action;

  /// How many are okay, defective and missing.
  final bool counts;

  /// What is written down of it, as a coach's number and class.
  final bool record;
  final String? recordHint;

  /// Yes or no questions asked of it side by side, as whether a record is
  /// available, updated and correct.
  final List<String> checks;

  bool isFault(Object? code) => faults.contains(code);

  /// Whether [option] says there is nothing here to inspect, as "N/A".
  static bool inapplicable(ProformaOption option) =>
      option.code == 'NA' ||
      RegExp(
        r'^not (available|applicable)$',
        caseSensitive: false,
      ).hasMatch(option.label);

  String? labelOf(Object? code) {
    for (final option in options) {
      if (option.code == code) return option.label;
    }
    return code?.toString();
  }

  /// Its answer's key for each yes or no question.
  static String checkKey(String check) =>
      check.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
}

/// A part of a proforma: the items under one heading, as "Driver Cab".
@immutable
class ProformaSection {
  const ProformaSection(this.key, this.title, this.items, {this.about});

  /// What the server calls it, as "DRIVER_CAB".
  final String key;
  final String title;
  final List<ProformaItem> items;

  /// A line under the title, as what is inspected.
  final String? about;
}

/// What a field of a proforma's head or foot asks for.
enum ProformaFieldKind { text, multiline, number, date, choice, multi, station }

/// A question asked once of the whole inspection, as the loco number or
/// the inspection's result.
@immutable
class ProformaField {
  const ProformaField(
    this.key,
    this.label,
    this.kind, {
    this.options = const [],
    this.required = false,
    this.hint,
    this.note,
    this.when,
  });

  final String key;
  final String label;
  final ProformaFieldKind kind;

  /// For a choice or a multi: the answers to pick from.
  final List<ProformaOption> options;
  final bool required;
  final String? hint;
  final String? note;

  /// Whether it is asked, given what is answered, as a workshop's stage
  /// only at a workshop; always when not given.
  final bool Function(ProformaAnswers answers)? when;

  bool asks(ProformaAnswers answers) => when?.call(answers) ?? true;
}

/// A table filled in row by row at the end, as the officers who inspected
/// in the year.
@immutable
class ProformaTable {
  const ProformaTable(
    this.key,
    this.title,
    this.columns, {
    required this.item,
    this.about,
  });

  final String key;
  final String title;
  final List<ProformaField> columns;

  /// What one row is, as "Officer".
  final String item;
  final String? about;
}

/// What an inspection on a proforma was given: the facts at its head and
/// foot, each item's answers by section and number, and the tables' rows.
/// It keeps answers as the phone stores them, dates as "yyyy-MM-dd".
class ProformaAnswers {
  ProformaAnswers();

  final Map<String, Object?> fields = {};
  final Map<String, Map<String, Map<String, Object?>>> items = {};
  final Map<String, List<Map<String, Object?>>> tables = {};

  /// The step the inspector was on.
  int step = 0;

  static bool _blank(Object? value) =>
      value == null ||
      (value is String && value.trim().isEmpty) ||
      (value is Iterable && value.isEmpty);

  bool get isEmpty =>
      items.values.every((section) => section.isEmpty) &&
      tables.values.every((rows) => rows.isEmpty) &&
      fields.values.every(_blank);

  /// [item]'s answers in [section], none given yet if empty.
  Map<String, Object?> of(String section, ProformaItem item) =>
      items[section]?[item.no] ?? const {};

  Object? field(String key) => fields[key];

  void setField(String key, Object? value) {
    if (_blank(value)) {
      fields.remove(key);
    } else {
      fields[key] = value;
    }
  }

  /// Sets what [item] in [section] was found to be, as its 'status' or
  /// its 'value'; a blank answer is taken away.
  void set(String section, ProformaItem item, String key, Object? value) {
    final answers = items.putIfAbsent(section, () => {});
    final answer = answers.putIfAbsent(item.no, () => {});
    if (_blank(value)) {
      answer.remove(key);
    } else {
      answer[key] = value;
    }
    if (key == 'status' && !item.isFault(value)) answer.remove('cause');
    if (answer.isEmpty) answers.remove(item.no);
  }

  /// Whether [item] has been answered as the form asks.
  bool answered(String section, ProformaItem item) {
    final answer = of(section, item);
    if (item.options.isNotEmpty) return !_blank(answer['status']);
    if (item.checks.isNotEmpty) {
      return item.checks.every(
        (check) => !_blank(answer[ProformaItem.checkKey(check)]),
      );
    }
    if (item.record) return !_blank(answer['record']);
    if (item.reading) return !_blank(answer['value']);
    return true;
  }

  /// How many of [section]'s items are answered, of all it asks.
  (int answered, int total) progress(ProformaSection section) {
    var done = 0;
    for (final item in section.items) {
      if (answered(section.key, item)) done++;
    }
    return (done, section.items.length);
  }

  /// Items of [section] answered as at fault.
  int faults(ProformaSection section) => section.items
      .where((item) => item.isFault(of(section.key, item)['status']))
      .length;

  List<Map<String, Object?>> rowsOf(String table) =>
      tables.putIfAbsent(table, () => []);

  Map<String, dynamic> toJson() => {
    'fields': fields,
    'items': items,
    'tables': tables,
    'step': step,
  };

  static ProformaAnswers fromJson(Object? json) {
    final answers = ProformaAnswers();
    if (json is! Map) return answers;
    final fields = json['fields'];
    if (fields is Map) {
      answers.fields.addAll({
        for (final MapEntry(:key, :value) in fields.entries) '$key': value,
      });
    }
    final items = json['items'];
    if (items is Map) {
      for (final MapEntry(key: section, value: numbered) in items.entries) {
        if (numbered is! Map) continue;
        answers.items['$section'] = {
          for (final MapEntry(key: no, value: answer) in numbered.entries)
            if (answer is Map) '$no': Map<String, Object?>.from(answer),
        };
      }
    }
    final tables = json['tables'];
    if (tables is Map) {
      for (final MapEntry(key: table, value: rows) in tables.entries) {
        if (rows is! List) continue;
        answers.tables['$table'] = [
          for (final row in rows)
            if (row is Map) Map<String, Object?>.from(row),
        ];
      }
    }
    answers.step = (json['step'] as num?)?.toInt() ?? 0;
    return answers;
  }

  /// The answers of [sections] as the server takes them: by section key,
  /// then item number, each its status and what else was noted. Items not
  /// answered are left out; a likely cause leads the note.
  Map<String, dynamic> data(
    List<ProformaSection> sections, {
    String noteKey = 'observation',
  }) {
    final data = <String, dynamic>{};
    for (final section in sections) {
      final out = <String, dynamic>{};
      for (final item in section.items) {
        final answer = of(section.key, item);
        if (answer.isEmpty) continue;
        final value = answer['value'];
        final note = [
          ?answer['cause'],
          ?answer['note'],
        ].map((part) => '$part'.trim()).where((part) => part.isNotEmpty);
        out[item.no] = {
          'status': ?answer['status'],
          if (!_blank(value))
            'value': item.unit == null ? '$value' : '$value ${item.unit}',
          'expiry_date': ?answer['expiry_date'],
          'record': ?answer['record'],
          for (final count in const ['ok', 'defective', 'missing'])
            count: ?int.tryParse('${answer[count] ?? ''}'),
          for (final check in item.checks)
            ProformaItem.checkKey(check): ?answer[ProformaItem.checkKey(check)],
          if (note.isNotEmpty) noteKey: note.join(' — '),
        };
      }
      if (out.isNotEmpty) data[section.key] = out;
    }
    return data;
  }

  /// [sections] as the report reads them, each the step it is answered
  /// on counted from [firstStep].
  List<ReportSection> report(
    List<ProformaSection> sections, {
    required int firstStep,
    required String Function(DateTime day) date,
  }) => [
    for (final (i, section) in sections.indexed)
      ReportSection(
        title: section.title,
        step: firstStep + i,
        rows: [for (final item in section.items) _row(section, item, date)],
      ),
  ];

  ReportRow _row(
    ProformaSection section,
    ProformaItem item,
    String Function(DateTime day) date,
  ) {
    final answer = of(section.key, item);
    final status = answer['status'];
    final expiry = DateTime.tryParse('${answer['expiry_date'] ?? ''}');
    final counts = [
      for (final (key, name) in const [
        ('ok', 'OK'),
        ('defective', 'Defective'),
        ('missing', 'Missing'),
      ])
        if (answer[key] case final n?) '$name $n',
    ];
    final parts = [
      if (status != null) item.labelOf(status)!,
      if (answer['value'] case final value?)
        item.unit == null ? '$value' : '$value ${item.unit}',
      if (expiry != null) 'Expires ${date(expiry)}',
      if (counts.isNotEmpty) counts.join(' · '),
      for (final check in item.checks)
        if (answer[ProformaItem.checkKey(check)] case final yes?)
          '$check: ${yes == 'Y' ? 'Yes' : 'No'}',
      ?answer['record'],
      ?answer['cause'],
      ?answer['note'],
    ].map((part) => '$part'.trim()).where((part) => part.isNotEmpty);
    final name = [
      '${item.no}.',
      if (item.group case final group?) '$group ·',
      item.label,
    ].join(' ');
    return ReportRow(
      name,
      parts.join(' — '),
      tone: !answered(section.key, item)
          ? ReportTone.missing
          : item.isFault(status)
          ? ReportTone.bad
          : status == null
          ? ReportTone.plain
          : ReportTone.good,
    );
  }
}

/// A date as the server and the phone keep it, "yyyy-MM-dd".
String proformaDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The usual answers, as the proformas word them.
abstract final class ProformaOptions {
  static const okay = ProformaOption('O', 'Okay');
  static const defective = ProformaOption('D', 'Defective');
  static const missing = ProformaOption('M', 'Missing');
  static const notApplicable = ProformaOption('NA', 'N/A');
  static const yes = ProformaOption('Y', 'Yes');
  static const no = ProformaOption('N', 'No');

  /// Okay, defective or missing.
  static const odm = [okay, defective, missing];

  /// Okay, defective, missing or not applicable.
  static const odmNa = [okay, defective, missing, notApplicable];
  static const yesNo = [yes, no];
  static const odmFaults = {'D', 'M'};

  /// [labels] as options sent as written, the first the one in order.
  static List<ProformaOption> worded(List<String> labels) => [
    for (final label in labels) ProformaOption(label),
  ];
}
