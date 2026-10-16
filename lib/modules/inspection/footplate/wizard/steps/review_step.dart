import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/widgets/stored_image.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/selfie_capture_sheet.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';

class ReviewStep extends StatefulWidget {
  final FootplateInspectionData data;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  const ReviewStep({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraft,
  });
  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  Future<void> _takeEndSelfie() async {
    final path = await captureAndConfirmSelfie(
      context,
      title: 'End of Inspection Selfie',
    );
    if (path == null) return;
    setState(() {
      widget.data.endSelfiePath = path;
      widget.data.endSelfieTime = DateTime.now();
    });
    widget.onChanged();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final scheme = Theme.of(context).colorScheme;
    final totalIssues =
        d.locomotive.issueCount +
        d.assetChecks.fold<int>(0, (s, e) => s + e.issueCount);
    final startSelfieTaken = d.startSelfiePath != null;
    final endSelfieTaken = d.endSelfiePath != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Review & Submit',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Double-check the summary below before submitting for review.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _summaryStat(
                context,
                'Assets Checked',
                '${d.assetChecks.length}',
                Icons.checklist,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryStat(
                context,
                'Issues Flagged',
                '$totalIssues',
                totalIssues > 0 ? Icons.error_outline : Icons.check_circle,
                color: totalIssues > 0 ? scheme.error : Colors.green.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Particulars of Train',
          icon: Icons.confirmation_number,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Train No.', d.trainSchedule.trainNo ?? '—'),
              _kv(
                'Load',
                d.trainSchedule.load.isEmpty ? '—' : d.trainSchedule.load,
              ),
              _kv('Engine No.', d.trainSchedule.engineNo ?? '—'),
              _kv("Driver's Name", d.trainSchedule.driver?.display ?? '—'),
              _kv(
                'Assistant Driver',
                d.trainSchedule.assistantDriver?.display ?? '—',
              ),
              _kv(
                'Guard Incharge',
                d.trainSchedule.guardIncharge?.display ?? '—',
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Locomotive Condition',
          icon: Icons.build_circle,
          child: d.locomotive.issueCount == 0
              ? const Text('All items functional.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.locomotive.equipmentStatus.entries
                      .where((e) => e.value.hasIssue)
                      .map((e) => StatusPill(text: e.key, color: scheme.error))
                      .toList(),
                ),
        ),

        SectionCard(
          title: 'Asset Checks (${d.assetChecks.length})',
          icon: Icons.assignment,
          child: d.assetChecks.isEmpty
              ? const Text('No assets recorded.')
              : Column(
                  children: d.assetChecks.map((e) {
                    final fieldLabels = {
                      for (final field in kAssetFieldConfig[e.assetType] ?? [])
                        field.key: field.label,
                    };
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        e.assetType,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${e.answers.length} selected value(s)'),
                      trailing: e.issueCount > 0
                          ? StatusPill(
                              text: '${e.issueCount} flagged',
                              color: scheme.error,
                            )
                          : StatusPill(
                              text: 'OK',
                              color: Colors.green.shade600,
                            ),
                      children: e.answers.entries.map((answer) {
                        final value = answer.value;
                        final displayValue = value is List
                            ? value.join(', ')
                            : value?.toString() ?? 'Not selected';
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 16,
                            right: 4,
                          ),
                          title: Text(
                            fieldLabels[answer.key] ?? _humanizeKey(answer.key),
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: Text(
                              displayValue,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: value == null ? scheme.error : null,
                                  ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
        ),

        SectionCard(
          title: 'Punctuality & OPs',
          icon: Icons.timer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Stations recorded', '${d.punctuality.length}'),
              _kv(
                'Caution orders received',
                d.ops.isEmpty ? 'None' : d.ops.map((o) => o.opCode).join(', '),
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Sign-off',
          icon: Icons.camera_alt,
          subtitle:
              'This inspection is bounded by a start and end selfie for verification.',
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _selfieTile(
                      context,
                      label: 'Inspection Start',
                      taken: startSelfieTaken,
                      imagePath: d.startSelfiePath,
                      timeLabel: _formatTime(d.startSelfieTime),
                      // Already captured before the wizard could be opened.
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selfieTile(
                      context,
                      label: 'Inspection End',
                      taken: endSelfieTaken,
                      imagePath: d.endSelfiePath,
                      timeLabel: _formatTime(d.endSelfieTime),
                      onTap: _takeEndSelfie,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Final Remarks (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: (v) {
                  d.finalRemarks = v;
                  widget.onChanged();
                },
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onSaveDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save as draft'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: (startSelfieTaken && endSelfieTaken)
              ? widget.onSubmit
              : null,
          icon: const Icon(Icons.send),
          label: const Text('Complete & Submit Inspection'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!(startSelfieTaken && endSelfieTaken))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Both start and end pictures are required before submitting.',
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _summaryStat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? scheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  String _humanizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Widget _selfieTile(
    BuildContext context, {
    required String label,
    required bool taken,
    required String? imagePath,
    required String timeLabel,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: taken ? Colors.green.shade600 : scheme.outlineVariant,
            width: taken ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: taken ? Colors.green.shade50 : null,
        ),
        child: Column(
          children: [
            if (taken && imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: StoredImage(path: imagePath),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Icon(
                Icons.camera_alt_outlined,
                color: scheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (taken && timeLabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                timeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (onTap != null) ...[
              const SizedBox(height: 2),
              Text(
                'Tap to capture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
