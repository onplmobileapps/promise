import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/sized_network_image.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/screens/apply_leave_view.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_download_sheet.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Months back the picker offers, this one included.
const _monthsOffered = 12;

/// Half an hour either side of a shift, so its ends show on a day's bar.
const _shiftMargin = Duration(minutes: 30);

/// A working day's bar when the shift isn't known: 07:00 to 20:00.
const _dayStartHour = 7;
const _dayEndHour = 20;

/// The employee's attendance month by month: how many days went which way,
/// the month on a calendar coloured by them, and a picked day's times.
class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({super.key, this.onBack, this.now});

  /// Goes back; there is no back tile without it.
  final VoidCallback? onBack;

  /// The clock; the device's by default.
  final DateTime Function()? now;

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late DateTime _month = _monthOf(_now());
  DateTime? _picked;

  /// The kind of day the records are filtered to; all when null.
  AttendanceMark? _filter;

  /// Every record shows, not only the latest few.
  bool _showAll = false;

  static DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);

  bool get _isThisMonth => _month == _monthOf(_now());

  Future<void> _pickMonth() async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = _now();
    final picked = await showAppOptionsSheet<DateTime>(
      context: context,
      title: l10n.attendancePickMonth,
      options: [
        for (var back = 0; back < _monthsOffered; back++)
          DateTime(today.year, today.month - back),
      ],
      optionLabel: (month) => DateFormat.yMMMM(locale).format(month),
      selected: _month,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _month = picked;
      _picked = null;
      _filter = null;
      _showAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = BlocBuilder<AttendanceCubit, AttendanceState>(builder: _page);
    // Inside HRMS, this month is the one the home shows too.
    if (_isThisMonth) {
      final shared = _maybeRead<AttendanceCubit>(context);
      if (shared != null) return BlocProvider.value(value: shared, child: page);
    }
    final repository = _maybeRead<EmployeeAttendanceRepository>(context);
    return BlocProvider(
      key: ValueKey(_month),
      create: (_) => AttendanceCubit(
        repository ??
            EmployeeAttendanceRepositoryImpl(
              EmployeeAttendanceRemoteDataSourceImpl(DioClient()),
            ),
        month: _isThisMonth ? null : _month,
      )..fetchAttendance(),
      child: page,
    );
  }

  static T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Widget _page(BuildContext context, AttendanceState state) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = _now();
    final today = DateUtils.dateOnly(now);
    final records = state is AttendanceLoaded
        ? state.records
        : const <AttendanceRecord>[];
    final days = attendanceDaysOf(_month, records, today: today);
    int count(AttendanceMark mark) =>
        days.where((day) => day.mark == mark).length;
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final picked =
        _picked ??
        (lastDay.isAfter(today) ? today : DateUtils.dateOnly(lastDay));
    final marks = {for (final day in days) day.day: day.mark};
    final loading = state is AttendanceInitial || state is AttendanceLoading;

    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        onRefresh: () =>
            context.read<AttendanceCubit>().fetchAttendance(silent: true),
        children: [
          AppHeaderBar(
            large: true,
            title: l10n.attendanceTitle,
            onBack: widget.onBack,
            actions: [
              AppButton(
                label: DateFormat.yMMM(locale).format(_month),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                trailingGlyph: AppGlyphs.chevronDown,
                expand: false,
                onPressed: _pickMonth,
              ),
            ],
          ),
          AppSpacing.gapLg,
          AppFeatureCard(
            glyph: AppGlyphs.download,
            title: l10n.downloadCardTitle,
            message: l10n.downloadCardMessage,
            tags: [
              l10n.downloadMonthly,
              l10n.downloadTagAnyDates,
              l10n.downloadTagLeaves,
            ],
            actionLabel: l10n.downloadButton,
            actionGlyph: AppGlyphs.download,
            onPressed: () => showAttendanceDownload(context),
          ),
          AppSpacing.gapLg,
          Skeletonizer(
            enabled: loading,
            // Tapping a count shows only those days in the records below.
            child: AppStatFilter<AttendanceMark>(
              selected: _filter,
              onSelected: (mark) => setState(() {
                _filter = mark;
                _showAll = false;
              }),
              options: [
                for (final (mark, label, color, tint) in [
                  (
                    AttendanceMark.onTime,
                    l10n.attendanceOnTime,
                    colors.primaryShade,
                    colors.dayPresent,
                  ),
                  (
                    AttendanceMark.late,
                    l10n.attendanceLate,
                    colors.dayLateEdge,
                    colors.dayLate,
                  ),
                  (
                    AttendanceMark.leave,
                    l10n.attendanceLeave,
                    colors.infoMark,
                    colors.dayLeave,
                  ),
                  (
                    AttendanceMark.absent,
                    l10n.attendanceAbsent,
                    colors.danger,
                    colors.dangerContainer,
                  ),
                ])
                  AppStatOption(
                    value: mark,
                    label: label,
                    count: count(mark),
                    color: color,
                    tint: tint,
                  ),
              ],
            ),
          ),
          if (state is AttendanceError) ...[
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.attendanceFailed,
                    style: text.bodySmall?.copyWith(
                      color: colors.onDangerContainer,
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
                  onPressed: () =>
                      context.read<AttendanceCubit>().fetchAttendance(),
                ),
              ],
            ),
          ],
          AppSpacing.gapMd,
          AppCard.glass(
            padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
            child: AppMonthCalendar(
              month: _month,
              rowGap: AppSpacing.xs + AppSpacing.xxs,
              columnGap: AppSpacing.xs + AppSpacing.xxs,
              dayBuilder: (context, day, inMonth) => _DayTile(
                day: day,
                inMonth: inMonth,
                mark: inMonth
                    ? marks[day] ?? AttendanceDay.of(day, null).mark
                    : AttendanceMark.none,
                selected: inMonth && DateUtils.isSameDay(day, picked),
                onTap: day.isAfter(today)
                    ? null
                    : () => setState(() => _picked = day),
              ),
            ),
          ),
          AppSpacing.gapMd,
          _DayDetail(
            day: AttendanceDay.of(
              picked,
              AttendanceRecord.forDay(records, picked),
            ),
            now: now,
          ),
          AppSpacing.gapXl,
          const _Legend(),
          AppSpacing.gapXl,
          _Records(
            days: [
              for (final day in days.reversed)
                if (_filter == null
                    ? day.mark != AttendanceMark.none &&
                          day.mark != AttendanceMark.weekend
                    : day.mark == _filter)
                  day,
            ],
            now: now,
            showAll: _showAll,
            onShowAll: (all) => setState(() => _showAll = all),
            onPick: (day) => setState(() => _picked = day),
          ),
        ],
      ),
    );
  }
}

/// How many records show before "View all".
const _recordsShown = 5;

/// The month's days that have a record, newest first: the latest five, and
/// the rest behind "View all". Tapping one picks it on the calendar.
class _Records extends StatelessWidget {
  const _Records({
    required this.days,
    required this.now,
    required this.showAll,
    required this.onShowAll,
    required this.onPick,
  });

  final List<AttendanceDay> days;
  final DateTime now;
  final bool showAll;
  final ValueChanged<bool> onShowAll;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shown = showAll ? days : days.take(_recordsShown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(l10n.attendanceRecords),
        AppSpacing.gapSm,
        if (days.isEmpty)
          DecoratedBox(
            decoration: appCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.attendanceNoRecords,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ),
          )
        else
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: AppListGroup(
              children: [
                for (final day in shown)
                  _AttendanceRecordTile(
                    day: day,
                    now: now,
                    locale: locale,
                    onTap: () {
                      onPick(day.day);
                      if (day.mark == AttendanceMark.absent) {
                        _openApplyLeave(context, selectedDate: day.day);
                      } else if (day.record?.attId != null &&
                          (day.mark == AttendanceMark.onTime ||
                              day.mark == AttendanceMark.late)) {
                        _openApplyChangeRequestSheet(context, day);
                      }
                    },
                  ),
              ],
            ),
          ),
        if (days.length > _recordsShown) ...[
          AppSpacing.gapMd,
          AppButton(
            label: showAll
                ? l10n.attendanceShowLess
                : l10n.attendanceViewAll(days.length),
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            trailingGlyph: showAll
                ? AppGlyphs.chevronUp
                : AppGlyphs.chevronDown,
            onPressed: () => onShowAll(!showAll),
          ),
        ],
      ],
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  const _AttendanceRecordTile({
    required this.day,
    required this.now,
    required this.locale,
    required this.onTap,
  });

  final AttendanceDay day;
  final DateTime now;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final time = DateFormat.jm(locale);
    final checkIn = day.checkIn;
    final checkOut = day.checkOut;
    final worked = day.workedUntil(now);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + AppSpacing.xxs,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateChip(day: day),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEEE d MMM', locale).format(day.day),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              fontWeight: AppFonts.semiBold,
                            ),
                          ),
                        ),
                        AppSpacing.gapXs,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (day.mark == AttendanceMark.onTime ||
                                day.mark == AttendanceMark.late) ...[
                              IconButton(
                                icon: AppGlyphIcon(
                                  AppGlyphs.camera,
                                  size: AppSizes.iconSm,
                                  color: context.colors.primaryShade,
                                ),
                                tooltip: 'View Photos',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                onPressed: () =>
                                    _openCheckImageSheet(context, day),
                              ),
                              AppSpacing.gapXs,
                            ],
                            AppPill(
                              _markLabel(l10n, day.mark),
                              tone: _markTone(day.mark),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (checkIn != null) ...[
                      AppSpacing.gapXs,
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppTag(
                            'In: ${time.format(checkIn)}',
                            tone: AppTone.neutral,
                          ),
                          if (checkOut != null)
                            AppTag(
                              'Out: ${time.format(checkOut)}',
                              tone: AppTone.neutral,
                            ),
                          if (worked != null && checkOut != null)
                            AppTag(
                              'Hours: ${worked.inHours}h ${worked.inMinutes.remainder(60)}m',
                              tone: AppTone.brand,
                            ),
                        ],
                      ),
                    ],
                    if (day.mark == AttendanceMark.absent ||
                        (day.record?.attId != null &&
                            (day.mark == AttendanceMark.onTime ||
                                day.mark == AttendanceMark.late))) ...[
                      AppSpacing.gapXs,
                      if (day.mark == AttendanceMark.absent)
                        const AppTag('Apply Leave', tone: AppTone.brand)
                      else
                        const AppTag('Change Request', tone: AppTone.brand),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day's date on a tile in the colour of how it went.
class _DateChip extends StatelessWidget {
  const _DateChip({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fill = switch (day.mark) {
      AttendanceMark.onTime => colors.dayPresent,
      AttendanceMark.late => colors.dayLate,
      AttendanceMark.leave => colors.dayLeave,
      AttendanceMark.absent => colors.dangerContainer,
      AttendanceMark.weekend || AttendanceMark.none => colors.surfaceMuted,
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.borderMd),
      child: SizedBox.square(
        dimension: AppSizes.avatarMedium,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day.day}',
              style: text.titleSmall?.copyWith(
                fontFeatures: AppFonts.tabularFigures,
                height: 1,
              ),
            ),
            Text(
              DateFormat.E(locale).format(day.day),
              style: text.labelSmall?.copyWith(letterSpacing: 0, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

AppTone _markTone(AttendanceMark mark) => switch (mark) {
  AttendanceMark.onTime => AppTone.brand,
  AttendanceMark.late => AppTone.warning,
  AttendanceMark.leave => AppTone.info,
  AttendanceMark.absent => AppTone.danger,
  AttendanceMark.weekend || AttendanceMark.none => AppTone.neutral,
};

/// What a day's mark is called.
String _markLabel(AppLocalizations l10n, AttendanceMark mark) => switch (mark) {
  AttendanceMark.onTime => l10n.attendanceOnTime,
  AttendanceMark.late => l10n.attendanceLate,
  AttendanceMark.leave => l10n.attendanceLeave,
  AttendanceMark.absent => l10n.attendanceAbsent,
  AttendanceMark.weekend => l10n.attendanceWeekend,
  AttendanceMark.none => l10n.memberNotMarked,
};

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.inMonth,
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final AttendanceMark mark;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fill = switch (mark) {
      AttendanceMark.onTime => colors.dayPresent,
      AttendanceMark.late => colors.dayLate,
      AttendanceMark.leave => colors.dayLeave,
      AttendanceMark.absent => colors.dangerContainer,
      AttendanceMark.weekend || AttendanceMark.none => null,
    };
    final ink = !inMonth
        ? colors.textFaint
        : mark == AttendanceMark.weekend
        ? colors.textTertiary
        : colors.textPrimary;
    return Semantics(
      button: inMonth && onTap != null,
      selected: selected,
      label: l10n.attendanceDayLabel(
        DateFormat.MMMMEEEEd(locale).format(day),
        _markLabel(l10n, mark),
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadius.borderMd,
          border: selected
              ? Border.all(color: colors.textPrimary, width: AppSizes.todayRing)
              : null,
          boxShadow: fill == null
              ? null
              : [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    offset: const Offset(0, AppSizes.keyEdgePressed * 2),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: inMonth ? onTap : null,
            borderRadius: AppRadius.borderMd,
            child: SizedBox(
              height: AppSizes.calendarTile,
              child: Center(
                child: Text(
                  '${day.day}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: ink,
                    fontWeight: AppFonts.semiBold,
                    fontFeatures: AppFonts.tabularFigures,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A picked day: its status, a bar from check-in to check-out across the
/// shift, and the times.
class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.now});

  final AttendanceDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale);
    final tone = switch (day.mark) {
      AttendanceMark.onTime => AppTone.brand,
      AttendanceMark.late => AppTone.warning,
      AttendanceMark.leave => AppTone.info,
      AttendanceMark.absent => AppTone.danger,
      AttendanceMark.weekend || AttendanceMark.none => AppTone.neutral,
    };
    final checkIn = day.checkIn;
    final today = DateUtils.isSameDay(day.day, now);
    // A past day without a check-out has no end to measure to.
    final until = day.checkOut ?? (today ? now : null);
    final worked = checkIn == null || until == null
        ? null
        : until.difference(checkIn);
    final opens =
        (day.shiftStart ??
                DateTime(
                  day.day.year,
                  day.day.month,
                  day.day.day,
                  _dayStartHour,
                ))
            .subtract(_shiftMargin);
    final closes =
        (day.shiftEnd ??
                DateTime(day.day.year, day.day.month, day.day.day, _dayEndHour))
            .add(_shiftMargin);
    final span = closes.difference(opens).inSeconds;
    double share(DateTime at) =>
        span <= 0 ? 0 : at.difference(opens).inSeconds / span;
    final late = day.mark == AttendanceMark.late;
    final labelStyle = text.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: AppFonts.semiBold,
      fontFeatures: AppFonts.tabularFigures,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
        ),
        borderRadius: AppRadius.borderHeroCard,
        border: Border.all(color: colors.surfaceRaised),
        boxShadow: context.elevations.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xxs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEE d MMM', locale).format(day.day),
                    style: text.labelLarge,
                  ),
                ),
                AppPill(_markLabel(l10n, day.mark), tone: tone),
              ],
            ),
            if (checkIn == null) ...[
              AppSpacing.gapSm,
              Text(l10n.attendanceNothingMarked, style: text.bodySmall),
            ] else ...[
              AppSpacing.gapMd,
              AppProgressTrack(
                height: AppSizes.progressTrackTall,
                from: share(checkIn),
                to: share(until ?? checkIn),
                fill: LinearGradient(
                  colors: [
                    late ? colors.dayLateEdge : colors.dayPresentEdge,
                    late ? colors.dayLateEdge : colors.dayPresentEdge,
                    colors.dayPresentEdge,
                    colors.dayPresentEdge,
                  ],
                  stops: const [0, 0.1, 0.1, 1],
                ),
              ),
              AppSpacing.gapXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.attendanceIn(time.format(checkIn)),
                    style: labelStyle,
                  ),
                  if (worked != null)
                    Text(
                      l10n.attendanceWorked(
                        worked.inHours,
                        worked.inMinutes.remainder(60),
                      ),
                      style: labelStyle,
                    ),
                  Text(
                    l10n.attendanceOut(
                      day.checkOut == null
                          ? '--:--'
                          : time.format(day.checkOut!),
                    ),
                    style: labelStyle,
                  ),
                ],
              ),
            ],
            if (day.mark == AttendanceMark.absent) ...[
              AppSpacing.gapMd,
              AppButton(
                label: 'Apply Leave',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.small,
                leadingGlyph: AppGlyphs.navLeave,
                expand: false,
                onPressed: () => _openApplyLeave(context),
              ),
            ] else if (day.record?.attId != null &&
                (day.mark == AttendanceMark.onTime ||
                    day.mark == AttendanceMark.late)) ...[
              AppSpacing.gapMd,
              AppButton(
                label: 'Apply Change Request',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                leadingGlyph: AppGlyphs.fileEdit,
                expand: false,
                onPressed: () => _openApplyChangeRequestSheet(context, day),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What the calendar's colours mean.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md + AppSpacing.xxs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (label, fill, edge) in [
            (l10n.attendanceOnTime, colors.dayPresent, colors.dayPresentEdge),
            (l10n.attendanceLate, colors.dayLate, colors.dayLateEdge),
            (l10n.attendanceLeave, colors.dayLeave, colors.dayLeaveEdge),
            (l10n.attendanceWeekend, null, colors.outlineStrong),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(
                      AppSizes.statMarkRadius,
                    ),
                    border: Border.all(color: edge),
                  ),
                  child: const SizedBox.square(
                    dimension: AppSizes.legendSwatch,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: AppFonts.semiBold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

void _openApplyLeave(BuildContext context, {DateTime? selectedDate}) {
  final range = selectedDate != null
      ? DateTimeRange(
          start: DateUtils.dateOnly(selectedDate),
          end: DateUtils.dateOnly(selectedDate),
        )
      : null;
  final route = MaterialPageRoute<void>(
    settings: const RouteSettings(name: AppRoutes.applyLeave),
    builder: (context) => ApplyLeaveView(
      initialDays: range,
      onBack: () => Navigator.of(context).maybePop(),
    ),
  );
  Navigator.of(context).push(route);
}

void _openApplyChangeRequestSheet(BuildContext context, AttendanceDay day) {
  if (day.mark != AttendanceMark.onTime && day.mark != AttendanceMark.late) {
    return;
  }
  final attId = day.record?.attId;
  if (attId == null) {
    showAppMessage(
      context,
      'No attendance record ID found for this day.',
      tone: AppDialogTone.info,
    );
    return;
  }

  final cubit = context.read<AttendanceCubit>();

  showAppSheet<void>(
    context: context,
    title: 'Apply Change Request',
    closeLabel: 'Close',
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ApplyChangeRequestSheet(attId: attId, day: day),
    ),
  );
}

class _ApplyChangeRequestSheet extends StatefulWidget {
  const _ApplyChangeRequestSheet({required this.attId, required this.day});

  final int attId;
  final AttendanceDay day;

  @override
  State<_ApplyChangeRequestSheet> createState() =>
      __ApplyChangeRequestSheetState();
}

class __ApplyChangeRequestSheetState extends State<_ApplyChangeRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();

  late DateTime _reqCheckIn;
  late DateTime _reqCheckOut;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final dayDate = widget.day.day;
    _reqCheckIn =
        widget.day.checkIn ??
        DateTime(dayDate.year, dayDate.month, dayDate.day, 9, 0);
    _reqCheckOut =
        widget.day.checkOut ??
        DateTime(dayDate.year, dayDate.month, dayDate.day, 17, 0);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  /// One sheet picks both the day and the time; a check-out after
  /// midnight falls on the next day.
  Future<void> _pickDateTime({required bool isCheckIn}) async {
    final l10n = context.l10n;
    final day = DateUtils.dateOnly(widget.day.day);
    final selected = await showAppDateTimeSheet(
      context: context,
      title: isCheckIn ? 'Requested Check-In' : 'Requested Check-Out',
      closeLabel: l10n.actionClose,
      doneLabel: l10n.dateTimeDone,
      timeLabel: l10n.dateTimeTime,
      initial: isCheckIn ? _reqCheckIn : _reqCheckOut,
      firstDate: day,
      lastDate: day.add(const Duration(days: 1)),
      today: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _reqCheckIn = selected;
      } else {
        _reqCheckOut = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final checkInStr = DateFormat('yyyy-MM-dd HH:mm').format(_reqCheckIn);
    final checkOutStr = DateFormat('yyyy-MM-dd HH:mm').format(_reqCheckOut);

    final cubit = context.read<AttendanceCubit>();
    final success = await cubit.applyChangeRequest(
      attId: widget.attId,
      reqCheckIn: checkInStr,
      reqCheckOut: checkOutStr,
      remarks: _remarksController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    showAppMessage(
      context,
      success
          ? 'Change request submitted successfully.'
          : 'Failed to submit change request. Please try again.',
      tone: AppDialogTone.success,
    );

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat('EEE d MMM yyyy, HH:mm', locale);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: AppMotion.short,
      curve: AppMotion.enter,
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE d MMMM yyyy', locale).format(widget.day.day),
                style: text.titleMedium?.copyWith(
                  fontWeight: AppFonts.semiBold,
                ),
              ),
              AppSpacing.gapLg,
              AppListGroup(
                children: [
                  AppListRow(
                    title: 'Requested Check-In',
                    subtitle: fmt.format(_reqCheckIn),
                    trailing: AppGlyphIcon(
                      AppGlyphs.calendar,
                      color: colors.iconAccent,
                      size: AppSizes.iconSm,
                    ),
                    onTap: () => _pickDateTime(isCheckIn: true),
                  ),
                  AppListRow(
                    title: 'Requested Check-Out',
                    subtitle: fmt.format(_reqCheckOut),
                    trailing: AppGlyphIcon(
                      AppGlyphs.calendar,
                      color: colors.iconAccent,
                      size: AppSizes.iconSm,
                    ),
                    onTap: () => _pickDateTime(isCheckIn: false),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              AppTextField(
                controller: _remarksController,
                label: 'Reason / Remarks',
                hint: 'Enter reason for change request',
                glyph: AppGlyphs.fileEdit,
                minLines: 2,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              AppSpacing.gapXl,
              AppButton(
                label: 'Submit Request',
                variant: AppButtonVariant.primary,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }
}

void _openCheckImageSheet(BuildContext context, AttendanceDay day) {
  final record = day.record;
  final attId = record?.attId;
  final empId = record?.empId;
  if (attId == null || empId == null) {
    showAppMessage(
      context,
      'Attendance ID or Employee ID not found for this record.',
      tone: AppDialogTone.error,
    );
    return;
  }

  final repository = context.read<EmployeeAttendanceRepository>();

  showAppSheet<void>(
    context: context,
    title: 'Check-In / Out Photos',
    closeLabel: 'Close',
    subtitle: DateFormat(
      'EEEE d MMMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(day.day),
    builder: (_) => RepositoryProvider.value(
      value: repository,
      child: AttendanceCheckImageSheet(attId: attId, empId: empId),
    ),
  );
}

class CheckImageResult {
  final String? checkInImage;
  final String? checkOutImage;

  const CheckImageResult({this.checkInImage, this.checkOutImage});

  factory CheckImageResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else if (json['data'] is List &&
        (json['data'] as List).isNotEmpty &&
        (json['data'] as List).first is Map<String, dynamic>) {
      data = (json['data'] as List).first as Map<String, dynamic>;
    } else if (json['result'] is Map<String, dynamic>) {
      data = json['result'] as Map<String, dynamic>;
    }

    String? findString(List<String> keys) {
      for (final k in keys) {
        final val = data[k] ?? json[k];
        if (val != null &&
            val.toString().trim().isNotEmpty &&
            val.toString().trim() != 'null') {
          return val.toString().trim();
        }
      }
      return null;
    }

    return CheckImageResult(
      checkInImage: findString([
        'CheckIn',
        'checkin_image',
        'check_in_image',
        'checkin_img',
        'checkinImage',
        'checkin_photo',
        'checkin',
        'checkIn',
        'Checkin',
        'CheckInImage',
      ]),
      checkOutImage: findString([
        'CheckOut',
        'checkout_image',
        'check_out_image',
        'checkout_img',
        'checkoutImage',
        'checkout_photo',
        'checkout',
        'checkOut',
        'Checkout',
        'CheckOutImage',
      ]),
    );
  }
}

Widget buildAttendanceImage(String? imageStr, BuildContext context) {
  if (imageStr == null || imageStr.trim().isEmpty || imageStr == 'null') {
    return _buildImagePlaceholder(context, 'No photo');
  }

  final trimmed = imageStr.trim();

  if (trimmed.startsWith('data:image') ||
      trimmed.contains('base64') ||
      (!trimmed.startsWith('http') &&
          !trimmed.contains('/') &&
          trimmed.length > 50)) {
    try {
      final cleanBase64 = trimmed.contains(',')
          ? trimmed.split(',').last
          : trimmed;
      final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _buildImagePlaceholder(context, 'Failed to decode'),
      );
    } catch (e) {
      log('Base64 decode error: $e');
    }
  }

  String fullUrl = trimmed;
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    final baseUrl = ApiEndpoints.base.endsWith('/')
        ? ApiEndpoints.base.substring(0, ApiEndpoints.base.length - 1)
        : ApiEndpoints.base;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    fullUrl = '$baseUrl$path';
  }

  // Decoded at the size it shows, not the camera's.
  return LayoutBuilder(
    builder: (context, box) => Image.network(
      fullUrl,
      cacheWidth: physicalWidth(context, box.maxWidth),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildImagePlaceholder(
          context,
          'Loading photo...',
          isLoading: true,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(context, 'Not available');
      },
    ),
  );
}

Widget _buildImagePlaceholder(
  BuildContext context,
  String message, {
  bool isLoading = false,
}) {
  final colors = context.colors;
  final text = context.textTheme;
  return Container(
    color: colors.surfaceSunken,
    child: Center(
      child: isLoading
          ? const AppLoader(size: AppSizes.loaderSmall)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppGlyphIcon(
                  AppGlyphs.camera,
                  size: AppSizes.iconLg,
                  color: colors.textTertiary,
                ),
                AppSpacing.gapXs,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
    ),
  );
}

class AttendanceCheckImageSheet extends StatefulWidget {
  const AttendanceCheckImageSheet({
    super.key,
    required this.attId,
    required this.empId,
  });

  final int attId;
  final int empId;

  @override
  State<AttendanceCheckImageSheet> createState() =>
      _AttendanceCheckImageSheetState();
}

class _AttendanceCheckImageSheetState extends State<AttendanceCheckImageSheet> {
  bool _loading = true;
  String? _error;
  CheckImageResult? _result;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = context.read<EmployeeAttendanceRepository>();
    final result = await repository.getCheckImage(
      attId: widget.attId,
      empId: widget.empId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (response) {
        try {
          final data = response.data;
          final parsed = CheckImageResult.fromJson(
            data is Map<String, dynamic> ? data : {'data': data},
          );
          setState(() {
            _loading = false;
            _result = parsed;
          });
        } catch (e) {
          setState(() {
            _loading = false;
            _error = 'Failed to parse image response';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              _error!,
              style: text.bodySmall?.copyWith(color: colors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Check-In Photo',
                    style: text.labelMedium?.copyWith(
                      fontWeight: AppFonts.semiBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapSm,
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.outlineStrong),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.borderMd,
                        child: _loading
                            ? _buildImagePlaceholder(
                                context,
                                'Loading photo...',
                                isLoading: true,
                              )
                            : buildAttendanceImage(
                                _result?.checkInImage,
                                context,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Check-Out Photo',
                    style: text.labelMedium?.copyWith(
                      fontWeight: AppFonts.semiBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapSm,
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.outlineStrong),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.borderMd,
                        child: _loading
                            ? _buildImagePlaceholder(
                                context,
                                'Loading photo...',
                                isLoading: true,
                              )
                            : buildAttendanceImage(
                                _result?.checkOutImage,
                                context,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
