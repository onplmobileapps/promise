import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/widgets/form_widgets.dart';
import 'package:railway_hrms/modules/prams/bloc/incident_photo_cubit.dart';

export 'package:railway_hrms/modules/prams/screens/accident_report_form.dart';

// ── NEW: SEVERITY COLOR HELPER ────────────────────────────────────────────

Color severityColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'critical':
      return const Color(0xFFDC2626);
    case 'major':
      return const Color(0xFFEA580C);
    case 'medium':
      return const Color(0xFFD97706);
    case 'minor':
      return const Color(0xFF16A34A);
    default:
      return Colors.grey;
  }
}

// ── NEW: PICKER FIELD (wraps to 2 lines instead of clipping) ──────────────

class PickerField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  const PickerField({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppFormStyle.inputRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          isDense: true,
          contentPadding: AppFormStyle.fieldPadding,
        ),
        child: Text(
          hasValue ? value! : hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: hasValue ? theme.colorScheme.onSurface : theme.hintColor,
          ),
        ),
      ),
    );
  }
}

// ── NEW: READ-ONLY SEVERITY DISPLAY ───────────────────────────────────────

class SeverityReadOnlyField extends StatelessWidget {
  final String? severity;
  const SeverityReadOnlyField({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final has = severity != null && severity!.isNotEmpty;
    final color = severityColor(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppFormStyle.inputRadius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          if (!has)
            Expanded(
              child: Text(
                'Set automatically from classification',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        severity!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

// ── NEW: CONDITION SWITCH TILE ────────────────────────────────────────────

class ConditionSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedChild;

  const ConditionSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
    this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.07) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: value ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: color,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: (value && expandedChild != null)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: expandedChild,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── NEW: CLASSIFICATION BOTTOM SHEET ──────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 2: RELIEF OPERATIONS SCREEN
// ══════════════════════════════════════════════════════════════════════════

class ReliefOperationsScreen extends StatelessWidget {
  const ReliefOperationsScreen({super.key});

  static const List<String> _truckOptions = [
    'Truck-101 (Emergency Response)',
    'Truck-102 (Medical Unit)',
    'Truck-103 (Heavy Equipment)',
  ];

  static const List<String> _locomotiveOptions = [
    'Loco-4001 (6000 HP)',
    'Loco-4002 (4000 HP)',
    'Loco-6010 (2000 HP)',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Local state variables (live only while this screen is mounted)
    String selectedOption = 'truck';
    String? selectedTruck;
    String? selectedLocomotive;

    return Scaffold(
      appBar: const FormAppBar(title: 'Relief Operations'),
      body: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatch Relief Units',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Assign active emergency resources to the site',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dispatch Mode
                FormGroup(
                  label: 'Select Dispatch Mode',
                  child: Container(
                    decoration: AppFormStyle.cardDecoration(context),
                    child: Column(
                      children: [
                        RadioGroup(
                          groupValue: selectedOption,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                selectedOption = v;
                                selectedLocomotive = null; // clear other
                              });
                            }
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: RadioListTile<String>(
                              title: Text(
                                'Relief Truck',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: 'truck',
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        RadioGroup(
                          groupValue: selectedOption,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                selectedOption = v;
                                selectedTruck = null; // clear other
                              });
                            }
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: RadioListTile<String>(
                              title: Text(
                                'Relief Train',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: 'train',
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Conditional dropdown
                if (selectedOption == 'truck')
                  FormGroup(
                    label: 'Assigned Truck',
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedTruck,
                      hint: const Text('Select Truck Unit'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.local_shipping_outlined,
                          size: 20,
                        ),
                        isDense: true,
                      ),
                      items: _truckOptions
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedTruck = v),
                    ),
                  )
                else
                  FormGroup(
                    label: 'Assigned Locomotive',
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedLocomotive,
                      hint: const Text('Select Engine Unit'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.train_outlined, size: 20),
                        isDense: true,
                      ),
                      items: _locomotiveOptions
                          .map(
                            (l) => DropdownMenuItem(value: l, child: Text(l)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedLocomotive = v),
                    ),
                  ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReliefDetailsFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Dispatch Resource'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 3: RELIEF DETAILS FORM SCREEN
// ══════════════════════════════════════════════════════════════════════════

class ReliefDetailsFormScreen extends StatefulWidget {
  const ReliefDetailsFormScreen({super.key});

  @override
  State<ReliefDetailsFormScreen> createState() =>
      _ReliefDetailsFormScreenState();
}

class _ReliefDetailsFormScreenState extends State<ReliefDetailsFormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const FormAppBar(title: 'Recovery Operations'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormGroup(
                label: 'Operation Name',
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'e.g. Operation Alpha Rescue',
                    prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              FormGroup(
                label: 'Estimated Passengers Onboard',
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Total head count',
                    prefixIcon: Icon(Icons.groups_outlined, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Injured + Critical
              ResponsiveFieldGroup(
                left: FormGroup(
                  label: 'Injured',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(
                        Icons.personal_injury_outlined,
                        size: 18,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                right: FormGroup(
                  label: 'Critical / Severe',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(
                        Icons.accessible_forward_rounded,
                        size: 18,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Deceased + Missing
              ResponsiveFieldGroup(
                left: FormGroup(
                  label: 'Deceased',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.heart_broken_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                right: FormGroup(
                  label: 'Missing Persons',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.person_search_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Employee Injured + Deceased
              ResponsiveFieldGroup(
                left: FormGroup(
                  label: 'Injured Employees',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                right: FormGroup(
                  label: 'Deceased Employees',
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              FormGroup(
                label: 'Public Casualties',
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Total non-passenger casualties',
                    prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              FormGroup(
                label: 'Emergency Response (ER) Speed',
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Target deployment speed',
                    prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                    isDense: true,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1.0,
                        child: Text(
                          'KM/H',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showAppMessage(
                      context,
                      'Relief Details Recorded',
                      tone: AppDialogTone.success,
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Save Operation Record'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── UPLOAD MEDIA CARD ─────────────────────────────────────────────────────
// Uses the IncidentPhotosCubit provided by AccidentReportingScreen.

class DottedUploadCard extends StatelessWidget {
  const DottedUploadCard({super.key});

  void _showPickerOptionSheet(BuildContext context) {
    final cubit = context.read<IncidentPhotosCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    cubit.pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    cubit.captureFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<IncidentPhotosCubit, IncidentPhotosState>(
      builder: (context, state) {
        final bool hasPhotos = state.photos.isNotEmpty;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppFormStyle.inputRadius),
            border: Border.all(
              color: state.canAddMore
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              if (state.isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: AppLoader(size: AppSizes.loaderSmall),
                ),
              ] else if (!hasPhotos) ...[
                // Empty State Drop Zone
                InkWell(
                  onTap: () => _showPickerOptionSheet(context),
                  borderRadius: BorderRadius.circular(AppFormStyle.inputRadius),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Incident Photos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attach up to 5 clear photos (JPG, PNG • Max 5MB)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Thumbnails + "Add More" tile
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.photos.length + (state.canAddMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == state.photos.length) {
                        return InkWell(
                          onTap: () => _showPickerOptionSheet(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add More',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final photo = state.photos[index];
                      return Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(photo),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            context.read<IncidentPhotosCubit>().removePhotoAt(
                              index,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: theme.colorScheme.onError,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uploaded Photos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${state.photos.length}/5',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state.canAddMore
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
