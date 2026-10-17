import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Matrix4;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/reports/report_ink.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';

/// Draws an [InspectionReport] as an A4 PDF, as the attendance reports are
/// drawn: a banner with what was inspected and by whom, then each section's
/// answers, coloured by how they read, its notes and photos, and at the
/// end the face checks the report is signed with. The app's emblem lies
/// faintly across every page.
class InspectionReportPdf {
  InspectionReportPdf(
    this.report,
    this.l10n,
    this.assets, {
    required this.locale,
  });

  final InspectionReport report;
  final AppLocalizations l10n;
  final ReportAssets assets;
  final String locale;

  static const _margin = 28.0;

  /// A section's photos on the report, at most.
  static const _photosPerSection = 6;

  /// Photos are drawn this wide, at most, in pixels: plenty for a page,
  /// and a report of many photos stays a few megabytes.
  static const _photoPixels = 900;

  Future<Uint8List> build() async {
    final photos = await _loadPhotos();
    final doc = pw.Document(
      title: '${report.title}${_subtitle.isEmpty ? '' : ' · $_subtitle'}',
      author: report.inspector,
      creator: 'PROMISE',
      theme: pw.ThemeData.withFont(base: assets.regular, bold: assets.bold),
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme,
        header: _runningHeader,
        footer: _footer,
        build: (_) => [
          _banner(),
          pw.SizedBox(height: 12),
          _summary(),
          for (final section in report.sections)
            if (!section.isEmpty) ..._section(section, photos),
          pw.SizedBox(height: 14),
          _signatures(photos),
        ],
      ),
    );
    return doc.save();
  }

  String get _subtitle => report.subtitle?.trim() ?? '';

  String _when(DateTime at) => DateFormat.yMMMd(locale).add_jm().format(at);

  // ── Photos ─────────────────────────────────────────────────────────────

  /// Every photo the report shows, by its stored path, made small enough
  /// for a page on a background isolate; one that can't be read is left
  /// out.
  Future<Map<String, pw.ImageProvider>> _loadPhotos() async {
    final paths = <String>{
      for (final section in report.sections)
        ...section.photos.take(_photosPerSection),
      ?report.signatures.start?.photoPath,
      ?report.signatures.submit?.photoPath,
    };
    final out = <String, pw.ImageProvider>{};
    for (final path in paths) {
      try {
        final file = await FootplateFileUtils.resolveAbsolutePath(path);
        final bytes = await Isolate.run(() => _shrink(file));
        if (bytes != null) out[path] = pw.MemoryImage(bytes);
      } catch (_) {
        // A photo gone from the phone isn't on the report.
      }
    }
    return out;
  }

  static Uint8List? _shrink(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) return null;
    final upright = img.bakeOrientation(decoded);
    final small = upright.width > _photoPixels
        ? img.copyResize(upright, width: _photoPixels)
        : upright;
    return img.encodeJpg(small, quality: 78);
  }

  // ── Text ───────────────────────────────────────────────────────────────

  pw.TextStyle _text(
    double size, {
    pw.Font? font,
    PdfColor color = ReportInk.ink900,
  }) =>
      pw.TextStyle(font: font ?? assets.regular, fontSize: size, color: color);

  // ── Page ───────────────────────────────────────────────────────────────

  pw.PageTheme get _pageTheme => pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(_margin, _margin, _margin, 20),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Container(color: ReportInk.ivory50),
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
                  child: pw.Container(height: 5, color: ReportInk.coral500),
                ),
                pw.Expanded(
                  child: pw.Container(height: 5, color: ReportInk.sky500),
                ),
              ],
            ),
          ),
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

  pw.Widget _runningHeader(pw.Context context) {
    if (context.pageNumber == 1) return pw.SizedBox();
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
            [report.title, if (_subtitle.isNotEmpty) _subtitle].join(' · '),
            style: _text(8.5, font: assets.semiBold, color: ReportInk.ink700),
          ),
        ],
      ),
    );
  }

  /// [text] as the brand writes its own name, the leading "e" of
  /// "e-Inspection" slanted, as the report's fonts have no italics.
  static List<pw.Widget> _brand(String text, pw.TextStyle style) {
    if (!RegExp(r'^e(?=[\s-]?[A-Z])').hasMatch(text)) {
      return [pw.Text(text, style: style)];
    }
    return [
      pw.Transform(
        transform: Matrix4.skewX(0.21),
        adjustLayout: true,
        child: pw.Text('e', style: style),
      ),
      pw.Text(text.substring(1), style: style),
    ];
  }

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
        ..._brand(
          l10n.inspPdfFooter,
          _text(7.5, font: assets.semiBold, color: ReportInk.jade800),
        ),
        pw.Text(
          '  ·  ${_when(report.date)}',
          style: _text(7.5, color: ReportInk.ink500),
        ),
        pw.Spacer(),
        pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: _text(7.5, font: assets.semiBold, color: ReportInk.ink500),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          l10n.poweredByLead,
          style: _text(7, font: assets.medium, color: ReportInk.ink500),
        ),
        pw.SizedBox(width: 5),
        pw.Image(assets.poweredBy, height: 12),
      ],
    ),
  );

  // ── Banner ─────────────────────────────────────────────────────────────

  pw.Widget _banner() {
    final facts = [
      ReportRow(l10n.inspPdfDate, _when(report.date)),
      if (report.inspector case final inspector? when inspector.isNotEmpty)
        ReportRow(l10n.inspPdfInspector, inspector),
      ...report.facts.where((fact) => fact.answered),
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: ReportInk.jade950,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      report.title,
                      style: _text(
                        20,
                        font: assets.display,
                        color: ReportInk.white,
                      ),
                    ),
                    if (_subtitle.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _subtitle,
                        style: _text(
                          11,
                          font: assets.semiBold,
                          color: ReportInk.jade200,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: ReportInk.white,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Image(assets.emblem, height: 24),
                    pw.SizedBox(width: 6),
                    pw.Image(assets.logo, height: 12),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (final fact in facts)
                pw.SizedBox(
                  width: 160,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        fact.label.toUpperCase(),
                        style: _text(
                          6.5,
                          font: assets.semiBold,
                          color: ReportInk.jade200,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        fact.value,
                        style: _text(
                          9.5,
                          font: assets.semiBold,
                          color: ReportInk.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary ────────────────────────────────────────────────────────────

  pw.Widget _summary() {
    final answered = report.sections.fold(
      0,
      (sum, s) => sum + s.rows.where((r) => r.answered).length,
    );
    final tiles = [
      (answered, ReportInk.jade950, ReportInk.jade100, ReportInk.jade700),
      (
        report.findings,
        ReportInk.coral800,
        ReportInk.coral50,
        ReportInk.coral500,
      ),
      (
        report.unanswered,
        ReportInk.ink700,
        ReportInk.ivory200,
        ReportInk.ink400,
      ),
    ];
    final labels = [
      l10n.inspPdfAnswered,
      l10n.inspPdfFindings,
      l10n.inspPdfUnanswered,
    ];
    return pw.Row(
      children: [
        for (final (i, (value, ink, tint, fill)) in tiles.indexed) ...[
          if (i > 0) pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(6, 8, 10, 8),
              decoration: pw.BoxDecoration(
                color: tint,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 3,
                    height: 28,
                    decoration: pw.BoxDecoration(
                      color: fill,
                      borderRadius: pw.BorderRadius.circular(1.5),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '$value',
                        style: _text(16, font: assets.display, color: ink),
                      ),
                      pw.Text(
                        labels[i],
                        style: _text(7.5, font: assets.semiBold, color: ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────

  List<pw.Widget> _section(
    ReportSection section,
    Map<String, pw.ImageProvider> photos,
  ) => [
    pw.SizedBox(height: 14),
    // The heading never ends a page alone: its first answer goes with it.
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: const pw.BoxDecoration(
            color: ReportInk.jade50,
            border: pw.Border(
              left: pw.BorderSide(color: ReportInk.jade700, width: 3),
            ),
          ),
          child: pw.Text(
            section.title,
            style: _text(11, font: assets.bold, color: ReportInk.jade950),
          ),
        ),
        if (section.rows.isNotEmpty) _row(section.rows.first, shaded: false),
      ],
    ),
    for (final (i, row) in section.rows.indexed.skip(1))
      _row(row, shaded: i.isOdd),
    if (section.note case final note? when note.trim().isNotEmpty)
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 6),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: ReportInk.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: ReportInk.sand300, width: 0.5),
        ),
        child: pw.Text(note.trim(), style: _text(8.5, color: ReportInk.ink700)),
      ),
    if (section.photos.any(photos.containsKey)) ...[
      pw.SizedBox(height: 6),
      pw.Text(
        l10n.inspPdfPhotos,
        style: _text(7.5, font: assets.semiBold, color: ReportInk.ink500),
      ),
      pw.SizedBox(height: 4),
      pw.Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final path in section.photos.take(_photosPerSection))
            if (photos[path] case final photo?)
              pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(
                  photo,
                  width: 168,
                  height: 118,
                  fit: pw.BoxFit.cover,
                ),
              ),
        ],
      ),
    ],
  ];

  pw.Widget _row(ReportRow row, {required bool shaded}) {
    final (ink, tint) = switch (row.tone) {
      ReportTone.good => (ReportInk.jade950, ReportInk.jade100),
      ReportTone.bad => (ReportInk.coral800, ReportInk.coral50),
      ReportTone.missing => (ReportInk.ink500, ReportInk.ivory200),
      ReportTone.plain => (ReportInk.ink900, ReportInk.white),
    };
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: shaded ? ReportInk.ivory200 : null,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              row.label,
              style: _text(8.5, font: assets.medium, color: ReportInk.ink700),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: tint,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  row.answered ? row.value : l10n.inspPdfUnanswered,
                  style: _text(8.5, font: assets.semiBold, color: ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Signatures ─────────────────────────────────────────────────────────

  pw.Widget _signatures(Map<String, pw.ImageProvider> photos) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: _signature(
          l10n.inspPdfStartVerified,
          report.signatures.start,
          photos,
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: _signature(
          l10n.inspPdfSubmitVerified,
          report.signatures.submit,
          photos,
        ),
      ),
    ],
  );

  pw.Widget _signature(
    String label,
    InspectionIdentity? identity,
    Map<String, pw.ImageProvider> photos,
  ) {
    final photo = identity == null ? null : photos[identity.photoPath];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: identity == null ? ReportInk.ivory200 : ReportInk.jade50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: identity == null ? ReportInk.sand300 : ReportInk.jade200,
          width: 0.6,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 48,
            height: 48,
            decoration: pw.BoxDecoration(
              color: ReportInk.white,
              borderRadius: pw.BorderRadius.circular(24),
              border: pw.Border.all(color: ReportInk.jade200, width: 0.8),
            ),
            child: photo == null
                ? null
                : pw.ClipOval(child: pw.Image(photo, fit: pw.BoxFit.cover)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: _text(
                    8.5,
                    font: assets.bold,
                    color: identity == null
                        ? ReportInk.ink500
                        : ReportInk.jade950,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  identity == null
                      ? l10n.inspPdfNotVerified
                      : _when(identity.verifiedAt),
                  style: _text(8, color: ReportInk.ink700),
                ),
                if (identity != null && identity.hasPlace)
                  pw.Text(
                    '${l10n.inspPdfLocation}: '
                    '${identity.latitude!.toStringAsFixed(5)}, '
                    '${identity.longitude!.toStringAsFixed(5)}',
                    style: _text(7, color: ReportInk.ink500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
