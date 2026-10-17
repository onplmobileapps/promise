import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';

/// A station inspection as its report reads: every section's answers, a
/// fault with the note written for it, a due date with whether it is past.
InspectionReport stationReport(
  StationInspectionController form, {
  required String title,
  required String stationLabel,
  required String dateLabel,
  String? inspector,
}) {
  final station = form.station?.trim();
  return InspectionReport(
    title: title,
    subtitle: station,
    date: form.inspDate,
    inspector: inspector,
    facts: [
      ReportRow(stationLabel, station, tone: ReportTone.plain),
      ReportRow(dateLabel, displayValue(form.inspDate), tone: ReportTone.plain),
    ],
    sections: [
      for (final section in kInspectionSections)
        if (_section(form, section) case final part when !part.isEmpty) part,
    ],
  );
}

ReportSection _section(
  StationInspectionController form,
  InspectionSection section,
) {
  if (section.isSignals) {
    return ReportSection(
      title: section.title,
      rows: [
        for (final (i, name) in kSignalNames.indexed)
          for (final part in kSignalParts)
            _answer(form, 'sig_${i}_${part[0]}', '$name · ${part[1]}'),
      ],
    );
  }
  if (section.isRepeatSection) {
    final type = section.repeatType!;
    final def = kRepeatDefs[type]!;
    return ReportSection(
      title: section.title,
      rows: [
        for (final (n, row) in form.rowsFor(type).indexed) ...[
          for (final column in def.cols)
            if (column.label.isNotEmpty ||
                form.isFilled('${form.rowPrefix(type, row)}_${column.key}'))
              _field(
                form,
                column.build('${form.rowPrefix(type, row)}_${column.key}'),
                prefix: '${def.label} ${n + 1}',
              ),
          if (def.hasTotal)
            ReportRow(
              '${def.label} ${n + 1} · Total',
              form.rowTotal(type, row).toStringAsFixed(0),
              tone: ReportTone.plain,
            ),
        ],
      ],
    );
  }
  final remarks = section.isReview ? form.get<Object>('remarks') : null;
  return ReportSection(
    title: section.title,
    note: remarks == null ? null : displayValue(remarks),
    rows: [
      for (final item in section.items)
        if (item is FieldFormItem && item.spec.id != 'remarks')
          _field(form, item.spec),
      if (section.items.any(
        (item) => item is FieldFormItem && item.spec.id == 'fireExtCount',
      ))
        for (var n = 1; n <= form.fireExtCount; n++)
          _field(
            form,
            FieldSpec(
              form.fireExtDateId(n),
              'Extinguisher #$n — Date of Filling',
              FieldKind.dateOverdue,
              overdueYears: 1,
            ),
          ),
    ],
  );
}

ReportRow _field(
  StationInspectionController form,
  FieldSpec spec, {
  String? prefix,
}) {
  final label = prefix == null ? spec.label : '$prefix · ${spec.label}';
  if (spec.kind == FieldKind.dateOverdue) {
    final date = form.get<DateTime>(spec.id);
    if (date == null) return ReportRow(label, null);
    final years = spec.id == 'blockOverhaulDate'
        ? form.overhaulYearsForBlockType(form.get<String>('blockType'))
        : spec.overdueYears ?? 1;
    final due = form.overdueInfo(spec.id, years);
    return ReportRow(
      label,
      '${displayValue(date)} · ${due.text}',
      tone: switch (due.status) {
        OverdueStatus.overdue => ReportTone.bad,
        OverdueStatus.valid => ReportTone.good,
        _ => ReportTone.plain,
      },
    );
  }
  return _answer(form, spec.id, label);
}

/// An answer, with the note written for it when it reports a fault.
ReportRow _answer(StationInspectionController form, String id, String label) {
  final value = displayValue(form.fields[id]);
  final note = displayValue(form.fields['${id}_remark']);
  return ReportRow(
    label,
    note.isEmpty || value.isEmpty ? value : '$value — $note',
    tone: ReportTone.of(value),
  );
}
