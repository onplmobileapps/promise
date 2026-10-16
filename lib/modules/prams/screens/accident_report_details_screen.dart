import 'package:flutter/material.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/extensions/accident_display_extension.dart';
import 'package:railway_hrms/modules/prams/widgets/accident_tile_widget.dart';
import 'package:railway_hrms/modules/prams/widgets/image_preview_widget.dart';

class AccidentReportDetailsScreen extends StatelessWidget {
  final Accidents accident;
  const AccidentReportDetailsScreen({super.key, required this.accident});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Accident Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: cs.onErrorContainer,
                              size: 38,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Accident Report',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.more_vert,
                                      color: cs.outline,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // ID, Status & Timestamp Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          accident.accidentId ??
                                              '# Accident Id',

                                          style: tt.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 3,
                                              backgroundColor: cs.onPrimary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                accident.status?.toString() ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: tt.labelSmall?.copyWith(
                                                  color: cs.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DetailTile(
                              icon: Icons.train_outlined,
                              label: 'Locomotive Number',
                              value: accident.locomotiveNumber ?? 'N/A',
                            ),
                          ),
                          const VerticalDivider(),
                          Expanded(
                            child: DetailTile(
                              icon: Icons.train_outlined,
                              label: 'Train Information',
                              value:
                                  '${accident.trainNumber} (${accident.trainName})',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DetailTile(
                              icon: Icons.home_work_outlined,
                              label: 'Last Station',
                              value: accident.lastCrossedStationName,
                            ),
                          ),
                          const VerticalDivider(),
                          Expanded(
                            child: DetailTile(
                              icon: Icons.straighten_outlined,
                              label: 'Kilometers Number',
                              value:
                                  accident.kilometerNumber?.toString() ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DetailTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Date & Time of Incident',
                              value:
                                  "${accident.dateLabel} ${accident.timeLabel}",
                            ),
                          ),
                          const VerticalDivider(),
                          Expanded(
                            child: DetailTile(
                              icon: Icons.warning_amber_rounded,
                              label: 'Accident Type',
                              value: accident.accidentClassCode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DetailTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Accident Severity',
                              customValue: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: cs.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      accident.severity ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const VerticalDivider(),
                          Expanded(
                            child: DetailTile(
                              icon: Icons.location_on_outlined,
                              label: 'Location / Station',
                              customValue: Text(
                                accident.incidentLocation,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image Section
                      if (accident.photos != null)
                        AccidentPhotoPreview(
                          imageUrls:
                              accident.photos
                                  ?.map(
                                    (e) =>
                                        "https://pakistanrailway.org${e.file ?? ''}",
                                  )
                                  .toList() ??
                              [],
                        ),
                    ],
                  ),
                ),

                // Remarks box
                if (accident.description?.isNotEmpty ?? false)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            accident.description ?? '',
                            style: tt.bodySmall?.copyWith(
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Card Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: cs.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted by:',
                              style: tt.labelSmall?.copyWith(color: cs.primary),
                            ),
                            Text(
                              accident.reporterName ?? '',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.accidentTimeline,
                            arguments: accident.accidentId,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: cs.surface,
                          side: BorderSide(color: cs.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        label: Text(
                          'View timeline',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
