import 'package:flutter/painting.dart';

/// The two typefaces of the design and the weights they ship in, matching
/// the `fonts:` section of `pubspec.yaml`.
abstract final class AppFonts {
  /// Text, labels and controls.
  static const text = 'Inter';

  /// Headings and big numbers.
  static const display = 'Outfit';

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;

  /// The largest text scale the app follows from the system setting. Above
  /// this, fixed-height controls would start to crowd.
  static const double maxTextScale = 1.3;

  /// The app's name set as a wordmark in text, spaced out.
  static const double brandLetterSpacing = 0.9;

  /// Capitals in a small tag, spaced a little.
  static const double tagLetterSpacing = 0.5;

  /// Lines of a card's description, a little open.
  static const double cardLineHeight = 1.35;

  /// The splash's tagline, open enough for its coloured initials to read.
  static const double taglineHeight = 1.5;

  /// How far below a text button's words its underline sits, and how thick.
  static const double linkUnderlineGap = 5;
  static const double linkUnderline = 2;

  /// Capitals in a segmented tab, spaced out.
  static const double tabLetterSpacing = 1;

  /// The capitals under a progress step's dot.
  static const double stepLabelSize = 10;

  /// Big numbers: the hours at work, a count on a board, a ring's value.
  static const double metricHero = 44;
  static const double metricLarge = 24;
  static const double metricRing = 19;

  /// The hero number drawn a little tighter, as large type should be.
  static const double metricHeroLetterSpacing = -0.9;

  /// Digits of equal width, so counters and times don't jitter.
  static const tabularFigures = [FontFeature.tabularFigures()];
}
