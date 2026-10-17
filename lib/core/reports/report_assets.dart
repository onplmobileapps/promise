import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:railway_hrms/core/constants/app_assets.dart';

/// The fonts and logo a report is drawn with, read once from the app.
class ReportAssets {
  const ReportAssets({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.bold,
    required this.display,
    required this.logo,
    required this.emblem,
    required this.poweredBy,
  });

  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font bold;

  /// Outfit, for headings and big numbers.
  final pw.Font display;

  /// The PROMISE wordmark.
  final pw.ImageProvider logo;

  /// The emblem the splash shows, faint behind every page.
  final pw.ImageProvider emblem;

  /// The company's logo, for "Powered by".
  final pw.ImageProvider poweredBy;

  static Future<ReportAssets> load() async {
    Future<pw.Font> font(String file) async =>
        pw.Font.ttf(await rootBundle.load(file));
    Future<pw.ImageProvider> image(String file) async =>
        pw.MemoryImage((await rootBundle.load(file)).buffer.asUint8List());
    return ReportAssets(
      regular: await font('assets/fonts/inter/Inter-Regular.ttf'),
      medium: await font('assets/fonts/inter/Inter-Medium.ttf'),
      semiBold: await font('assets/fonts/inter/Inter-SemiBold.ttf'),
      bold: await font('assets/fonts/inter/Inter-Bold.ttf'),
      display: await font('assets/fonts/outfit/Outfit-Bold.ttf'),
      logo: await image(AppAssets.wordmark),
      emblem: await image(AppAssets.emblemPng),
      poweredBy: await image(AppAssets.poweredByLogo),
    );
  }
}
