import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/validator.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// A form template's questions, section by section, on the form design.
/// Answers go into [formData] as the template keeps them: dates as
/// "yyyy-MM-dd", a photo as its stored path, a location as "lat, lng".
class TemplateFormBody extends StatelessWidget {
  const TemplateFormBody({
    super.key,
    required this.template,
    required this.formData,
    required this.onChanged,
  });

  final FormTemplate template;
  final FormData formData;
  final VoidCallback onChanged;

  void _set(DynamicFormField field, Object? value) {
    formData.setValue(field.key, value);
    FieldValidator.validateAndUpdate(field, formData);
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final section in template.sections) ...[
        InspectionSubhead(section.title),
        for (final field in section.fields)
          if (field.isVisible(formData.values)) ...[
            AppSpacing.gapMd,
            _field(context, field),
          ],
        AppSpacing.gapLg,
      ],
    ],
  );

  Widget _field(BuildContext context, DynamicFormField field) {
    final value = formData.getValue(field.key);
    final error = formData.errors[field.key];
    final label = field.validation.required ? '${field.label} *' : field.label;
    String? labelOf(Object? option) {
      for (final o in field.options) {
        if (o.value == option) return o.label;
      }
      return option?.toString();
    }

    String? valueOf(String label) {
      for (final o in field.options) {
        if (o.label == label) return o.value;
      }
      return label;
    }

    final labels = [for (final o in field.options) o.label];
    switch (field.type) {
      case FieldType.text || FieldType.number || FieldType.remarks:
        return InspectionTextInput(
          label: label,
          value: value?.toString(),
          hint: field.placeholder,
          warning: error,
          kind: switch ((field.type, field.inputFormatter?.type)) {
            (FieldType.remarks, _) ||
            (_, FormatterType.multiline) => InspectionTextKind.multiline,
            (_, FormatterType.integer) => InspectionTextKind.integer,
            (FieldType.number, _) ||
            (_, FormatterType.decimal) => InspectionTextKind.decimal,
            _ => InspectionTextKind.text,
          },
          onChanged: (typed) => _set(field, typed),
        );
      case FieldType.dropdown:
        return InspectionSelectInput(
          label: label,
          options: labels,
          value: labelOf(value),
          hint: field.placeholder,
          note: error,
          onChanged: (picked) => _set(field, valueOf(picked)),
        );
      case FieldType.radio:
        return InspectionChoiceInput(
          label: label,
          options: labels,
          value: labelOf(value),
          note: error,
          onChanged: (picked) => _set(field, valueOf(picked)),
        );
      case FieldType.checkbox:
        final picked = value is List
            ? value.map(labelOf).nonNulls.toList()
            : <String>[];
        return InspectionMultiChoiceInput(
          label: label,
          options: labels,
          values: picked,
          note: error,
          onChanged: (all) =>
              _set(field, [for (final l in all) valueOf(l)].nonNulls.toList()),
        );
      case FieldType.date:
        return InspectionDateInput(
          label: label,
          value: DateTime.tryParse('${value ?? ''}'),
          note: error,
          onChanged: (day) => _set(
            field,
            '${day.year}-${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
          ),
        );
      case FieldType.gps:
        return _Location(
          label: label,
          value: value?.toString(),
          onChanged: (at) => _set(field, at),
        );
      case FieldType.image:
        return InspectionPhotosInput(
          photos: [
            if (value is String && value.isNotEmpty) value,
            if (value is List) ...value.whereType<String>(),
          ],
          onChanged: (photos) => _set(
            field,
            photos.isEmpty
                ? null
                : (photos.length == 1 ? photos.single : photos),
          ),
        );
      case FieldType.signature:
        // The report is signed with the inspector's face at submit.
        return InspectionFieldNote(text: context.l10n.inspFormSignedByFace);
    }
  }
}

/// Where the inspector stands, taken from the phone's location on a tap.
class _Location extends StatefulWidget {
  const _Location({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_Location> createState() => _LocationState();
}

class _LocationState extends State<_Location> {
  bool _finding = false;

  Future<void> _find() async {
    setState(() => _finding = true);
    final here = await CurrentLocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _finding = false);
    if (here != null) {
      widget.onChanged(
        '${here.latitude.toStringAsFixed(6)}, '
        '${here.longitude.toStringAsFixed(6)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return AppFieldFrame(
      label: widget.label,
      glyph: AppGlyphs.mapPin,
      state: AppFieldState.readOnly,
      trailing: _finding
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: AppLoader(size: AppSizes.loaderSmall),
            )
          : AppButton(
              label: context.l10n.inspFormLocate,
              size: AppButtonSize.small,
              variant: AppButtonVariant.tonal,
              leadingGlyph: AppGlyphs.locateFixed,
              expand: false,
              onPressed: _find,
            ),
      child: Text(
        value == null || value.isEmpty ? '—' : value,
        style: const TextStyle(fontFeatures: AppFonts.tabularFigures),
      ),
    );
  }
}

/// Asks for a question to add to a form, of one of [types]; the question,
/// or null if the sheet is closed.
Future<DynamicFormField?> showAddFieldSheet(
  BuildContext context, {
  required List<FieldType> types,
}) {
  final l10n = context.l10n;
  return showAppSheet<DynamicFormField>(
    context: context,
    title: l10n.inspFormAddField,
    closeLabel: l10n.actionClose,
    builder: (sheet) => _AddField(types: types),
  );
}

class _AddField extends StatefulWidget {
  const _AddField({required this.types});

  final List<FieldType> types;

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  String _label = '';
  late FieldType _type = widget.types.isEmpty
      ? FieldType.text
      : widget.types.first;
  bool _required = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = widget.types.isEmpty ? const [FieldType.text] : widget.types;
    // Scrolls, and rises over the keyboard, as a sheet's body must.
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectionTextInput(
            label: l10n.inspFormFieldLabel,
            value: _label,
            onChanged: (typed) => setState(() => _label = typed),
          ),
          AppSpacing.gapLg,
          InspectionChoiceInput(
            label: l10n.inspFormFieldType,
            options: [for (final t in types) t.name],
            value: _type.name,
            onChanged: (name) =>
                setState(() => _type = types.firstWhere((t) => t.name == name)),
          ),
          AppSpacing.gapMd,
          AppListRow(
            title: l10n.inspFormFieldRequired,
            trailing: AppSwitch(
              value: _required,
              onChanged: (on) => setState(() => _required = on),
            ),
            onTap: () => setState(() => _required = !_required),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: l10n.inspFormAddField,
            leadingGlyph: AppGlyphs.plus,
            onPressed: _label.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(
                    DynamicFormField(
                      key: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      type: _type,
                      label: _label.trim(),
                      validation: FieldValidation(required: _required),
                      isCustom: true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
