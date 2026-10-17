import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';

/// A motor trolley inspection as its report reads: each step's answers,
/// a reading with its unit, a fault with the remedy picked for it.
InspectionReport trolleyReport(
  MotorTrolleyInspectionState form, {
  required String title,
  required String sectionLabel,
  required String dateLabel,
}) {
  String text(String key) => form.value(key)?.trim() ?? '';
  final from = text('sectionFrom');
  final to = text('sectionTo');
  final section = [from, to].where((part) => part.isNotEmpty).join(' – ');
  return InspectionReport(
    title: title,
    subtitle: section.isEmpty ? null : section,
    date: form.inspectionDate ?? DateTime.now(),
    facts: [
      ReportRow(sectionLabel, section, tone: ReportTone.plain),
      ReportRow(
        dateLabel,
        displayValue(form.inspectionDate),
        tone: ReportTone.plain,
      ),
    ],
    sections: [
      for (final step in kTrolleySteps)
        ReportSection(
          title: step.title,
          rows: [
            for (final field in step.fields.where(form.asks))
              if (text(field.key) case final answer)
                ReportRow(
                  field.label,
                  [
                    if (answer.isNotEmpty && field.unit != null)
                      '$answer ${field.unit}'
                    else
                      answer,
                    if (text(field.remedyKey) case final remedy
                        when remedy.isNotEmpty && answer.isNotEmpty)
                      'Remedy: $remedy',
                  ].join(' — '),
                  tone: _outOfLimit(field.key) && answer.isNotEmpty
                      ? (answer == 'Yes' ? ReportTone.bad : ReportTone.good)
                      : ReportTone.of(answer),
                ),
          ],
        ),
    ],
  );
}

/// A question whose "Yes" reports the fault: the reading is out of limit.
bool _outOfLimit(String key) => key.endsWith('OutOfLimit');
