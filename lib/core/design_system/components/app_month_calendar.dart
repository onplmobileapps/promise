import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Draws one day of an [AppMonthCalendar]. [inMonth] is false for the days
/// of the weeks before and after the month that fill its first and last
/// rows.
typedef AppCalendarDayBuilder =
    Widget Function(BuildContext context, DateTime day, bool inMonth);

/// A [month] laid out in weeks from Monday, under the weekdays' initials.
/// [dayBuilder] draws every day; [rowGap] and [columnGap] space them.
class AppMonthCalendar extends StatelessWidget {
  const AppMonthCalendar({
    super.key,
    required this.month,
    required this.dayBuilder,
    this.rowGap = AppSpacing.xs,
    this.columnGap = 0,
  });

  final DateTime month;
  final AppCalendarDayBuilder dayBuilder;
  final double rowGap;
  final double columnGap;

  /// A Monday, to name the weekdays from.
  static final _aMonday = DateTime(2024);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final initial = DateFormat.EEEEE(locale);
    final first = DateTime(month.year, month.month);
    final lead = (first.weekday - DateTime.monday) % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = ((lead + days) / 7).ceil();
    Widget row(List<Widget> cells) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0 && columnGap > 0) SizedBox(width: columnGap),
          Expanded(child: cells[i]),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: row([
            for (var i = 0; i < 7; i++)
              Center(
                child: Text(
                  initial.format(_aMonday.add(Duration(days: i))),
                  style: context.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0,
                  ),
                ),
              ),
          ]),
        ),
        for (var week = 0; week < weeks; week++) ...[
          SizedBox(height: rowGap),
          row([
            for (var weekday = 0; weekday < 7; weekday++)
              Builder(
                builder: (context) {
                  final day = DateTime(
                    month.year,
                    month.month,
                    1 - lead + week * 7 + weekday,
                  );
                  return dayBuilder(context, day, day.month == month.month);
                },
              ),
          ]),
        ],
      ],
    );
  }
}
