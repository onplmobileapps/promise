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
