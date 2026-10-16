enum FieldKind {
  text,
  textarea,
  number,
  date,
  select,
  decimal,
  dateOverdue,
  toggle,
  toggleRemark,
  stepper,
}

class FieldSpec {
  final String id;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final String? note;
  final String? hint;
  final String? unit;
  final double? min;
  final double? max;
  final int? overdueYears; // for dateOverdue
  final bool span2;
  final String? placeholder;

  const FieldSpec(
    this.id,
    this.label,
    this.kind, {
    this.options = const [],
    this.note,
    this.hint,
    this.unit,
    this.min,
    this.max,
    this.overdueYears,
    this.span2 = false,
    this.placeholder,
  });

  /// The companion remark-field id for a [FieldKind.toggleRemark] field.
  String get remarkId => '${id}_remark';
}

/// An item that appears inside a fixed (non-repeating) section: either a
/// field, or a subheading that groups fields visually.
abstract class FormItem {}

class FieldFormItem extends FormItem {
  final FieldSpec spec;
  FieldFormItem(this.spec);
}

class SubheadFormItem extends FormItem {
  final String label;
  final String? note;
  SubheadFormItem(this.label, {this.note});
}

/// One column definition inside a repeatable section (points, level
/// crossings, track circuits, failure summary). [build] receives the
/// fully-qualified field id (already prefixed with the row key).
class RepeatColumn {
  final String key;
  final String label;
  final FieldSpec Function(String fid) build;
  const RepeatColumn(this.key, this.label, this.build);
}

class RepeatDef {
  final String label;
  final int minRows;
  final List<RepeatColumn> cols;
  final bool hasTotal;
  const RepeatDef(this.label, this.minRows, this.cols, {this.hasTotal = false});
}

class InspectionSection {
  final String id;
  final String title;
  final String blurb;
  final List<FormItem> items;
  final String? repeatType; // one of REPEAT_DEFS keys, or 'signals'
  final bool isReview;

  const InspectionSection({
    required this.id,
    required this.title,
    required this.blurb,
    this.items = const [],
    this.repeatType,
    this.isReview = false,
  });

  bool get isSignals => repeatType == 'signals';
  bool get isRepeatSection => repeatType != null && !isSignals;
}

/// Value-classification used to color toggle buttons and badges,
/// mirroring the web proforma's pos/neg/amber/neutral scheme.
enum FieldTone { positive, negative, amber, neutral }

const Set<String> kPositiveValues = {
  'Yes',
  'Available',
  'Functional',
  'Satisfactory',
  'Good',
  'Working',
  'Complete',
  'Prime',
  'Pass',
};
const Set<String> kNegativeValues = {
  'No',
  'Not available',
  'Not Available',
  'Non-functional',
  'Unsatisfactory',
  'Poor',
  'Not working',
  'Incomplete',
  'Fail',
};
const Set<String> kAmberValues = {'Standby'};

FieldTone classifyValue(String value) {
  if (kPositiveValues.contains(value)) return FieldTone.positive;
  if (kNegativeValues.contains(value)) return FieldTone.negative;
  if (kAmberValues.contains(value)) return FieldTone.amber;
  return FieldTone.neutral;
}

const List<String> kStations = [
  'Lahore Junction',
  'Rawalpindi',
  'Multan Cantt',
  'Faisalabad',
  'Sahiwal',
  'Sheikhupura',
  'Gujranwala',
  'Wazirabad',
  'Sialkot',
  'Kot Radha Kishan',
  'Raiwind Junction',
  'Other',
];

const List<String> kSignalNames = [
  'Up OHS',
  'UP HS',
  'Up SS ML',
  'Up SS LL',
  'Up ASS',
  'DN OHS',
  'DN HS',
  'DN SS ML',
  'DN SS LL',
  'DN ASS',
];
