/// What a question described as data asks for.
enum FormSpecKind {
  /// A heading that starts a new part of the form.
  section,

  /// One of a few answers, as chips.
  choice,

  /// One of many answers, from a sheet.
  select,
  date,
  number,
  text,

  /// A fact shown, not asked.
  display,

  /// Questions grouped under a label.
  group,

  /// Questions asked again for each of several things, as each pier of a
  /// bridge.
  repeat,
}

/// A question of a form described as data, as the civil and electrical
/// catalogues describe theirs.
abstract interface class FormSpec {
  /// Where its answer is kept.
  String get key;
  String get label;
  FormSpecKind get kind;

  /// The answers to pick from, for a choice or a select.
  List<String> get choices;

  /// What a number is measured in.
  String? get unit;

  /// The highest a number may be.
  num? get maxValue;

  /// The questions of a group or a repeat.
  List<FormSpec> get parts;

  /// Asked only while the answer kept under [showIfKey] is [showIfValue],
  /// or one of them when it is a list.
  String? get showIfKey;
  Object? get showIfValue;

  /// The fact a display shows.
  String? get shownValue;

  /// What each repeat is called, as "Pier".
  String? get itemLabel;

  /// A line under the question, as the standard a reading is held to.
  String? get note;

  /// The answers that report a fault, when the wording alone doesn't say,
  /// as "Yes" to "Any knocking sound?".
  List<String> get faults;
}
