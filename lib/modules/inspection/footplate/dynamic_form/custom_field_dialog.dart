import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';

/// Dialog for adding custom fields to a dynamic form
class CustomFieldDialog extends StatefulWidget {
  final List<FieldType> allowedTypes;
  final void Function(DynamicFormField) onFieldAdded;

  const CustomFieldDialog({
    super.key,
    required this.allowedTypes,
    required this.onFieldAdded,
  });

  @override
  State<CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<CustomFieldDialog> {
  FieldType? _selectedType;
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _placeholderController = TextEditingController();
  bool _isRequired = false;
  int? _minLength;
  int? _maxLength;
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    super.dispose();
  }

  void _addField() {
    if (_selectedType == null) {
      showAppMessage(
        context,
        'Please select a field type',
        tone: AppDialogTone.warning,
      );
      return;
    }

    if (_labelController.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Please enter a field label',
        tone: AppDialogTone.warning,
      );
      return;
    }

    // Generate a unique key for the custom field
    final key = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final field = DynamicFormField(
      key: key,
      type: _selectedType!,
      label: _labelController.text.trim(),
      placeholder: _placeholderController.text.trim().isEmpty
          ? null
          : _placeholderController.text.trim(),
      validation: FieldValidation(
        required: _isRequired,
        minLength: _minLength,
        maxLength: _maxLength,
        errorMessage: _errorMessage,
      ),
      isCustom: true,
    );

    widget.onFieldAdded(field);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Type Selection
            const Text(
              'Field Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allowedTypes.map((type) {
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Field Label
            const Text(
              'Field Label',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: 'e.g., Additional Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Placeholder (optional)
            const Text(
              'Placeholder (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placeholderController,
              decoration: const InputDecoration(
                hintText: 'e.g., Enter additional information',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Validation Options
            const Text(
              'Validation',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Required Field'),
              value: _isRequired,
              onChanged: (value) => setState(() => _isRequired = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),

            // Min Length (for text fields)
            if (_selectedType == FieldType.text ||
                _selectedType == FieldType.remarks) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Length (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() => _minLength = int.tryParse(value));
                },
              ),
              const SizedBox(height: 8),
            ],

            // Max Length (for text fields)
            if (_selectedType == FieldType.text ||
                _selectedType == FieldType.remarks) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Length (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() => _maxLength = int.tryParse(value));
                },
              ),
              const SizedBox(height: 8),
            ],

            // Custom Error Message
            TextField(
              decoration: const InputDecoration(
                labelText: 'Custom Error Message (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(
                  () => _errorMessage = value.trim().isEmpty
                      ? null
                      : value.trim(),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _addField, child: const Text('Add Field')),
      ],
    );
  }

  String _getTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.number:
        return 'Number';
      case FieldType.dropdown:
        return 'Dropdown';
      case FieldType.radio:
        return 'Radio';
      case FieldType.checkbox:
        return 'Checkbox';
      case FieldType.date:
        return 'Date';
      case FieldType.gps:
        return 'GPS';
      case FieldType.image:
        return 'Image';
      case FieldType.signature:
        return 'Signature';
      case FieldType.remarks:
        return 'Remarks';
    }
  }
}
