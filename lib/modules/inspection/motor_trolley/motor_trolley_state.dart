import 'package:railway_hrms/modules/inspection/motor_trolley/inspection_params_config.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';

/// A motor trolley inspection as it is filled in: every answer by its
/// question's key, the day, and the step it is on.
class MotorTrolleyInspectionState {
  const MotorTrolleyInspectionState({
    this.values = const {},
    this.inspectionDate,
    this.step = 0,
  });

  final Map<String, String> values;
  final DateTime? inspectionDate;
  final int step;

  String? value(String key) => values[key];

  bool isAnswered(String key) => values[key]?.trim().isNotEmpty ?? false;

  /// Whether [field] is asked, given the answers so far.
  bool asks(ParamField field) {
    final when = field.showWhen;
    return when == null || values[when.$1] == when.$2;
  }

  /// Questions [step] asks, and how many have answers.
  (int answered, int total) progressOf(TrolleyStep step) {
    var answered = 0;
    var total = 0;
    for (final field in step.fields.where(asks)) {
      total++;
      if (isAnswered(field.key)) answered++;
    }
    return (answered, total);
  }

  bool get hasAnswers => values.values.any((v) => v.trim().isNotEmpty);

  MotorTrolleyInspectionState copyWith({
    Map<String, String>? values,
    DateTime? inspectionDate,
    int? step,
  }) => MotorTrolleyInspectionState(
    values: values ?? this.values,
    inspectionDate: inspectionDate ?? this.inspectionDate,
    step: step ?? this.step,
  );

  Map<String, dynamic> toJson() => {
    'values': values,
    'inspectionDate': inspectionDate?.toIso8601String(),
    'step': step,
  };

  factory MotorTrolleyInspectionState.fromJson(Map<String, dynamic> json) =>
      MotorTrolleyInspectionState(
        values: {
          if (json['values'] case final Map<dynamic, dynamic> saved)
            for (final MapEntry(:key, :value) in saved.entries)
              if (value != null) '$key': '$value',
        },
        inspectionDate: DateTime.tryParse('${json['inspectionDate'] ?? ''}'),
        step: json['step'] is int ? json['step'] as int : 0,
      );
}
