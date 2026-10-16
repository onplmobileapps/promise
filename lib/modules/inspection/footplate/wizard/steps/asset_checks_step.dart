import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/custom_field_dialog.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/form_renderer.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/models.dart';
import 'package:railway_hrms/modules/inspection/footplate/dynamic_form/validator.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';

class AssetChecksStep extends StatefulWidget {
  final List<AssetCheckEntry> entries;
  final VoidCallback onChanged;
  const AssetChecksStep({
    super.key,
    required this.entries,
    required this.onChanged,
  });
  @override
  State<AssetChecksStep> createState() => _AssetChecksStepState();
}

class _AssetChecksStepState extends State<AssetChecksStep> {
  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  void _initializeChecklist() {
    final existingByType = {
      for (final entry in widget.entries) entry.assetType: entry,
    };
    widget.entries
      ..clear()
      ..addAll(
        kAssetTypes.map(
          (type) => existingByType[type] ?? AssetCheckEntry(assetType: type),
        ),
      );
  }

  void _openAssetForm({AssetCheckEntry? existing}) async {
    final result = await showModalBottomSheet<AssetCheckEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssetFormSheet(existing: existing, lockAssetType: true),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = widget.entries.indexOf(existing);
          widget.entries[idx] = result;
        } else {
          widget.entries.add(result);
        }
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Asset Checks',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Complete each asset in order. Select the observed value for every field before continuing.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ...widget.entries.asMap().entries.map(
          (item) => _AssetEntryCard(
            sequence: item.key + 1,
            entry: item.value,
            onTap: () => _openAssetForm(existing: item.value),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _AssetEntryCard extends StatelessWidget {
  final int sequence;
  final AssetCheckEntry entry;
  final VoidCallback onTap;

  const _AssetEntryCard({
    required this.sequence,
    required this.entry,
    required this.onTap,
  });

  IconData _iconFor(String type) {
    switch (type) {
      case 'Signal':
        return Icons.traffic;
      case 'Track':
        return Icons.linear_scale;
      case 'Tunnel':
        return Icons.landscape;
      case 'Bridge':
        return Icons.architecture;
      case 'Curve':
        return Icons.turn_right;
      default:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fields = kAssetFieldConfig[entry.assetType] ?? [];
    final markedCount = entry.answers.length;
    final isComplete = fields.isNotEmpty && markedCount >= fields.length;
    final issues = entry.issueCount;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '$sequence',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(_iconFor(entry.assetType), color: scheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.assetType,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$markedCount/${fields.length} values marked${entry.civilDept ? ' • Civil dept.' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusPill(
              text: isComplete
                  ? (issues > 0 ? '$issues issue(s)' : 'OK')
                  : 'Mark',
              color: isComplete && issues == 0
                  ? Colors.green.shade600
                  : scheme.primary,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AssetFormSheet extends StatefulWidget {
  final AssetCheckEntry? existing;
  final bool lockAssetType;

  const _AssetFormSheet({this.existing, this.lockAssetType = false});

  @override
  State<_AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<_AssetFormSheet> {
  late String assetType = widget.existing?.assetType ?? kAssetTypes.first;
  late bool civilDept = widget.existing?.civilDept ?? false;
  late Map<String, dynamic> answers = Map.of(widget.existing?.answers ?? {});

  // Dynamic form support
  FormTemplate? _formTemplate;
  final FormData _formData = FormData();
  bool _useDynamicForm = false;

  @override
  void initState() {
    super.initState();
    _loadFormTemplate();
  }

  Future<void> _loadFormTemplate() async {
    if (assetType == 'Track') {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/forms/track_inspection_template.json',
        );
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        setState(() {
          _formTemplate = FormTemplate.fromJson(jsonData);
          _useDynamicForm = true;
          // Initialize form data with existing answers
          for (final key in answers.keys) {
            _formData.setValue(key, answers[key]);
          }
        });
      } catch (e) {
        debugPrint('Error loading form template: $e');
      }
    }
  }

  void _handleCustomFieldAdded(DynamicFormField field) {
    setState(() {
      _formTemplate?.sections.last.fields.add(field);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fields = kAssetFieldConfig[assetType] ?? [];

    bool isVisible(RadioFieldConfig f) {
      if (f.showIfKey == null) return true;
      if (f.showIfKey == '_civil') {
        return civilDept ? (f.showIfValue == 'yes') : false;
      }
      return answers[f.showIfKey] == f.showIfValue;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? 'Add Asset Check'
                              : 'Edit Asset Check',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      Text(
                        'Asset Type',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kAssetTypes.map((t) {
                          final selected = assetType == t;
                          return ChoiceChip(
                            label: Text(t),
                            selected: selected,
                            onSelected: widget.lockAssetType
                                ? null
                                : (_) async {
                                    setSheetState(() {
                                      assetType = t;
                                      answers = {};
                                    });
                                    await _loadFormTemplate();
                                  },
                          );
                        }).toList(),
                      ),
                      if (assetType == 'Track') ...[
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Conducted by Civil Department?'),
                          subtitle: const Text(
                            'Reveals Rails, Rail Joints, Ballast, Sleepers & Boundary checks',
                          ),
                          value: civilDept,
                          onChanged: (v) => setSheetState(() => civilDept = v),
                        ),
                      ],
                      const SizedBox(height: 6),
                      const Divider(),
                      const SizedBox(height: 6),

                      // Use dynamic form for Track type, otherwise use legacy form
                      if (_useDynamicForm && _formTemplate != null) ...[
                        DynamicFormRenderer(
                          template: _formTemplate!,
                          formData: _formData,
                          onChanged: () {
                            // Sync form data back to answers
                            setSheetState(() {
                              answers
                                ..clear()
                                ..addAll(_formData.values);
                            });
                          },
                        ),
                        if (_formTemplate!.allowCustomFields)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => CustomFieldDialog(
                                    allowedTypes:
                                        _formTemplate!.customFieldTypes,
                                    onFieldAdded: _handleCustomFieldAdded,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Custom Field'),
                            ),
                          ),
                      ] else
                        ...fields
                            .where(isVisible)
                            .map(
                              (f) => RadioChipGroup(
                                label: f.label,
                                options: f.options,
                                value: answers[f.key] as String?,
                                onChanged: (v) =>
                                    setSheetState(() => answers[f.key] = v),
                              ),
                            ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      // Validate dynamic form if in use
                      if (_useDynamicForm && _formTemplate != null) {
                        final errors = FieldValidator.validateForm(
                          _formTemplate!,
                          _formData,
                        );
                        if (errors.isNotEmpty) {
                          // Show errors in form data
                          _formData.errors.clear();
                          _formData.errors.addAll(errors);
                          setState(() {});
                          showAppMessage(
                            context,
                            'Please fix validation errors before saving',
                            tone: AppDialogTone.warning,
                          );
                          return;
                        }
                      }

                      final entry = AssetCheckEntry(
                        assetType: assetType,
                        civilDept: civilDept,
                      );
                      entry.answers.addAll(answers);
                      Navigator.pop(context, entry);
                    },
                    child: Text(
                      widget.existing == null
                          ? 'Add to Inspection'
                          : 'Save Changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
