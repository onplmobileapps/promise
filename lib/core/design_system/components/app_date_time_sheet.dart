import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_date_range_calendar.dart';
import 'package:railway_hrms/core/design_system/components/app_section_label.dart';
import 'package:railway_hrms/core/design_system/components/app_sheet.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Picks a day and a time on one sheet: the month's calendar over a wheel
/// of hours and minutes, and a key that takes both. Gives the moment
/// picked, or null if the sheet is closed.
Future<DateTime?> showAppDateTimeSheet({
  required BuildContext context,
  required String title,
  required String closeLabel,
  required String doneLabel,
  required String timeLabel,
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  String? subtitle,
  DateTime? today,
}) => showAppSheet<DateTime>(
  context: context,
  title: title,
  subtitle: subtitle,
  closeLabel: closeLabel,
  builder: (sheetContext) => AppDateTimePicker(
    initial: initial,
    firstDate: firstDate,
    lastDate: lastDate,
    today: today,
    timeLabel: timeLabel,
    doneLabel: doneLabel,
    onDone: (picked) => Navigator.of(sheetContext).pop(picked),
  ),
);

/// The body of [showAppDateTimeSheet]: a calendar for the day, a wheel for
/// the time, and [doneLabel]'s key that hands both to [onDone].
class AppDateTimePicker extends StatefulWidget {
  const AppDateTimePicker({
    super.key,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.timeLabel,
    required this.doneLabel,
    required this.onDone,
    this.today,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? today;
  final String timeLabel;
  final String doneLabel;
  final ValueChanged<DateTime> onDone;

  @override
  State<AppDateTimePicker> createState() => _AppDateTimePickerState();
}

class _AppDateTimePickerState extends State<AppDateTimePicker> {
  late DateTime _day = DateUtils.dateOnly(widget.initial);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.initial);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDateRangeCalendar(
            range: false,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            today: widget.today,
            selected: DateTimeRange(start: _day, end: _day),
            onChanged: (picked) => setState(() => _day = picked.start),
          ),
          AppSpacing.gapMd,
          AppSectionLabel(widget.timeLabel),
          AppSpacing.gapXs,
          SizedBox(
            height: AppSizes.timeWheelHeight,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Theme.of(context).brightness,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: context.textTheme.titleLarge
                      ?.copyWith(color: colors.textPrimary),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  _day.year,
                  _day.month,
                  _day.day,
                  _time.hour,
                  _time.minute,
                ),
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                onDateTimeChanged: (picked) =>
                    _time = TimeOfDay.fromDateTime(picked),
              ),
            ),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: widget.doneLabel,
            variant: AppButtonVariant.primary,
            onPressed: () => widget.onDone(
              DateTime(
                _day.year,
                _day.month,
                _day.day,
                _time.hour,
                _time.minute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks a day on a sheet with wheels for the day, month and year, so a
/// day years back, as an overhaul date, is a flick away. Gives the day
/// picked, or null if the sheet is closed.
Future<DateTime?> showAppDateSheet({
  required BuildContext context,
  required String title,
  required String closeLabel,
  required String doneLabel,
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  String? subtitle,
}) => showAppSheet<DateTime>(
  context: context,
  title: title,
  subtitle: subtitle,
  closeLabel: closeLabel,
  builder: (sheetContext) => AppDatePicker(
    initial: initial,
    firstDate: firstDate,
    lastDate: lastDate,
    doneLabel: doneLabel,
    onDone: (picked) => Navigator.of(sheetContext).pop(picked),
  ),
);

/// The body of [showAppDateSheet]: wheels for the day and [doneLabel]'s key
/// that hands it to [onDone].
class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.doneLabel,
    required this.onDone,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final String doneLabel;
  final ValueChanged<DateTime> onDone;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late final DateTime _first = DateUtils.dateOnly(widget.firstDate);
  late final DateTime _last = DateUtils.dateOnly(widget.lastDate);
  late DateTime _day = _clamp(DateUtils.dateOnly(widget.initial));

  DateTime _clamp(DateTime day) => day.isBefore(_first)
      ? _first
      : day.isAfter(_last)
      ? _last
      : day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSizes.timeWheelHeight + AppSpacing.xxl,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: context.textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              dateOrder: DatePickerDateOrder.dmy,
              initialDateTime: _day,
              minimumDate: _first,
              maximumDate: _last,
              onDateTimeChanged: (picked) =>
                  _day = _clamp(DateUtils.dateOnly(picked)),
            ),
          ),
        ),
        AppSpacing.gapLg,
        AppButton(
          label: widget.doneLabel,
          variant: AppButtonVariant.primary,
          onPressed: () => widget.onDone(_day),
        ),
      ],
    );
  }
}

/// Picks a time of day on a sheet with a wheel of hours and minutes. Gives
/// the time picked, or null if the sheet is closed.
Future<TimeOfDay?> showAppTimeSheet({
  required BuildContext context,
  required String title,
  required String closeLabel,
  required String doneLabel,
  required TimeOfDay initial,
}) {
  var picked = initial;
  return showAppSheet<TimeOfDay>(
    context: context,
    title: title,
    closeLabel: closeLabel,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSizes.timeWheelHeight,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(sheetContext).brightness,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: sheetContext.textTheme.titleLarge
                    ?.copyWith(color: sheetContext.colors.textPrimary),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                2000,
                1,
                1,
                initial.hour,
                initial.minute,
              ),
              use24hFormat: MediaQuery.alwaysUse24HourFormatOf(sheetContext),
              onDateTimeChanged: (at) => picked = TimeOfDay.fromDateTime(at),
            ),
          ),
        ),
        AppSpacing.gapLg,
        AppButton(
          label: doneLabel,
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(sheetContext).pop(picked),
        ),
      ],
    ),
  );
}
