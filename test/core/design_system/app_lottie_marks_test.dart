import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final mark in AppLottie.values) {
    test(
      '${mark.name} is a Lottie that draws on and ends on its glyph',
      () async {
        final composition = await LottieComposition.fromBytes(
          File(mark.asset).readAsBytesSync(),
        );
        expect(composition.duration, greaterThan(Duration.zero));
        expect(composition.layers, isNotEmpty);
        expect(AppLottie.of(mark.glyph), mark);
      },
    );
  }

  for (final (tone, mark) in [
    (AppDialogTone.success, AppLottie.check),
    (AppDialogTone.error, AppLottie.cross),
    (AppDialogTone.warning, AppLottie.warning),
    (AppDialogTone.info, AppLottie.info),
  ]) {
    testWidgets('a ${tone.name} dialog draws its ${mark.name}', (tester) async {
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppDialog(
              context: context,
              tone: tone,
              title: 'Title',
              primaryLabel: 'OK',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 400));
      final drawn = tester.widget<AppLottieMark>(find.byType(AppLottieMark));
      expect(drawn.mark, mark);
    });
  }

  testWidgets('a dialog given a glyph with a drawing draws it', (tester) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppDialog(
            context: context,
            tone: AppDialogTone.success,
            glyph: AppGlyphs.upload,
            title: 'Inspection submitted',
            primaryLabel: 'OK',
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<AppLottieMark>(find.byType(AppLottieMark)).mark,
      AppLottie.upload,
    );
  });
}
