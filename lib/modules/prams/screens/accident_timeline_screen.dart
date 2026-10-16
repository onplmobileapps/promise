import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

class AccidentTimelineScreen extends StatelessWidget {
  const AccidentTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final List<_TimelineItemData> items = [
      _TimelineItemData(
        title: 'Accident area clear',
        statusType: _TimelineStatusType.warning,
        icon: Icons.assignment_outlined,
        time: '10:20 AM',
        date: '13 Aug 2026',
        description: 'Site inspection has been conducted.',
        byLabel: 'Inspected by:',
        byValue: 'Sub Inspector Farhan',
        role: 'Role: Railway Police',
      ),
      _TimelineItemData(
        title: 'Relief Train Arrived',
        statusType: _TimelineStatusType.tertiary,
        icon: Icons.train_outlined,
        time: '10:05 AM',
        date: '13 Aug 2026',
        description: 'Truck reached at accident location',
        byLabel: 'Assigned to:',
        byValue: 'Safety Investigation Team',
        role: 'Division: Lahore Division',
      ),
      _TimelineItemData(
        title: 'Relief Dispatched',
        statusType: _TimelineStatusType.secondary,
        icon: Icons.local_shipping_outlined,
        time: '09:41 AM',
        date: '13 Aug 2026',
        description: 'Truck dispatched for accident location',
        byLabel: 'Reviewed by:',
        byValue: 'Divisional Safety Officer',
        role: 'Role: DSO Lahore Division',
      ),
      _TimelineItemData(
        title: 'Acknowledged',
        statusType: _TimelineStatusType.primary,
        icon: Icons.check_circle_rounded,
        time: '09:32 AM',
        date: '13 Aug 2026',
        description: 'The accident report has been acknowledged.',
        byLabel: 'Acknowledged by:',
        byValue: 'Inspector Ahmed Khan',
        role: 'Role: Safety Inspector',
      ),
      _TimelineItemData(
        title: 'Accident Reported',
        statusType: _TimelineStatusType.primary,
        icon: Icons.assignment_turned_in_rounded,
        time: '09:25 AM',
        date: '13 Aug 2026',
        description: 'Accident report has been submitted.',
        byLabel: 'Reported by:',
        byValue: 'Muhammad Ali',
        role: 'Role: Train Operator',
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        leading: const Center(child: AppBackButton()),
        title: Text('Timeline', style: tt.headlineSmall?.copyWith()),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: cs.primary),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accident Timeline Updates',
                        style: tt.titleLarge?.copyWith(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time updates for Accident Report #AR-024',
                        style: tt.bodyMedium?.copyWith(),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: cs.primary,
                  ),
                  label: Text(
                    'Mark read',
                    style: tt.labelMedium?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Timeline List
            ListView.builder(
              padding: .zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _TimelineTile(
                  data: items[index],
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                );
              },
            ),

            // Info Card at Bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will receive a notification for every important update related to this accident report.',
                      style: tt.bodySmall?.copyWith(),
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

// ── TIMELINE STATUS ENUM ─────────────────────────────────────────────────────

enum _TimelineStatusType { primary, secondary, tertiary, warning }

// ── TIMELINE DATA MODEL ──────────────────────────────────────────────────────

class _TimelineItemData {
  final String title;
  final _TimelineStatusType statusType;
  final IconData icon;
  final String time;
  final String date;
  final String description;
  final String byLabel;
  final String byValue;
  final String role;

  _TimelineItemData({
    required this.title,
    required this.statusType,
    required this.icon,
    required this.time,
    required this.date,
    required this.description,
    required this.byLabel,
    required this.byValue,
    required this.role,
  });

  // Solid dark background color for icon step node
  Color getDarkNodeBg(ColorScheme cs) {
    switch (statusType) {
      case _TimelineStatusType.primary:
        return cs.primary;
      case _TimelineStatusType.secondary:
        return cs.secondary;
      case _TimelineStatusType.tertiary:
        return cs.tertiary;
      case _TimelineStatusType.warning:
        return cs.error;
    }
  }

  // Text accent color matching status
  Color getStatusTextColor(ColorScheme cs) {
    switch (statusType) {
      case _TimelineStatusType.primary:
        return cs.primary;
      case _TimelineStatusType.secondary:
        return cs.secondary;
      case _TimelineStatusType.tertiary:
        return cs.tertiary;
      case _TimelineStatusType.warning:
        return cs.error;
    }
  }

  // Icon color inside solid dark node
  Color getNodeIconColor(ColorScheme cs) {
    switch (statusType) {
      case _TimelineStatusType.primary:
        return cs.onPrimary;
      case _TimelineStatusType.secondary:
        return cs.onSecondary;
      case _TimelineStatusType.tertiary:
        return cs.onTertiary;
      case _TimelineStatusType.warning:
        return cs.onError;
    }
  }
}

// ── TIMELINE TILE WIDGET ─────────────────────────────────────────────────────

class _TimelineTile extends StatelessWidget {
  final _TimelineItemData data;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.data,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final darkNodeBg = data.getDarkNodeBg(cs);
    final nodeIconColor = data.getNodeIconColor(cs);
    final statusTextColor = data.getStatusTextColor(cs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line & Darkened Node Icon Column
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Connecting Vertical Line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? 24 : 0,
                  child: Container(width: 3, color: cs.outlineVariant),
                ),
                // Solid Dark Icon Node
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: darkNodeBg,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: darkNodeBg.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, color: nodeIconColor, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                spacing: 4,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Timestamp Row (Aligned to center)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Group: Bullet + Title
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: statusTextColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.title,
                                style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Group: Uniform Time & Date Badge; it shrinks
                      // rather than push the title out on a narrow screen.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  data.time,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '•',
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.outline,
                                    ),
                                  ),
                                ),
                                Text(
                                  data.date,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  Text(
                    data.description,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                  // User Action Line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${data.byLabel} ',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          data.byValue,
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Role Text
                  Text(data.role, style: tt.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
