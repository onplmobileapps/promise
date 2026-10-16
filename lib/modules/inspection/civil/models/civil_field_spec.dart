library;

enum CivilFieldType {
  section,
  radio,
  date,
  number,
  text,
  dropdown,
  display,
  group,
  repeatGroup,
}

class CivilFieldSpec {
  final String key;
  final String label;
  final CivilFieldType type;
  final List<String>? options;
  final String? unit;
  final List<CivilFieldSpec>? children;

  /// If set, this field (and its children) only render when
  /// `answers[conditionKey] == conditionValue` (or is contained in
  /// conditionValue when it's a List, for "any of" conditions).
  final String? conditionKey;
  final dynamic conditionValue;

  /// For `display` fields: the sample/current value to show read-only.
  final String? displayValue;

  /// For `repeatGroup`: label used for the "Add ..." button and for
  /// naming each instance (e.g. "Pier" -> "Pier 1", "Pier 2", ...).
  final String? itemLabel;

  const CivilFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.unit,
    this.children,
    this.conditionKey,
    this.conditionValue,
    this.displayValue,
    this.itemLabel,
  });

  factory CivilFieldSpec.section(String label) => CivilFieldSpec(
    key: 'section_${label.hashCode}',
    label: label,
    type: CivilFieldType.section,
  );

  factory CivilFieldSpec.radio(
    String key,
    String label,
    List<String> options, {
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.radio,
    options: options,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.date(
    String key,
    String label, {
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.date,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.number(
    String key,
    String label, {
    String? unit,
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.number,
    unit: unit,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.text(
    String key,
    String label, {
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.text,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.dropdown(
    String key,
    String label,
    List<String> options, {
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.dropdown,
    options: options,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.display(String key, String label, String value) =>
      CivilFieldSpec(
        key: key,
        label: label,
        type: CivilFieldType.display,
        displayValue: value,
      );

  factory CivilFieldSpec.group(
    String label,
    List<CivilFieldSpec> children, {
    String? conditionKey,
    dynamic conditionValue,
  }) => CivilFieldSpec(
    key: 'group_${label.hashCode}_${children.length}',
    label: label,
    type: CivilFieldType.group,
    children: children,
    conditionKey: conditionKey,
    conditionValue: conditionValue,
  );

  factory CivilFieldSpec.repeatGroup(
    String key,
    String label,
    String itemLabel,
    List<CivilFieldSpec> template,
  ) => CivilFieldSpec(
    key: key,
    label: label,
    type: CivilFieldType.repeatGroup,
    children: template,
    itemLabel: itemLabel,
  );

  /// Builds the recurring BRD pattern:
  /// "During Inspection: Exists / Removed  ->  (if Exists) Same / New  ->

  ///
  /// [existsToggleKey] is the parent yes/no toggle (e.g. "Encroachments:
  /// Yes/No") that reveals the whole block; pass null to always show it.
  static List<CivilFieldSpec> duringInspectionBlock({
    required String prefix,
    required List<CivilFieldSpec> newFields,
    String? conditionKey,
    dynamic conditionValue,
  }) {
    return [
      CivilFieldSpec.group(
        'During Inspection',
        [
          CivilFieldSpec.radio('${prefix}_status', 'Status', const [
            'Exists',
            'Removed',
          ]),
          CivilFieldSpec.radio(
            '${prefix}_sameNew',
            'Same / New',
            const ['Same', 'New'],
            conditionKey: '${prefix}_status',
            conditionValue: 'Exists',
          ),
          CivilFieldSpec.group(
            'Updated Details',
            newFields,
            conditionKey: '${prefix}_sameNew',
            conditionValue: 'New',
          ),
        ],
        conditionKey: conditionKey,
        conditionValue: conditionValue,
      ),
    ];
  }
}

/// One selectable asset type within a department/sub-department, as per
/// the BRD's "How assets Work" table (page 5).
class CivilAssetFormDef {
  final String id;
  final String assetLabel;
  final String department;
  final String subDepartment;
  final List<CivilFieldSpec> fields;

  const CivilAssetFormDef({
    required this.id,
    required this.assetLabel,
    required this.department,
    required this.subDepartment,
    required this.fields,
  });
}
