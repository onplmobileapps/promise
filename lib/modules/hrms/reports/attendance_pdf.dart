import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/reports/report_ink.dart';
import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/reports/attendance_report.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';

/// How a day's status is coloured: its deep ink, its fill and its tint.
typedef _Tone = ({PdfColor ink, PdfColor fill, PdfColor tint});

_Tone _toneOf(AttendanceMark mark) => switch (mark) {
  AttendanceMark.onTime => (
    ink: ReportInk.jade950,
    fill: ReportInk.jade700,
    tint: ReportInk.jade100,
  ),
  AttendanceMark.late => (
    ink: ReportInk.gold800,
    fill: ReportInk.gold500,
    tint: ReportInk.gold50,
  ),
  AttendanceMark.leave => (
    ink: ReportInk.sky800,
    fill: ReportInk.sky500,
    tint: ReportInk.sky50,
  ),
  AttendanceMark.absent => (
    ink: ReportInk.coral800,
    fill: ReportInk.coral500,
    tint: ReportInk.coral50,
  ),
  AttendanceMark.weekend || AttendanceMark.none => (
    ink: ReportInk.ink700,
    fill: ReportInk.ink400,
    tint: ReportInk.ivory200,
  ),
};

/// Draws an [AttendanceReport] as an A4 PDF: for a team, a summary of
/// everyone first; then, for each person, a banner with who they are, the
/// period's counts, a calendar of it, every day's times, and their leaves.
/// The app's logo lies faintly across every page.
class AttendancePdf {
  AttendancePdf(this.report, this.l10n, this.assets, {required this.locale});

  final AttendanceReport report;
  final AppLocalizations l10n;
  final ReportAssets assets;
  final String locale;

  static const _margin = 28.0;

  Future<Uint8List> build() async {
    final doc = pw.Document(
      title: _title,
      author: report.madeBy,
      creator: 'PROMISE',
      theme: pw.ThemeData.withFont(base: assets.regular, bold: assets.bold),
    );
    if (report.isTeam) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: _pageTheme,
          footer: _footer,
          build: (_) => _teamSummary(),
        ),
      );
    }
    for (final person in report.people) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: _pageTheme,
          header: (context) => _runningHeader(context, person),
          footer: _footer,
          build: (_) => _person(person),
        ),
      );
    }
    return doc.save();
  }

  // ── Text ───────────────────────────────────────────────────────────────

  pw.TextStyle _text(
    double size, {
    pw.Font? font,
    PdfColor color = ReportInk.ink900,
    double? spacing,
  }) => pw.TextStyle(
    font: font ?? assets.regular,
    fontSize: size,
    color: color,
    letterSpacing: spacing,
  );

  String get _period {
    if (report.monthly) return DateFormat.yMMMM(locale).format(report.from);
    return _range(report.from, report.to);
  }

  String _range(DateTime from, DateTime to) {
    final day = DateFormat.yMMMd(locale);
    return from == to
        ? day.format(from)
        : '${day.format(from)} – ${day.format(to)}';
  }

  String get _title =>
      '${report.isTeam ? l10n.attReportTeamTitle : l10n.attReportTitle} · $_period';

  String _hours(Duration worked) {
    final minutes = worked.inMinutes;
    if (minutes <= 0) return '—';
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
  }

  String _time(DateTime? time) =>
      time == null ? '—' : DateFormat('hh:mm a', locale).format(time);

  String _markName(AttendanceMark mark) => switch (mark) {
    AttendanceMark.onTime => l10n.attendanceOnTime,
    AttendanceMark.late => l10n.attendanceLate,
    AttendanceMark.leave => l10n.attendanceLeave,
    AttendanceMark.absent => l10n.attendanceAbsent,
    AttendanceMark.weekend => l10n.attReportDaysOff,
    AttendanceMark.none => l10n.memberNotMarked,
  };

  String _percent(double share) => '${(share * 100).round()}%';

  // ── Page ───────────────────────────────────────────────────────────────

  pw.PageTheme get _pageTheme => pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(_margin, _margin, _margin, 20),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Container(color: ReportInk.ivory50),
          // A band of colour along the top edge.
          pw.Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(height: 5, color: ReportInk.brand),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(height: 5, color: ReportInk.brandGold),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(height: 5, color: ReportInk.coral500),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(height: 5, color: ReportInk.sky500),
                ),
              ],
            ),
          ),
          // The splash's emblem, faint, in the middle of the page.
          pw.Center(
            child: pw.Opacity(
              opacity: 0.06,
              child: pw.Image(assets.emblem, width: 360),
            ),
          ),
        ],
      ),
    ),
  );

  pw.Widget _runningHeader(pw.Context context, PersonReport person) {
    // The first page of a person has the banner instead.
    if (context.pageNumber == _firstPageOf(context, person)) {
      return pw.SizedBox();
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: ReportInk.sand300, width: 0.6),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Image(assets.emblem, height: 18),
          pw.SizedBox(width: 5),
          pw.Image(assets.logo, height: 11),
          pw.Spacer(),
          pw.Text(
            '${person.subject.name} · $_period',
            style: _text(8.5, font: assets.semiBold, color: ReportInk.ink700),
          ),
        ],
      ),
    );
  }

  /// Pages already drawn before [person]'s, so their first can be told.
  final Map<PersonReport, int> _firstPages = {};

  int _firstPageOf(pw.Context context, PersonReport person) =>
      _firstPages.putIfAbsent(person, () => context.pageNumber);

  pw.Widget _footer(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: ReportInk.sand300, width: 0.6),
      ),
    ),
    child: pw.Row(
      children: [
        pw.Text(
          l10n.attReportFooter,
          style: _text(7.5, font: assets.semiBold, color: ReportInk.jade800),
        ),
        if (report.madeBy.isNotEmpty)
          pw.Text(
            '  ·  ${l10n.attReportGeneratedBy(report.madeBy)}',
            style: _text(7.5, color: ReportInk.ink500),
          ),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: ReportInk.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: ReportInk.sand300, width: 0.5),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                l10n.poweredByLead,
                style: _text(7, font: assets.medium, color: ReportInk.ink500),
              ),
              pw.SizedBox(width: 5),
              pw.Image(assets.poweredBy, height: 12),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          l10n.attReportPage(context.pageNumber, context.pagesCount),
          style: _text(7.5, color: ReportInk.ink500),
        ),
      ],
    ),
  );

  // ── Banner ─────────────────────────────────────────────────────────────

  pw.Widget _banner({
    required String kicker,
    required String title,
    required String subtitle,
  }) => pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      gradient: const pw.LinearGradient(
        begin: pw.Alignment.topLeft,
        end: pw.Alignment.bottomRight,
        colors: [ReportInk.brand, ReportInk.jade950, ReportInk.jade700],
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                kicker.toUpperCase(),
                style: _text(
                  8,
                  font: assets.bold,
                  color: ReportInk.gold300,
                  spacing: 1.4,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                title,
                style: _text(22, font: assets.display, color: ReportInk.white),
              ),
              if (subtitle.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  subtitle,
                  style: _text(
                    10,
                    font: assets.medium,
                    color: ReportInk.jade200,
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: ReportInk.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Image(assets.emblem, height: 26),
                  pw.SizedBox(width: 6),
                  pw.Image(assets.logo, height: 13),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: ReportInk.gold500,
                borderRadius: pw.BorderRadius.circular(9),
              ),
              child: pw.Text(
                _period,
                style: _text(9, font: assets.bold, color: ReportInk.white),
              ),
            ),
            if (report.monthly) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                _range(report.from, report.to),
                style: _text(7.5, color: ReportInk.jade200),
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Text(
              l10n.attReportGenerated(
                DateFormat.yMMMd(locale).add_jm().format(report.made),
              ),
              style: _text(7.5, color: ReportInk.jade200),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Stats ──────────────────────────────────────────────────────────────

  pw.Widget _statTile(
    String label,
    String value,
    _Tone tone, {
    double? share,
  }) => pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(6, 9, 10, 9),
    decoration: pw.BoxDecoration(
      color: tone.tint,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // A stripe of the status's colour down the tile's edge.
        pw.Container(
          width: 3,
          height: share == null ? 30 : 38,
          decoration: pw.BoxDecoration(
            color: tone.fill,
            borderRadius: pw.BorderRadius.circular(1.5),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: _text(18, font: assets.display, color: tone.ink),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                label,
                maxLines: 1,
                style: _text(7.5, font: assets.semiBold, color: tone.ink),
              ),
              if (share != null) ...[
                pw.SizedBox(height: 5),
                _bar(share, tone.fill, ReportInk.white),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  pw.Widget _bar(
    double share,
    PdfColor fill,
    PdfColor track, {
    double height = 4,
  }) {
    final on = (share.clamp(0, 1) * 1000).round();
    return pw.ClipRRect(
      horizontalRadius: height / 2,
      verticalRadius: height / 2,
      child: pw.Row(
        children: [
          if (on > 0)
            pw.Expanded(
              flex: on,
              child: pw.Container(height: height, color: fill),
            ),
          if (on < 1000)
            pw.Expanded(
              flex: 1000 - on,
              child: pw.Container(height: height, color: track),
            ),
        ],
      ),
    );
  }

  pw.Widget _counts({
    required int onTime,
    required int late,
    required int leave,
    required int absent,
    required int off,
    required int total,
  }) {
    double share(int n) => total == 0 ? 0 : n / total;
    return pw.Row(
      children: [
        for (final (mark, count) in [
          (AttendanceMark.onTime, onTime),
          (AttendanceMark.late, late),
          (AttendanceMark.leave, leave),
          (AttendanceMark.absent, absent),
          (AttendanceMark.weekend, off),
        ]) ...[
          if (mark != AttendanceMark.onTime) pw.SizedBox(width: 6),
          pw.Expanded(
            child: _statTile(
              _markName(mark),
              '$count',
              _toneOf(mark),
              share: share(count),
            ),
          ),
        ],
      ],
    );
  }

  /// The period split by status, as one bar, with its key.
  pw.Widget _spread(Map<AttendanceMark, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return pw.SizedBox();
    final shown = [
      for (final mark in AttendanceMark.values)
        if ((counts[mark] ?? 0) > 0) mark,
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 5,
          verticalRadius: 5,
          child: pw.Row(
            children: [
              for (final mark in shown)
                pw.Expanded(
                  flex: counts[mark]!,
                  child: pw.Container(height: 10, color: _toneOf(mark).fill),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Wrap(
          spacing: 12,
          runSpacing: 3,
          children: [
            for (final mark in shown)
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 7,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: _toneOf(mark).fill,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    '${_markName(mark)} ${counts[mark]} (${_percent(counts[mark]! / total)})',
                    style: _text(7.5, color: ReportInk.ink700),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _keyFigure(
    String label,
    String value,
    PdfColor color,
  ) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: ReportInk.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: ReportInk.sand300, width: 0.6),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 6,
            height: 26,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: _text(14, font: assets.display, color: ReportInk.ink900),
              ),
              pw.Text(
                label,
                style: _text(7.5, font: assets.medium, color: ReportInk.ink500),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  pw.Widget _section(String title, {PdfColor accent = ReportInk.jade700}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 7),
        child: pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 13,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              title,
              style: _text(12, font: assets.display, color: ReportInk.ink900),
            ),
          ],
        ),
      );

  // ── One person ─────────────────────────────────────────────────────────

  List<pw.Widget> _person(PersonReport person) {
    final subject = person.subject;
    final facts = [
      (l10n.attReportEmployeeId, subject.employeeId),
      (l10n.attReportDesignation, subject.designation),
      (l10n.attReportDepartment, subject.department),
      (l10n.attReportDivision, subject.division),
      (l10n.attReportLocation, subject.location),
      (l10n.attReportShift, subject.shift),
    ].where((fact) => fact.$2.trim().isNotEmpty).toList();
    final counts = {
      for (final mark in AttendanceMark.values) mark: person.count(mark),
    };
    return [
      pw.Builder(
        builder: (context) {
          _firstPageOf(context, person);
          return _banner(
            kicker: l10n.attReportTitle,
            title: subject.name.isEmpty ? subject.employeeId : subject.name,
            subtitle: [
              subject.designation,
              subject.department,
            ].where((part) => part.isNotEmpty).join(' · '),
          );
        },
      ),
      if (facts.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, value) in facts)
              pw.Container(
                width: (PdfPageFormat.a4.width - _margin * 2 - 12) / 3,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: pw.BoxDecoration(
                  color: ReportInk.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: ReportInk.sand300, width: 0.6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      label.toUpperCase(),
                      style: _text(
                        6.5,
                        font: assets.bold,
                        color: ReportInk.jade800,
                        spacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      value,
                      maxLines: 1,
                      style: _text(
                        9.5,
                        font: assets.semiBold,
                        color: ReportInk.ink900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
      if (person.failed)
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: ReportInk.coral50,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: ReportInk.coral500, width: 0.8),
          ),
          child: pw.Text(
            l10n.attReportLoadFailed,
            style: _text(10, font: assets.semiBold, color: ReportInk.coral800),
          ),
        )
      else ...[
        pw.SizedBox(height: 12),
        _counts(
          onTime: counts[AttendanceMark.onTime]!,
          late: counts[AttendanceMark.late]!,
          leave: counts[AttendanceMark.leave]!,
          absent: counts[AttendanceMark.absent]!,
          off: counts[AttendanceMark.weekend]!,
          total: person.days.length,
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _keyFigure(
              l10n.attReportRate,
              _percent(person.rate),
              ReportInk.jade700,
            ),
            pw.SizedBox(width: 6),
            _keyFigure(
              l10n.attReportHours,
              _hours(person.worked),
              ReportInk.gold500,
            ),
            pw.SizedBox(width: 6),
            _keyFigure(
              l10n.attReportWorkingDays,
              '${person.workingDays}',
              ReportInk.sky500,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        _spread(counts),
        if (person.days.length <= 93) ...[
          _section(l10n.attReportGlance, accent: ReportInk.gold500),
          _glance(person.days),
        ],
        _section(l10n.attReportDaily),
        _dailyTable(person.days),
      ],
      _section(l10n.attReportLeaves, accent: ReportInk.sky500),
      _leaveTable(person.leaves),
    ];
  }

  /// The period as a calendar of weeks from Monday, each day in its colour.
  pw.Widget _glance(List<AttendanceDay> days) {
    if (days.isEmpty) return pw.SizedBox();
    final byDay = {for (final day in days) day.day: day};
    final first = days.first.day;
    final last = days.last.day;
    final start = first.subtract(
      Duration(days: first.weekday - DateTime.monday),
    );
    final weekday = DateFormat.E(locale);
    final cells = <pw.Widget>[];
    for (
      var day = start;
      !day.isAfter(last) || day.weekday != DateTime.monday;
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final entry = byDay[day];
      final tone = entry == null ? null : _toneOf(entry.mark);
      cells.add(
        pw.Container(
          height: 24,
          margin: const pw.EdgeInsets.all(1.5),
          decoration: pw.BoxDecoration(
            color: tone?.tint ?? ReportInk.white,
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(
              color: tone?.fill ?? ReportInk.ivory200,
              width: entry == null ? 0.4 : 0.8,
            ),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '${day.day}',
                  style: _text(
                    8,
                    font: assets.bold,
                    color: tone?.ink ?? ReportInk.sand300,
                  ),
                ),
                if (day.day == 1)
                  pw.Text(
                    DateFormat.MMM(locale).format(day),
                    style: _text(5, color: tone?.ink ?? ReportInk.ink400),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final weeks = <pw.TableRow>[
      pw.TableRow(
        children: [
          for (var i = 0; i < 7; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Center(
                child: pw.Text(
                  weekday.format(DateTime(2024, 1, 1 + i)),
                  style: _text(
                    7,
                    font: assets.semiBold,
                    color: ReportInk.ink500,
                  ),
                ),
              ),
            ),
        ],
      ),
      for (var i = 0; i < cells.length; i += 7)
        pw.TableRow(children: cells.sublist(i, math.min(i + 7, cells.length))),
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: ReportInk.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: ReportInk.sand300, width: 0.6),
      ),
      child: pw.Table(children: weeks),
    );
  }

  pw.Widget _pill(String text, _Tone tone) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: pw.BoxDecoration(
      color: tone.tint,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: tone.fill, width: 0.6),
    ),
    child: pw.Text(
      text,
      style: _text(7.5, font: assets.semiBold, color: tone.ink),
    ),
  );

  pw.Widget _cell(
    String text, {
    pw.Font? font,
    PdfColor color = ReportInk.ink900,
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      textAlign: align,
      style: _text(8, font: font, color: color),
    ),
  );

  pw.TableRow _headRow(List<String> titles) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: ReportInk.jade950),
    repeat: true,
    children: [
      for (final title in titles)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(
            title.toUpperCase(),
            style: _text(
              6.5,
              font: assets.bold,
              color: ReportInk.white,
              spacing: 0.6,
            ),
          ),
        ),
    ],
  );

  pw.Widget _table(
    List<pw.TableRow> rows,
    Map<int, pw.TableColumnWidth> widths,
  ) => pw.Table(
    // Square, so it breaks cleanly across pages.
    border: const pw.TableBorder(
      left: pw.BorderSide(color: ReportInk.sand300, width: 0.6),
      right: pw.BorderSide(color: ReportInk.sand300, width: 0.6),
      bottom: pw.BorderSide(color: ReportInk.sand300, width: 0.6),
      horizontalInside: pw.BorderSide(color: ReportInk.ivory200, width: 0.4),
    ),
    columnWidths: widths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: rows,
  );

  pw.Widget _dailyTable(List<AttendanceDay> days) {
    final date = DateFormat.yMMMd(locale);
    final weekday = DateFormat.E(locale);
    return _table(
      [
        _headRow([
          l10n.attReportDate,
          l10n.attReportDay,
          l10n.attReportStatus,
          l10n.attReportCheckIn,
          l10n.attReportCheckOut,
          l10n.attReportWorked,
          l10n.attReportShift,
        ]),
        for (final (i, day) in days.indexed)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: day.mark == AttendanceMark.weekend
                  ? ReportInk.ivory200
                  : i.isEven
                  ? ReportInk.white
                  : ReportInk.jade50,
            ),
            children: [
              _cell(date.format(day.day), font: assets.semiBold),
              _cell(weekday.format(day.day), color: ReportInk.ink500),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _pill(_markName(day.mark), _toneOf(day.mark)),
                ),
              ),
              _cell(_time(day.checkIn)),
              _cell(_time(day.checkOut)),
              _cell(
                day.checkIn != null && day.checkOut != null
                    ? _hours(day.checkOut!.difference(day.checkIn!))
                    : '—',
                font: assets.semiBold,
                color: ReportInk.jade950,
              ),
              _cell(
                day.record?.shift?.trim().isNotEmpty ?? false
                    ? day.record!.shift!.trim()
                    : '—',
                color: ReportInk.ink500,
              ),
            ],
          ),
      ],
      const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(0.8),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1.2),
      },
    );
  }

  _Tone _leaveTone(String status) {
    final s = status.toLowerCase();
    if (s.contains('approv') || s.contains('accept')) {
      return _toneOf(AttendanceMark.onTime);
    }
    if (s.contains('reject') || s.contains('declin') || s.contains('cancel')) {
      return _toneOf(AttendanceMark.absent);
    }
    return _toneOf(AttendanceMark.late);
  }

  pw.Widget _leaveTable(List<EmpLeaveRecord> leaves) {
    if (leaves.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: ReportInk.sky50,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Text(
          l10n.attReportNoLeaves,
          style: _text(9, font: assets.medium, color: ReportInk.sky800),
        ),
      );
    }
    final date = DateFormat.yMMMd(locale);
    String day(String raw) {
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? (raw.isEmpty ? '—' : raw) : date.format(parsed);
    }

    return _table(
      [
        _headRow([
          l10n.attReportLeaveType,
          l10n.leaveFrom,
          l10n.leaveTo,
          l10n.attReportDays,
          l10n.attReportStatus,
          l10n.attReportAppliedOn,
          l10n.attReportRemarks,
        ]),
        for (final (i, leave) in leaves.indexed)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? ReportInk.white : ReportInk.sky50,
            ),
            children: [
              _cell(
                leave.leaveName.isEmpty ? '—' : leave.leaveName,
                font: assets.semiBold,
              ),
              _cell(day(leave.fromDate)),
              _cell(day(leave.toDate)),
              _cell(
                switch (leaveSpan(leave)) {
                  (final from?, final to?) =>
                    '${to.difference(from).inDays + 1}',
                  _ => '—',
                },
                font: assets.semiBold,
                color: ReportInk.sky800,
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: _pill(leave.status, _leaveTone(leave.status)),
                ),
              ),
              _cell(day(leave.appliedDate), color: ReportInk.ink500),
              _cell(
                leave.remarks.isEmpty ? '—' : leave.remarks,
                color: ReportInk.ink700,
              ),
            ],
          ),
      ],
      const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(0.6),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.2),
        6: pw.FlexColumnWidth(1.8),
      },
    );
  }

  // ── The team ───────────────────────────────────────────────────────────

  List<pw.Widget> _teamSummary() {
    final people = report.people.where((person) => !person.failed).toList();
    int sum(AttendanceMark mark) =>
        people.fold(0, (total, person) => total + person.count(mark));
    final days = people.fold(0, (total, person) => total + person.days.length);
    final working = people.fold(0, (t, p) => t + p.workingDays);
    final present = people.fold(0, (t, p) => t + p.present);
    final worked = people.fold(Duration.zero, (t, p) => t + p.worked);
    final counts = {for (final mark in AttendanceMark.values) mark: sum(mark)};
    return [
      _banner(
        kicker: l10n.attReportTitle,
        title: l10n.attReportTeamTitle,
        subtitle: l10n.attReportMembers(report.people.length),
      ),
      pw.SizedBox(height: 12),
      _counts(
        onTime: counts[AttendanceMark.onTime]!,
        late: counts[AttendanceMark.late]!,
        leave: counts[AttendanceMark.leave]!,
        absent: counts[AttendanceMark.absent]!,
        off: counts[AttendanceMark.weekend]!,
        total: days,
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          _keyFigure(
            l10n.attReportRate,
            _percent(working == 0 ? 0 : present / working),
            ReportInk.jade700,
          ),
          pw.SizedBox(width: 6),
          _keyFigure(l10n.attReportHours, _hours(worked), ReportInk.gold500),
          pw.SizedBox(width: 6),
          _keyFigure(
            l10n.attReportPeople,
            '${report.people.length}',
            ReportInk.sky500,
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      _spread(counts),
      _section(l10n.attReportPeople),
      _table(
        [
          _headRow([
            '#',
            l10n.attReportName,
            l10n.attendanceOnTime,
            l10n.attendanceLate,
            l10n.attendanceLeave,
            l10n.attendanceAbsent,
            l10n.attReportRate,
            l10n.attReportHours,
          ]),
          for (final (i, person) in report.people.indexed)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isEven ? ReportInk.white : ReportInk.jade50,
              ),
              children: [
                _cell('${i + 1}', color: ReportInk.ink500),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        person.subject.name.isEmpty
                            ? person.subject.employeeId
                            : person.subject.name,
                        style: _text(8.5, font: assets.semiBold),
                      ),
                      pw.Text(
                        [
                          person.subject.employeeId,
                          person.subject.designation,
                        ].where((part) => part.isNotEmpty).join(' · '),
                        style: _text(6.5, color: ReportInk.ink500),
                      ),
                    ],
                  ),
                ),
                if (person.failed) ...[
                  for (var c = 0; c < 6; c++)
                    _cell('—', color: ReportInk.coral800),
                ] else ...[
                  _cell(
                    '${person.count(AttendanceMark.onTime)}',
                    font: assets.semiBold,
                    color: ReportInk.jade950,
                  ),
                  _cell(
                    '${person.count(AttendanceMark.late)}',
                    font: assets.semiBold,
                    color: ReportInk.gold800,
                  ),
                  _cell(
                    '${person.count(AttendanceMark.leave)}',
                    font: assets.semiBold,
                    color: ReportInk.sky800,
                  ),
                  _cell(
                    '${person.count(AttendanceMark.absent)}',
                    font: assets.semiBold,
                    color: ReportInk.coral800,
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _percent(person.rate),
                          style: _text(
                            8,
                            font: assets.bold,
                            color: ReportInk.jade950,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        _bar(
                          person.rate,
                          ReportInk.jade700,
                          ReportInk.jade100,
                          height: 3,
                        ),
                      ],
                    ),
                  ),
                  _cell(_hours(person.worked), color: ReportInk.ink700),
                ],
              ],
            ),
        ],
        const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(2.6),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(0.8),
          4: pw.FlexColumnWidth(0.8),
          5: pw.FlexColumnWidth(0.9),
          6: pw.FlexColumnWidth(1.1),
          7: pw.FlexColumnWidth(1.1),
        },
      ),
    ];
  }
}
