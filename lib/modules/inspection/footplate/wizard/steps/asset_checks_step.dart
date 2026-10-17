import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/template_form.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/validator.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/station_asset_inspection_step.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// The kinds of asset passed on the run, each checked on a sheet of its
/// own questions; the track's come from its form template.
class AssetChecksStep extends StatefulWidget {
  const AssetChecksStep({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<AssetCheckEntry> entries;
  final VoidCallback onChanged;

  @override
  State<AssetChecksStep> createState() => _AssetChecksStepState();
}

class _AssetChecksStepState extends State<AssetChecksStep> {
  @override
  void initState() {
    super.initState();
    // One entry per kind, in order, keeping any a draft brought back.
    final kept = {for (final e in widget.entries) e.assetType: e};
    widget.entries
      ..clear()
      ..addAll([
        for (final type in kAssetTypes)
          kept[type] ?? AssetCheckEntry(assetType: type),
      ]);
  }

  Future<void> _check(AssetCheckEntry entry) async {
    final checked = await showAppSheet<AssetCheckEntry>(
      context: context,
      title: entry.assetType,
      closeLabel: context.l10n.actionClose,
      builder: (_) => _AssetSheet(entry: entry),
    );
    if (checked == null) return;
    setState(() {
      widget.entries[widget.entries.indexOf(entry)] = checked;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Check each asset in turn and pick what you saw for every question.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        AppSpacing.gapMd,
        AppListGroup(
          children: [
            for (final entry in widget.entries)
              AppListRow(
                leading: AppIconTile(
                  size: AppSizes.rowTile,
                  child: AppGlyphIcon(
                    footplateAssetGlyph(entry.assetType),
                    size: AppSizes.iconMd,
                    color: colors.iconAccent,
                    depth: true,
                  ),
                ),
                title: entry.assetType,
                subtitle: entry.answers.isEmpty
                    ? 'Not checked yet'
                    : entry.issueCount == 0
                    ? 'In order'
                    : '${entry.issueCount} flagged',
                trailing: entry.answers.isEmpty
                    ? null
                    : AppPill(
                        entry.issueCount == 0 ? 'OK' : '${entry.issueCount}',
                        tone: entry.issueCount == 0
                            ? AppTone.brand
                            : AppTone.danger,
                      ),
                showChevron: entry.answers.isEmpty,
                onTap: () => _check(entry),
              ),
          ],
        ),
      ],
    );
  }
}

class _AssetSheet extends StatefulWidget {
  const _AssetSheet({required this.entry});

  final AssetCheckEntry entry;

  @override
  State<_AssetSheet> createState() => _AssetSheetState();
}

class _AssetSheetState extends State<_AssetSheet> {
  late bool _civil = widget.entry.civilDept;
  late final Map<String, dynamic> _answers = {...widget.entry.answers};
  FormTemplate? _template;
  final FormData _form = FormData();

  @override
  void initState() {
    super.initState();
    if (widget.entry.assetType == 'Track') _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/forms/track_inspection_template.json',
      );
      final template = FormTemplate.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _answers.forEach(_form.setValue);
      if (mounted) setState(() => _template = template);
    } on Object catch (e) {
      debugPrint('Track template could not be read: $e');
    }
  }

  bool _shows(RadioFieldConfig field) {
    final key = field.showIfKey;
    if (key == null) return true;
    if (key == '_civil') return _civil && field.showIfValue == 'yes';
    return _answers[key] == field.showIfValue;
  }

  void _save() {
    final template = _template;
    if (template != null) {
      final errors = FieldValidator.validateForm(template, _form)
        // The face check at submit is the signature.
        ..removeWhere(
          (key, _) => template.getFieldByKey(key)?.type == FieldType.signature,
        );
      if (errors.isNotEmpty) {
        setState(
          () => _form.errors
            ..clear()
            ..addAll(errors),
        );
        return;
      }
      _answers
        ..clear()
        ..addAll(_form.values);
    }
    Navigator.of(context).pop(
      AssetCheckEntry(assetType: widget.entry.assetType, civilDept: _civil)
        ..answers.addAll(_answers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final template = _template;
    final fields = kAssetFieldConfig[widget.entry.assetType] ?? const [];
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.entry.assetType == 'Track') ...[
            AppListRow(
              title: 'Conducted by Civil Department',
              subtitle: 'Adds rails, joints, ballast, sleepers and boundary',
              trailing: AppSwitch(
                value: _civil,
                onChanged: (on) => setState(() => _civil = on),
              ),
              onTap: () => setState(() => _civil = !_civil),
            ),
            AppSpacing.gapMd,
          ],
          if (template != null) ...[
            TemplateFormBody(
              template: template,
              formData: _form,
              onChanged: () => setState(() {}),
            ),
            if (template.allowCustomFields)
              AppButton(
                label: l10n.inspFormAddField,
                variant: AppButtonVariant.secondary,
                leadingGlyph: AppGlyphs.plus,
                onPressed: () async {
                  final field = await showAddFieldSheet(
                    context,
                    types: template.customFieldTypes,
                  );
                  if (field == null || !mounted) return;
                  setState(() => template.sections.last.fields.add(field));
                },
              ),
          ] else
            for (final field in fields.where(_shows)) ...[
              InspectionChoiceInput(
                label: field.label,
                options: field.options,
                value: _answers[field.key] as String?,
                toneOf: (option) => option == field.options.first
                    ? AppTone.brand
                    : answerTone(option),
                onChanged: (picked) =>
                    setState(() => _answers[field.key] = picked),
              ),
              AppSpacing.gapMd,
            ],
          AppSpacing.gapLg,
          AppButton(
            label: l10n.inspFormDone,
            leadingGlyph: AppGlyphs.check,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
