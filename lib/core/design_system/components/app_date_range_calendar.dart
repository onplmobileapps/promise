import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/components/app_month_calendar.dart';
import 'package:railway_hrms/core/design_system/components/app_tile_button.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Picks a run of days on a month calendar, or with [range] false a single
/// day. A run is picked one end at a time: two tiles over the month show
/// the first day and the last, the one being picked lit in jade with a
/// line saying what to tap; picking the first moves on to the last, and
/// either tile can be tapped to change its day. The ends are small jade
/// spheres with a band between them; [today] has a gold ring.
///
/// Only days from [firstDate] to [lastDate] can be picked, and the months
/// page between theirs.
class AppDateRangeCalendar extends StatefulWidget {
  const AppDateRangeCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.selected,
    this.today,
    this.range = true,
    this.startLabel,
    this.endLabel,
    this.emptyLabel,
    this.startPrompt,
    this.endPrompt,
    this.previousLabel,
    this.nextLabel,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? selected;
  final ValueChanged<DateTimeRange> onChanged;
  final DateTime? today;

  /// A run of days, picked end by end; false picks one day, with no tiles.
  final bool range;

  /// The tiles' names, like "From" and "To", and what an unpicked one says.
  final String? startLabel;
  final String? endLabel;
  final String? emptyLabel;

  /// The line saying what to tap while the first day, or the last, is
  /// being picked.
  final String? startPrompt;
  final String? endPrompt;

  /// Read by screen readers on the month buttons.
  final String? previousLabel;
  final String? nextLabel;

  @override
  State<AppDateRangeCalendar> createState() => _AppDateRangeCalendarState();
}

class _AppDateRangeCalendarState extends State<AppDateRangeCalendar> {
  late DateTime _month = _monthOf(
    widget.selected?.start ?? widget.today ?? widget.firstDate,
  );

  /// The last day is being picked; otherwise the first is.
  late bool _pickingEnd = widget.selected != null;

  static DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);

  bool get _canGoBack => _month.isAfter(_monthOf(widget.firstDate));
  bool get _canGoForward => _month.isBefore(_monthOf(widget.lastDate));

  void _page(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  void _pick(DateTime day) {
    final picked = widget.selected;
    if (!widget.range) {
      widget.onChanged(DateTimeRange(start: day, end: day));
      return;
    }
    if (_pickingEnd && picked != null && !day.isBefore(picked.start)) {
      widget.onChanged(DateTimeRange(start: picked.start, end: day));
      return;
    }
    // A new first day keeps the last if it still comes after it, and the
    // last is picked next.
    final keepEnd =
        _pickingEnd == false && picked != null && !picked.end.isBefore(day);
    setState(() => _pickingEnd = true);
    widget.onChanged(
      DateTimeRange(start: day, end: keepEnd ? picked.end : day),
    );
  }

  void _show(DateTime day) {
    final month = _monthOf(day);
    if (month != _month) setState(() => _month = month);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final materialLabels = MaterialLocalizations.of(context);
    final picked = widget.selected;
    final prompt = _pickingEnd ? widget.endPrompt : widget.startPrompt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.range) ...[
          Row(
            children: [
              Expanded(
                child: _EndTile(
                  label:
                      widget.startLabel ?? materialLabels.dateRangeStartLabel,
                  day: picked?.start,
                  emptyLabel:
                      widget.emptyLabel ?? materialLabels.unspecifiedDate,
                  active: !_pickingEnd,
                  onTap: () {
                    setState(() => _pickingEnd = false);
                    if (picked != null) _show(picked.start);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: AppGlyphIcon(
                  Directionality.of(context) == TextDirection.rtl
                      ? AppGlyphs.arrowLeft
                      : AppGlyphs.arrowRight,
                  size: AppSizes.iconSm,
                  color: context.colors.textTertiary,
                ),
              ),
              Expanded(
                child: _EndTile(
                  label: widget.endLabel ?? materialLabels.dateRangeEndLabel,
                  day: picked?.end,
                  emptyLabel:
                      widget.emptyLabel ?? materialLabels.unspecifiedDate,
                  active: _pickingEnd,
                  onTap: () {
                    setState(() => _pickingEnd = true);
                    if (picked != null) _show(picked.end);
                  },
                ),
              ),
            ],
          ),
          if (prompt != null) ...[
            AppSpacing.gapSm,
            AnimatedSwitcher(
              duration: AppMotion.short,
              child: Text(
                prompt,
                key: ValueKey(_pickingEnd),
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.accentStrong,
                  fontWeight: AppFonts.semiBold,
                ),
              ),
            ),
          ],
          AppSpacing.gapSm,
        ],
        Row(
          children: [
            AppTileButton(
              icon: const AppGlyphIcon(AppGlyphs.chevronLeft),
              tooltip:
                  widget.previousLabel ?? materialLabels.previousMonthTooltip,
              onPressed: _canGoBack ? () => _page(-1) : null,
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(_month),
                textAlign: TextAlign.center,
                style: context.textTheme.labelLarge,
              ),
            ),
            AppTileButton(
              icon: const AppGlyphIcon(AppGlyphs.chevronRight),
              tooltip: widget.nextLabel ?? materialLabels.nextMonthTooltip,
              onPressed: _canGoForward ? () => _page(1) : null,
            ),
          ],
        ),
        AppSpacing.gapSm,
        AppMonthCalendar(
          month: _month,
          dayBuilder: (context, day, inMonth) => _Day(
            day: day,
            inMonth: inMonth,
            enabled:
                inMonth &&
                !day.isBefore(DateUtils.dateOnly(widget.firstDate)) &&
                !day.isAfter(DateUtils.dateOnly(widget.lastDate)),
            range: picked,
            today: widget.today,
            onTap: () => _pick(day),
          ),
        ),
      ],
    );
  }
}

/// One end of the run over the calendar: its name over its day, sunk while
/// another is being picked, lit in jade inside a soft ring while it is.
class _EndTile extends StatelessWidget {
  const _EndTile({
    required this.label,
    required this.day,
    required this.emptyLabel,
    required this.active,
    required this.onTap,
  });

  final String label;
  final DateTime? day;
  final String emptyLabel;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final day = this.day;
    final shown = day == null
        ? emptyLabel
        : DateFormat.MMMEd(locale).format(day);
    return Semantics(
      button: true,
      selected: active,
      label: '$label, $shown',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.short,
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderLg,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colors.focusRing,
                    spreadRadius: AppSizes.fieldRing,
                  ),
                ]
              : const [],
        ),
        child: AppInkSurface(
          onTap: onTap,
          decoration: BoxDecoration(
            color: active ? colors.dayPresent : colors.surfaceSunken,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: active ? colors.dayPresentEdge : colors.outline,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.smd,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: active ? colors.accentStrong : colors.textTertiary,
                    fontWeight: AppFonts.semiBold,
                  ),
                ),
                Text(
                  shown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: day == null
                        ? colors.textTertiary
                        : colors.textPrimary,
                    fontWeight: day == null ? AppFonts.medium : AppFonts.bold,
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

class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.inMonth,
    required this.enabled,
    required this.range,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool enabled;
  final DateTimeRange? range;
  final DateTime? today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final range = this.range;
    final isStart = range != null && DateUtils.isSameDay(day, range.start);
    final isEnd = range != null && DateUtils.isSameDay(day, range.end);
    final within =
        range != null &&
        inMonth &&
        !day.isBefore(range.start) &&
        !day.isAfter(range.end);
    final spans = range != null && !DateUtils.isSameDay(range.start, range.end);
    final isToday = today != null && DateUtils.isSameDay(day, today);
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final picked = inMonth && (isStart || isEnd);

    final style = context.textTheme.labelMedium?.copyWith(
      fontFeatures: AppFonts.tabularFigures,
      fontWeight: picked || isToday ? AppFonts.bold : AppFonts.medium,
      // Days that can't be picked fade, so the ones that can stand out.
      color: !inMonth || (!enabled && !picked)
          ? colors.textFaint
          : picked
          ? colors.textPrimary
          : weekend
          ? colors.textTertiary
          : colors.textPrimary,
    );
    Widget face = Text('${day.day}', style: style);
    if (picked) {
      final sphere = context.spheres.jade;
      face = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [sphere.highlight, sphere.body, colors.success],
            stops: const [0, 0.45, 1],
          ),
          boxShadow: context.elevations.daySphere,
        ),
        child: SizedBox.square(
          dimension: AppSizes.calendarDay,
          child: Center(child: face),
        ),
      );
    } else if (isToday && inMonth) {
      face = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.warningMark,
            width: AppSizes.todayRing,
          ),
        ),
        child: SizedBox.square(
          dimension: AppSizes.calendarDay - AppSizes.todayRing,
          child: Center(child: face),
        ),
      );
    }

    // The band joins the ends across the days between them.
    final band = within && spans
        ? LinearGradient(
            colors: [
              isStart
                  ? colors.dayPresent.withValues(alpha: 0)
                  : colors.dayPresent,
              isStart
                  ? colors.dayPresent.withValues(alpha: 0)
                  : colors.dayPresent,
              isEnd
                  ? colors.dayPresent.withValues(alpha: 0)
                  : colors.dayPresent,
              isEnd
                  ? colors.dayPresent.withValues(alpha: 0)
                  : colors.dayPresent,
            ],
            stops: const [0, 0.5, 0.5, 1],
          )
        : null;

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: within,
      label: DateFormat.yMMMMEEEEd(locale).format(day),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: band),
        child: InkResponse(
          onTap: enabled ? onTap : null,
          radius: AppSizes.calendarDay / 2,
          child: SizedBox(
            height: AppSizes.calendarDay,
            // A picked day swells under a lens of liquid glass.
            child: Center(
              child: LiquidPop(selected: picked, child: face),
            ),
          ),
        ),
      ),
    );
  }
}
