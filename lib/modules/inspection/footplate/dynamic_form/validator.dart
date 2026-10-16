import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';

/// Validation result for a field
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.success() => const ValidationResult(isValid: true);
  factory ValidationResult.failure(String message) =>
      ValidationResult(isValid: false, errorMessage: message);
}

/// Validator for form fields
class FieldValidator {
  /// Validate a single field
  static ValidationResult validateField(DynamicFormField field, dynamic value) {
    final validation = field.validation;

    // Check required
    if (validation.required) {
      if (value == null || value.toString().isEmpty) {
        return ValidationResult.failure(
          validation.errorMessage ?? '${field.label} is required',
        );
      }
    }

    // If value is empty and not required, skip other validations
    if (value == null || value.toString().isEmpty) {
      return ValidationResult.success();
    }

    // String length validations
    if (value is String) {
      if (validation.minLength != null &&
          value.length < validation.minLength!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must be at least ${validation.minLength} characters',
        );
      }

      if (validation.maxLength != null &&
          value.length > validation.maxLength!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must not exceed ${validation.maxLength} characters',
        );
      }

      // Pattern validation
      if (validation.pattern != null) {
        final regex = RegExp(validation.pattern!);
        if (!regex.hasMatch(value)) {
          return ValidationResult.failure(
            validation.errorMessage ?? '${field.label} format is invalid',
          );
        }
      }
    }

    // Number validations
    if (value is num) {
      if (validation.min != null && value < validation.min!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must be at least ${validation.min}',
        );
      }

      if (validation.max != null && value > validation.max!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must not exceed ${validation.max}',
        );
      }
    }

    // Number validation for string inputs
    if (field.type == FieldType.number && value is String) {
      final numValue = double.tryParse(value);
      if (numValue == null) {
        return ValidationResult.failure(
          validation.errorMessage ?? '${field.label} must be a valid number',
        );
      }

      if (validation.min != null && numValue < validation.min!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must be at least ${validation.min}',
        );
      }

      if (validation.max != null && numValue > validation.max!) {
        return ValidationResult.failure(
          validation.errorMessage ??
              '${field.label} must not exceed ${validation.max}',
        );
      }
    }

    // Image validation
    if (field.type == FieldType.image && value != null) {
      // File size validation would be done at file selection time
      // This is a placeholder for when file data is available
    }

    return ValidationResult.success();
  }

  /// Validate entire form
  static Map<String, String> validateForm(
    FormTemplate template,
    FormData formData,
  ) {
    final errors = <String, String>{};

    for (final field in template.getAllFields()) {
      // Skip validation if field is not visible
      if (!field.isVisible(formData.values)) {
        continue;
      }

      final value = formData.getValue(field.key);
      final result = validateField(field, value);

      if (!result.isValid && result.errorMessage != null) {
        errors[field.key] = result.errorMessage!;
      }
    }

    return errors;
  }

  /// Validate a specific field and update form data
  static bool validateAndUpdate(DynamicFormField field, FormData formData) {
    final value = formData.getValue(field.key);
    final result = validateField(field, value);

    if (result.isValid) {
      formData.clearError(field.key);
      return true;
    } else {
      formData.setError(field.key, result.errorMessage ?? 'Invalid value');
      return false;
    }
  }
}
