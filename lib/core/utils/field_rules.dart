import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/utils/validators.dart';

/// One rule for what a field holds: what is wrong with [value] by it, or
/// null when the value keeps it.
typedef FieldRule = String? Function(String value);

/// Rules a form field's value is checked by, built once and put together
/// for any field, each with the message it shows:
///
/// ```dart
/// validator: FieldRules.all([
///   FieldRules.required(l10n.employeeIdRequired),
///   FieldRules.maxLength(10, l10n.employeeIdTooLong(10)),
/// ]),
/// ```
///
/// What can't be typed at all is kept out by [FieldInput] instead.
abstract final class FieldRules {
  /// A validator for a form field that checks [rules] in order and says
  /// what the first one broken says.
  static FormFieldValidator<String> all(List<FieldRule> rules) => (value) {
    for (final rule in rules) {
      final problem = rule(value ?? '');
      if (problem != null) return problem;
    }
    return null;
  };

  /// Something other than spaces is there.
  static FieldRule required(String message) =>
      (value) => value.trim().isEmpty ? message : null;

  /// At least [min] characters. An empty value is left to [required].
  static FieldRule minLength(int min, String message) =>
      (value) => value.isNotEmpty && value.length < min ? message : null;

  /// At most [max] characters.
  static FieldRule maxLength(int max, String message) =>
      (value) => value.length > max ? message : null;

  /// No spaces anywhere.
  static FieldRule noSpaces(String message) =>
      (value) => value.contains(RegExp(r'\s')) ? message : null;

  /// Digits only. An empty value is left to [required].
  static FieldRule digits(String message) => pattern(RegExp(r'^\d+$'), message);

  /// The whole value matches [regex]. An empty value is left to
  /// [required].
  static FieldRule pattern(RegExp regex, String message) =>
      (value) => value.isEmpty || regex.hasMatch(value) ? null : message;

  /// An e-mail address. An empty value is left to [required].
  static FieldRule email(String message) =>
      (value) => value.isEmpty || isValidEmail(value.trim()) ? null : message;

  /// A Pakistani mobile number, 03 and nine more digits.
  static FieldRule pakistaniMobile(String message) =>
      (value) =>
          value.isEmpty || isValidPakistaniMobile(value) ? null : message;

  /// The same as another field's value now, such as a password typed
  /// again.
  static FieldRule sameAs(String Function() other, String message) =>
      (value) => value == other() ? null : message;
}

/// What a field lets be typed or pasted at all, so the user can't get it
/// wrong in the first place; [FieldRules] says what is wrong with the rest.
abstract final class FieldInput {
  /// No spaces, and at most [maxLength] characters when given: for IDs,
  /// passwords and codes.
  static List<TextInputFormatter> noSpaces({int? maxLength}) => [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Digits only, at most [maxLength] when given.
  static List<TextInputFormatter> digits({int? maxLength}) => [
    FilteringTextInputFormatter.digitsOnly,
    if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Anything, at most [maxLength] characters.
  static List<TextInputFormatter> limited(int maxLength) => [
    LengthLimitingTextInputFormatter(maxLength),
  ];
}
