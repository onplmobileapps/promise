import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/date_ranges.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_types.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The days of a leave type still to take.
num leaveDaysLeft(LeaveTypesRecord type) =>
    (type.allotted - type.consumed).clamp(0, double.infinity);

/// The colour of the [index]th leave type's ring, in a fixed order.
Color leaveRingColor(AppColors colors, int index) => [
  colors.success,
  colors.warningMark,
  colors.infoMark,
  colors.danger,
][index % 4];

/// Each leave type on its own card, side by side: a ring of the days
/// left, "8/10" in its middle, its name, and the days used.
class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({super.key, this.onPick});

  /// Applies for the tapped type of leave.
  final ValueChanged<LeaveTypesRecord>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return BlocBuilder<LeaveCubit, LeaveState>(
      builder: (context, state) {
        final Widget body;
        if (state.fetchStatus == LeaveStatus.error) {
          body = _Problem(
            message: l10n.leaveBalanceFailed,
            onRetry: () => context.read<LeaveCubit>().fetchLeaveLeadger(),
          );
        } else if (state.fetchStatus == LeaveStatus.loaded &&
            state.records.isEmpty) {
          body = _Quiet(l10n.leaveBalanceEmpty);
        } else {
          final loading = state.fetchStatus != LeaveStatus.loaded;
          final types = loading ? _placeholders : state.records;
          // Side by side, one card a type, scrolling when there are many.
          return Skeletonizer(
            enabled: loading,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, type) in types.indexed) ...[
                      if (index > 0) AppSpacing.gapMd,
                      AppInkSurface(
                        decoration: appCardDecoration(context),
                        onTap: loading || onPick == null
                            ? null
                            : () => onPick!(type),
                        child: SizedBox(
                          width: AppSizes.leaveCard,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.md + AppSpacing.xxs,
                            ),
                            child: _Ring(
                              type: type,
                              color: leaveRingColor(colors, index),
                              label: text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return DecoratedBox(
          decoration: appCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md + AppSpacing.xxs,
            ),
            child: body,
          ),
        );
      },
    );
  }

  static final _placeholders = [
    for (var i = 0; i < 3; i++)
      LeaveTypesRecord(
        leaveType: -1,
        leaveTypeName: 'Casual',
        leaveFlag: '',
        allotted: 10,
        remaining: 8,
        consumed: 2,
        status: true,
        applicationPeriod: 0,
        icon: '',
      ),
  ];
}

class _Ring extends StatelessWidget {
  const _Ring({required this.type, required this.color, required this.label});

  final LeaveTypesRecord type;
  final Color color;
  final TextTheme label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = leaveDaysLeft(type);
    final total = type.allotted;
    return Semantics(
      label: l10n.leaveRingLabel(
        type.leaveTypeName,
        formatDays(left),
        formatDays(total),
      ),
      excludeSemantics: true,
      child: Column(
        children: [
          AppRingGauge(
            fraction: total > 0 ? left / total : 0,
            color: color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${formatDays(left)}/${formatDays(total)}',
                  style: label.titleSmall?.copyWith(
                    fontFeatures: AppFonts.tabularFigures,
                  ),
                ),
                Text(
                  l10n.leaveLeftShort,
                  style: label.labelSmall?.copyWith(letterSpacing: 0),
                ),
              ],
            ),
          ),
          AppSpacing.gapXs,
          Text(
            type.leaveTypeName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: label.labelMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: AppFonts.semiBold,
            ),
          ),
          Text(
            l10n.leaveUsed(formatDays(type.consumed)),
            style: label.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The status a request's text stands for.
enum LeaveRequestStatus {
  pending,
  approved,
  rejected;

  static LeaveRequestStatus of(String status) {
    final value = status.toLowerCase();
    if (value.contains('approv')) return approved;
    if (value.contains('reject') || value.contains('declin')) return rejected;
    return pending;
  }

  String label(AppLocalizations l10n) => switch (this) {
    pending => l10n.leaveStatusPending,
    approved => l10n.leaveStatusApproved,
    rejected => l10n.leaveStatusRejected,
  };

  AppTone get tone => switch (this) {
    pending => AppTone.warning,
    approved => AppTone.brand,
    rejected => AppTone.danger,
  };
}

/// A request's days, as "Earned · 3 – 7 Nov".
String leaveRequestTitle(
  AppLocalizations l10n,
  EmpLeaveRecord request,
  String locale,
) {
  final from = DateTime.tryParse(request.fromDate);
  final to = DateTime.tryParse(request.toDate) ?? from;
  final dates = from == null
      ? request.fromDate
      : formatDayRange(from, to ?? from, locale);
  return l10n.leaveRequestTitle(request.leaveName, dates);
}

/// The employee's latest requests, each with how far it has got; "All
/// requests" lists the rest.
class LeaveRequestsCard extends StatelessWidget {
  const LeaveRequestsCard({super.key, this.shown = 2});

  /// How many of the latest to show.
  final int shown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LeaveCubit, LeaveState>(
      buildWhen: (a, b) =>
          a.history != b.history || a.historyStatus != b.historyStatus,
      builder: (context, state) {
        if (state.historyStatus == LeaveStatus.error) {
          return DecoratedBox(
            decoration: appCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _Problem(
                message: l10n.leaveRequestsFailed,
                onRetry: () => context.read<LeaveCubit>().fetchHistory(),
              ),
            ),
          );
        }
        if (state.historyStatus == LeaveStatus.loaded &&
            state.history.isEmpty) {
          return DecoratedBox(
            decoration: appCardDecoration(context),
            child: _Quiet(l10n.leaveRequestsEmpty),
          );
        }
        final loading = state.historyStatus != LeaveStatus.loaded;
        return Skeletonizer(
          enabled: loading,
          child: AppListGroup(
            children: [
              for (final request
                  in (loading ? _placeholders : state.history).take(shown))
                LeaveRequestRow(
                  request: request,
                  onTap: () => showLeaveRequest(context, request),
                ),
            ],
          ),
        );
      },
    );
  }

  static final _placeholders = [
    for (var i = 0; i < 2; i++)
      EmpLeaveRecord(
        leaveID: 0,
        empID: 0,
        sapID: 0,
        firstName: '',
        lastName: '',
        department: '',
        division: '',
        location: '',
        designation: '',
        leaveTypeID: 0,
        leaveName: 'Casual leave',
        remarks: '',
        appliedDate: '2026-10-01',
        fromDate: '2026-10-06',
        toDate: '2026-10-07',
        status: 'Pending',
        appliedBy: '',
      ),
  ];
}

/// One request: its type and days, its status, and how far it has got.
class LeaveRequestRow extends StatelessWidget {
  const LeaveRequestRow({super.key, required this.request, this.onTap});

  final EmpLeaveRecord request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = LeaveRequestStatus.of(request.status);
    final applied = DateTime.tryParse(request.appliedDate);
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + AppSpacing.xxs,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      leaveRequestTitle(l10n, request, locale),
                      style: text.titleSmall,
                    ),
                  ),
                  AppSpacing.gapSm,
                  AppPill(status.label(l10n), tone: status.tone),
                ],
              ),
              AppSpacing.gapSm,
              if (status == LeaveRequestStatus.pending)
                Row(
                  children: [
                    const _RequestSteps(),
                    AppSpacing.gapSmd,
                    Expanded(
                      child: Text(
                        l10n.leaveWaitingManager,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                )
              else if (applied != null)
                Text(
                  l10n.leaveAppliedOn(
                    DateFormat('d MMM', locale).format(applied),
                  ),
                  style: text.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Applied, with the manager, then in the HR record: done, here, to come.
class _RequestSteps extends StatelessWidget {
  const _RequestSteps();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget dot(double size, {Color? fill, Color? ring, Color? edge}) =>
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: edge == null ? null : Border.all(color: edge, width: 2),
            boxShadow: ring == null
                ? null
                : [BoxShadow(color: ring, spreadRadius: 3)],
          ),
          child: SizedBox.square(dimension: size),
        );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot(AppSizes.stepDot - 1, fill: colors.success),
          SizedBox(
            width: AppSpacing.huge,
            height: AppSizes.stepLine,
            child: ColoredBox(color: colors.success),
          ),
          dot(
            AppSizes.stepDot + 1,
            fill: colors.warningMark,
            ring: colors.goldContainer,
          ),
          SizedBox(
            width: AppSpacing.huge,
            height: AppSizes.stepLine,
            child: CustomPaint(painter: _DashPainter(colors.outline)),
          ),
          dot(AppSizes.stepDot - 1, edge: colors.outline),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 4, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Opens a request's details in a sheet.
Future<void> showLeaveRequest(BuildContext context, EmpLeaveRecord request) {
  final l10n = context.l10n;
  return showAppSheet<void>(
    context: context,
    title: l10n.leaveRequestDetails,
    closeLabel: l10n.actionClose,
    builder: (context) => _RequestDetails(request: request),
  );
}

/// Opens every request in a sheet.
Future<void> showAllLeaveRequests(BuildContext context) {
  final l10n = context.l10n;
  final cubit = context.read<LeaveCubit>();
  return showAppSheet<void>(
    context: context,
    title: l10n.leaveAllRequests,
    closeLabel: l10n.actionClose,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<LeaveCubit, LeaveState>(
        builder: (context, state) => state.history.isEmpty
            ? _Quiet(
                state.historyStatus == LeaveStatus.error
                    ? l10n.leaveRequestsFailed
                    : l10n.leaveRequestsEmpty,
              )
            : SingleChildScrollView(
                child: AppListGroup(
                  children: [
                    for (final request in state.history)
                      LeaveRequestRow(
                        request: request,
                        onTap: () => showLeaveRequest(context, request),
                      ),
                  ],
                ),
              ),
      ),
    ),
  );
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails({required this.request});

  final EmpLeaveRecord request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = LeaveRequestStatus.of(request.status);
    final from = DateTime.tryParse(request.fromDate);
    final to = DateTime.tryParse(request.toDate) ?? from;
    final applied = DateTime.tryParse(request.appliedDate);
    Widget glyph(AppGlyph glyph) =>
        AppGlyphIcon(glyph, size: AppSizes.glyphRow, color: colors.iconAccent);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppListGroup(
            children: [
              AppListRow(
                leading: glyph(AppGlyphs.fileEdit),
                title: l10n.leaveDetailType,
                trailing: Text(request.leaveName),
              ),
              if (from != null)
                AppListRow(
                  leading: glyph(AppGlyphs.calendar),
                  title: l10n.leaveDetailDates,
                  trailing: Text(formatDayRange(from, to ?? from, locale)),
                ),
              AppListRow(
                leading: glyph(AppGlyphs.hourglass),
                title: l10n.leaveDetailStatus,
                trailing: AppPill(status.label(l10n), tone: status.tone),
              ),
              if (applied != null)
                AppListRow(
                  leading: glyph(AppGlyphs.clock),
                  title: l10n.leaveDetailApplied,
                  trailing: Text(DateFormat('d MMM y', locale).format(applied)),
                ),
            ],
          ),
          if (request.remarks.isNotEmpty) ...[
            AppSpacing.gapLg,
            AppSectionLabel(l10n.leaveDetailReason),
            AppSpacing.gapSm,
            Text(request.remarks, style: context.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// A quiet line in place of what isn't there.
class _Quiet extends StatelessWidget {
  const _Quiet(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: context.textTheme.bodyMedium,
    ),
  );
}

/// Something failed to load, with a way to try again.
class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onDangerContainer,
              fontWeight: AppFonts.semiBold,
            ),
          ),
        ),
        AppButton(
          label: l10n.actionRetry,
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
          expand: false,
          underlined: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
