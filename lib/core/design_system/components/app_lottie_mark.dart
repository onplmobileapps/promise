import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';

/// The marks the app draws on screen stroke by stroke, each a Lottie file
/// traced from its [AppGlyph], so the finished drawing is the glyph itself.
enum AppLottie {
  check('assets/lottie/check.json', AppGlyphs.check),
  cross('assets/lottie/cross.json', AppGlyphs.close),
  warning('assets/lottie/warning.json', AppGlyphs.triangleAlert),
  info('assets/lottie/info.json', AppGlyphs.info),
  upload('assets/lottie/upload.json', AppGlyphs.upload),
  download('assets/lottie/download.json', AppGlyphs.download);

  const AppLottie(this.asset, this.glyph);

  final String asset;

  /// The mark as it stands once drawn, shown in its place when it cannot
  /// be played.
  final AppGlyph glyph;

  /// The mark drawn for [glyph], if there is one.
  static AppLottie? of(AppGlyph glyph) {
    for (final mark in values) {
      if (identical(mark.glyph, glyph)) return mark;
    }
    return null;
  }
}

/// [mark] drawn once in [color] at [size], as a dialog's badge shows it.
/// A phone that asks for less motion sees the finished glyph at once; a
/// stroke or two is light enough to draw on any other.
class AppLottieMark extends StatelessWidget {
  const AppLottieMark(
    this.mark, {
    super.key,
    required this.color,
    required this.size,
  });

  final AppLottie mark;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final still = AppGlyphIcon(mark.glyph, size: size, color: color);
    if (MediaQuery.disableAnimationsOf(context)) return still;
    return Lottie.asset(
      mark.asset,
      width: size,
      height: size,
      repeat: false,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.strokeColor(const ['**'], value: color),
        ],
      ),
      errorBuilder: (_, _, _) => still,
    );
  }
}
