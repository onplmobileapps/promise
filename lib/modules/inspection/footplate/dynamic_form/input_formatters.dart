import 'package:flutter/services.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';

/// Input formatter factory
class InputFormatterFactory {
  /// Create a TextInputFormatter based on the formatter configuration
  static List<TextInputFormatter> createFormatters(InputFormatter? config) {
    if (config == null) return [];

    final formatters = <TextInputFormatter>[];

    switch (config.type) {
      case FormatterType.decimal:
        formatters.add(
          _DecimalFormatter(
            decimalDigits: config.decimalDigits ?? 2,
            min: config.min,
            max: config.max,
          ),
        );
        break;

      case FormatterType.integer:
        formatters.add(_IntegerFormatter(min: config.min, max: config.max));
        break;

      case FormatterType.text:
        formatters.add(
          _TextFormatter(
            allowUppercase: config.allowUppercase,
            allowSpaces: config.allowSpaces,
            maxLength: config.maxLength,
          ),
        );
        break;

      case FormatterType.phone:
        formatters.add(_PhoneFormatter());
        break;

      case FormatterType.email:
        formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
        break;

      case FormatterType.multiline:
        // Multiline doesn't need special formatting, just length limiting
        if (config.maxLength != null) {
          formatters.add(LengthLimitingTextInputFormatter(config.maxLength));
        }
        break;
    }

    return formatters;
  }
}

/// Decimal number formatter
class _DecimalFormatter extends TextInputFormatter {
  final int decimalDigits;
  final num? min;
  final num? max;

  _DecimalFormatter({required this.decimalDigits, this.min, this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Allow only digits and decimal point
    final regex = RegExp(r'^\d*\.?\d*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Parse the value
    final value = double.tryParse(newValue.text);
    if (value == null) return oldValue;

    // Check min/max constraints
    if (min != null && value < min!) return oldValue;
    if (max != null && value > max!) return oldValue;

    // Check decimal places
    final parts = newValue.text.split('.');
    if (parts.length > 2) return oldValue;
    if (parts.length == 2 && parts[1].length > decimalDigits) {
      return oldValue;
    }

    return newValue;
  }
}

/// Integer formatter
class _IntegerFormatter extends TextInputFormatter {
  final num? min;
  final num? max;

  _IntegerFormatter({this.min, this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Allow only digits
    if (!RegExp(r'^\d*$').hasMatch(newValue.text)) {
      return oldValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    // Check min/max constraints
    if (min != null && value < min!) return oldValue;
    if (max != null && value > max!) return oldValue;

    return newValue;
  }
}

/// Text formatter with uppercase and space control
class _TextFormatter extends TextInputFormatter {
  final bool allowUppercase;
  final bool allowSpaces;
  final int? maxLength;

  _TextFormatter({
    this.allowUppercase = false,
    this.allowSpaces = true,
    this.maxLength,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove spaces if not allowed
    if (!allowSpaces) {
      text = text.replaceAll(' ', '');
    }

    // Convert to uppercase if required
    if (allowUppercase) {
      text = text.toUpperCase();
    }

    // Apply max length
    if (maxLength != null && text.length > maxLength!) {
      text = text.substring(0, maxLength!);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Phone number formatter (basic)
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits, spaces, dashes, and plus
    final regex = RegExp(r'^[\d\s\-\+]*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    return newValue;
  }
}

/// Helper to get keyboard type based on field type
class KeyboardTypeHelper {
  static TextInputType getKeyboardType(FieldType fieldType) {
    switch (fieldType) {
      case FieldType.number:
        return TextInputType.number;
      case FieldType.text:
      case FieldType.remarks:
        return TextInputType.text;
      case FieldType.date:
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  static bool isMultiline(FieldType fieldType) {
    return fieldType == FieldType.remarks || fieldType == FieldType.text;
  }
}
