/// Field types supported in dynamic forms
enum FieldType {
  text,
  number,
  dropdown,
  radio,
  checkbox,
  date,
  gps,
  image,
  signature,
  remarks,
}

/// Input formatter types
enum FormatterType { text, decimal, integer, multiline, phone, email }

/// Validation rules for a field
class FieldValidation {
  final bool required;
  final String? errorMessage;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? pattern;
  final int? maxFileSizeMB;
  final List<String>? allowedFormats;

  FieldValidation({
    this.required = false,
    this.errorMessage,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.pattern,
    this.maxFileSizeMB,
    this.allowedFormats,
  });

  factory FieldValidation.fromJson(Map<String, dynamic> json) {
    return FieldValidation(
      required: json['required'] ?? false,
      errorMessage: json['errorMessage'],
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      pattern: json['pattern'],
      maxFileSizeMB: json['maxFileSizeMB'],
      allowedFormats: json['allowedFormats'] != null
          ? List<String>.from(json['allowedFormats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'required': required,
      'errorMessage': errorMessage,
      'minLength': minLength,
      'maxLength': maxLength,
      'min': min,
      'max': max,
      'pattern': pattern,
      'maxFileSizeMB': maxFileSizeMB,
      'allowedFormats': allowedFormats,
    };
  }
}

/// Input formatter configuration
class InputFormatter {
  final FormatterType type;
  final int? decimalDigits;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool allowUppercase;
  final bool allowSpaces;
  final num? min;
  final num? max;

  InputFormatter({
    required this.type,
    this.decimalDigits,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.allowUppercase = false,
    this.allowSpaces = true,
    this.min,
    this.max,
  });

  factory InputFormatter.fromJson(Map<String, dynamic> json) {
    return InputFormatter(
      type: _parseFormatterType(json['type']),
      decimalDigits: json['decimalDigits'],
      maxLength: json['maxLength'],
      minLines: json['minLines'],
      maxLines: json['maxLines'],
      allowUppercase: json['allowUppercase'] ?? false,
      allowSpaces: json['allowSpaces'] ?? true,
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
    );
  }

  static FormatterType _parseFormatterType(String? type) {
    switch (type) {
      case 'decimal':
        return FormatterType.decimal;
      case 'integer':
        return FormatterType.integer;
      case 'multiline':
        return FormatterType.multiline;
      case 'phone':
        return FormatterType.phone;
      case 'email':
        return FormatterType.email;
      default:
        return FormatterType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'decimalDigits': decimalDigits,
      'maxLength': maxLength,
      'minLines': minLines,
      'maxLines': maxLines,
      'allowUppercase': allowUppercase,
      'allowSpaces': allowSpaces,
      'min': min,
      'max': max,
    };
  }
}

/// Option for radio/checkbox/dropdown fields
class FieldOption {
  final String value;
  final String label;

  FieldOption({required this.value, required this.label});

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(value: json['value'], label: json['label']);
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'label': label};
  }
}

/// Individual field definition
class DynamicFormField {
  final String key;
  final FieldType type;
  final String label;
  final String? placeholder;
  final String? lookupCategory;
  final List<FieldOption> options;
  final FieldValidation validation;
  final InputFormatter? inputFormatter;
  final String? visibleWhenFieldKey;
  final String? visibleWhenEquals;
  final bool autoCapture;
  final bool isCustom; // Added by user dynamically

  DynamicFormField({
    required this.key,
    required this.type,
    required this.label,
    this.placeholder,
    this.lookupCategory,
    this.options = const [],
    FieldValidation? validation,
    this.inputFormatter,
    this.visibleWhenFieldKey,
    this.visibleWhenEquals,
    this.autoCapture = false,
    this.isCustom = false,
  }) : validation = validation ?? FieldValidation();

  factory DynamicFormField.fromJson(
    Map<String, dynamic> json, {
    bool isCustom = false,
  }) {
    return DynamicFormField(
      key: json['key'],
      type: _parseFieldType(json['type']),
      label: json['label'],
      placeholder: json['placeholder'],
      lookupCategory: json['lookupCategory'],
      options: json['options'] != null
          ? (json['options'] as List)
                .map((e) => FieldOption.fromJson(e))
                .toList()
          : [],
      validation: json['validation'] != null
          ? FieldValidation.fromJson(json['validation'])
          : null,
      inputFormatter: json['inputFormatter'] != null
          ? InputFormatter.fromJson(json['inputFormatter'])
          : null,
      visibleWhenFieldKey: json['visibleWhenFieldKey'],
      visibleWhenEquals: json['visibleWhenEquals'],
      autoCapture: json['autoCapture'] ?? false,
      isCustom: isCustom,
    );
  }

  static FieldType _parseFieldType(String? type) {
    switch (type) {
      case 'text':
        return FieldType.text;
      case 'number':
        return FieldType.number;
      case 'dropdown':
        return FieldType.dropdown;
      case 'radio':
        return FieldType.radio;
      case 'checkbox':
        return FieldType.checkbox;
      case 'date':
        return FieldType.date;
      case 'gps':
        return FieldType.gps;
      case 'image':
        return FieldType.image;
      case 'signature':
        return FieldType.signature;
      case 'remarks':
        return FieldType.remarks;
      default:
        return FieldType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'type': type.name,
      'label': label,
      'placeholder': placeholder,
      'lookupCategory': lookupCategory,
      'options': options.map((e) => e.toJson()).toList(),
      'validation': validation.toJson(),
      if (inputFormatter != null) 'inputFormatter': inputFormatter!.toJson(),
      if (visibleWhenFieldKey != null)
        'visibleWhenFieldKey': visibleWhenFieldKey,
      if (visibleWhenEquals != null) 'visibleWhenEquals': visibleWhenEquals,
      'autoCapture': autoCapture,
    };
  }

  /// Check if field should be visible based on other field values
  bool isVisible(Map<String, dynamic> formData) {
    if (visibleWhenFieldKey == null) return true;
    final dependentValue = formData[visibleWhenFieldKey];
    return dependentValue?.toString() == visibleWhenEquals;
  }
}

/// Section containing multiple fields
class FormSection {
  final String title;
  final List<DynamicFormField> fields;

  FormSection({required this.title, required this.fields});

  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      title: json['title'],
      fields: (json['fields'] as List)
          .map((e) => DynamicFormField.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'fields': fields.map((e) => e.toJson()).toList()};
  }
}

/// Complete form template
class FormTemplate {
  final String templateId;
  final String name;
  final String type;
  final int version;
  final bool allowCustomFields;
  final List<FieldType> customFieldTypes;
  final List<FormSection> sections;

  FormTemplate({
    required this.templateId,
    required this.name,
    required this.type,
    required this.version,
    this.allowCustomFields = false,
    this.customFieldTypes = const [],
    required this.sections,
  });

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      templateId: json['templateId'],
      name: json['name'],
      type: json['type'],
      version: json['version'],
      allowCustomFields: json['allowCustomFields'] ?? false,
      customFieldTypes: json['customFieldTypes'] != null
          ? (json['customFieldTypes'] as List)
                .map((e) => _parseFieldType(e))
                .toList()
          : [],
      sections: (json['sections'] as List)
          .map((e) => FormSection.fromJson(e))
          .toList(),
    );
  }

  static FieldType _parseFieldType(String type) {
    switch (type) {
      case 'text':
        return FieldType.text;
      case 'number':
        return FieldType.number;
      case 'dropdown':
        return FieldType.dropdown;
      case 'radio':
        return FieldType.radio;
      case 'checkbox':
        return FieldType.checkbox;
      case 'date':
        return FieldType.date;
      case 'gps':
        return FieldType.gps;
      case 'image':
        return FieldType.image;
      case 'signature':
        return FieldType.signature;
      case 'remarks':
        return FieldType.remarks;
      default:
        return FieldType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'name': name,
      'type': type,
      'version': version,
      'allowCustomFields': allowCustomFields,
      'customFieldTypes': customFieldTypes.map((e) => e.name).toList(),
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }

  /// Get all fields from all sections
  List<DynamicFormField> getAllFields() {
    return sections.expand((section) => section.fields).toList();
  }

  /// Get field by key
  DynamicFormField? getFieldByKey(String key) {
    for (final section in sections) {
      for (final field in section.fields) {
        if (field.key == key) return field;
      }
    }
    return null;
  }
}

/// Form data holder with validation state
class FormData {
  final Map<String, dynamic> values = {};
  final Map<String, String> errors = {};

  /// Get value for a field
  dynamic getValue(String key) => values[key];

  /// Set value for a field
  void setValue(String key, dynamic value) {
    values[key] = value;
    // Clear error when value changes
    errors.remove(key);
  }

  /// Set error for a field
  void setError(String key, String error) {
    errors[key] = error;
  }

  /// Clear error for a field
  void clearError(String key) {
    errors.remove(key);
  }

  /// Check if form has any errors
  bool hasErrors() => errors.isNotEmpty;

  /// Check if specific field has error
  bool hasError(String key) => errors.containsKey(key);

  /// Get all required fields that are empty
  List<String> getEmptyRequiredFields(FormTemplate template) {
    final emptyFields = <String>[];
    for (final field in template.getAllFields()) {
      if (field.validation.required) {
        final value = values[field.key];
        if (value == null || value.toString().isEmpty) {
          emptyFields.add(field.key);
        }
      }
    }
    return emptyFields;
  }

  /// Clear all data
  void clear() {
    values.clear();
    errors.clear();
  }
}
