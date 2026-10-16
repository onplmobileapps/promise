import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/theme/app_frame.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';

/// The screens a layout is checked on: phones from the smallest to the
/// largest, phones on their side, and tablets.
const deviceSizes = <String, Size>{
  'iPhone SE 1st gen': Size(320, 568),
  'small Android': Size(360, 640),
  'iPhone 8': Size(375, 667),
  'iPhone 15': Size(393, 852),
  'Pixel 7 / CMF Phone 1': Size(412, 915),
  'iPhone 15 Pro Max': Size(430, 932),
  'Galaxy Z Fold cover': Size(344, 882),
  'Galaxy Z Flip': Size(412, 1005),
  'Galaxy Z Fold open': Size(690, 829),
  'small phone landscape': Size(640, 360),
  'phone landscape': Size(852, 393),
  'iPad mini': Size(744, 1133),
  'iPad landscape': Size(1180, 820),
  'Android tablet': Size(800, 1280),
};

/// Text scales a layout is checked at; the app caps the system setting at
/// [AppFonts.maxTextScale], so 2.0 shows that cap holding.
const textScales = [1.0, AppFonts.maxTextScale, 2.0];

/// Safe areas of a phone with a notch, in logical pixels.
const notchedPadding = FakeViewPadding(top: 47, bottom: 34);

/// Loads the app's fonts, so text measures as on a phone (the test font
/// draws every glyph a full em wide).
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load(AppFonts.text, [
    'assets/fonts/inter/Inter-Regular.ttf',
    'assets/fonts/inter/Inter-Medium.ttf',
    'assets/fonts/inter/Inter-SemiBold.ttf',
    'assets/fonts/inter/Inter-Bold.ttf',
  ]);
  await load(AppFonts.display, [
    'assets/fonts/outfit/Outfit-Medium.ttf',
    'assets/fonts/outfit/Outfit-SemiBold.ttf',
    'assets/fonts/outfit/Outfit-Bold.ttf',
  ]);
}

/// Pumps [screen] as the app would show it: the app's theme for
/// [platform], its strings, its cap on text scale, on a [size] screen.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(393, 852),
  double textScale = 1,
  TargetPlatform platform = TargetPlatform.android,
  FakeViewPadding padding = notchedPadding,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = size.width > size.height
      ? FakeViewPadding.zero
      : padding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme.copyWith(platform: platform),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          AppFrame(child: AppPerformanceScope(child: child!)),
      home: screen,
      routes: routes,
    ),
  );
  await tester.pump();
}

/// Every size, scale and platform pairing, named for the test that runs it.
Iterable<(String, Size, double, TargetPlatform)> layoutMatrix() sync* {
  for (final MapEntry(key: name, value: size) in deviceSizes.entries) {
    for (final scale in textScales) {
      for (final platform in const [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ]) {
        yield (
          '$name ${size.width.toInt()}x${size.height.toInt()} '
              'text x$scale ${platform.name}',
          size,
          scale,
          platform,
        );
      }
    }
  }
}

/// Scrolls [text] into view and taps it, then lets everything settle.
Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}
