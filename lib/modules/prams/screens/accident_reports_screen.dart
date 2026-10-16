import 'package:flutter/material.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/extensions/accident_display_extension.dart';
import 'package:railway_hrms/modules/prams/screens/report_accident_screen.dart';
import 'package:railway_hrms/modules/prams/widgets/accident_tile_widget.dart';
import 'package:railway_hrms/modules/prams/widgets/image_preview_widget.dart';

class AccidentReportsScreen extends StatelessWidget {
  final List<Accidents> accidents;
  const AccidentReportsScreen({super.key, required this.accidents});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accident Reports',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              'View and manage all submitted accident reports.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              child: IconButton(
                icon: Icon(Icons.add, color: cs.onPrimary),
                onPressed: () {
                  showModalBottomSheet(
                    showDragHandle: true,
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: cs.surface,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (context, scrollController) {
                        return AccidentReportingScreen(
                          scrollController: scrollController,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: .only(bottom: 16),
        itemCount: accidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _AccidentReportCard(report: accidents[index]);
        },
      ),
    );
  }
}

// ── REUSABLE ACCIDENT CARD WIDGET ───────────────────────────────────────────

class _AccidentReportCard extends StatelessWidget {
  final Accidents report;

  const _AccidentReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      margin: .symmetric(horizontal: 20),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning Badge Icon Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: .start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            // ID, Status & Timestamp Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. Report ID
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      report.accidentId ?? '',
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 2. Status Badge Chip
                                Flexible(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 3,
                                          backgroundColor: cs.onPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            report.status ?? '',
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
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${report.timeLabel} • ${report.dateLabel}',
                                              style: tt.labelSmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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

                  // Details Grid
                  Row(
                    children: [
                      Expanded(
                        child: DetailTile(
                          icon: Icons.train_outlined,
                          label: 'Locomotive Number',
                          value: report.locomotiveNumber,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: DetailTile(
                          icon: Icons.train_outlined,
                          label: 'Train Information',
                          value: report.trainNumber,
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
                          value: report.lastCrossedStationName,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: DetailTile(
                          icon: Icons.straighten_outlined,
                          label: 'Kilometers Number',
                          value: report.kilometerNumber,
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
                          value: report.accidentDateTime,
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: DetailTile(
                          icon: Icons.warning_amber_rounded,
                          label: 'Accident Type',
                          value: report.accidentClassCode.toString(),
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
                                  report.severity ?? '',
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
                          customValue: Row(
                            children: [
                              Expanded(
                                // ← added
                                child: FittedBox(
                                  fit: BoxFit.scaleDown, // ← added, explicit
                                  alignment: Alignment
                                      .centerLeft, // ← added, keep left-aligned
                                  child: Text(
                                    report.incidentLocation,
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (report.photos != null)
                    AccidentPhotoPreview(
                      imageUrls:
                          report.photos
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

            // Card Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

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
                        Text('Submitted by:', style: tt.labelSmall?.copyWith()),
                        Text(
                          report.reporterName.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.accidentTimeline);
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
    );
  }
}
