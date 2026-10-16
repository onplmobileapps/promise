import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Text whose lines come out about the same length, for short centred copy
/// such as a tagline. No word is left on its own on the last line.
///
/// It sets the text at the narrowest width that still needs no more lines
/// than the full width does.
class BalancedText extends StatelessWidget {
  const BalancedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String data;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final text = Text(data, style: style, textAlign: textAlign);
        if (!constraints.hasBoundedWidth) return text;
        return Align(
          heightFactor: 1,
          child: SizedBox(
            width: _balancedWidth(context, constraints.maxWidth),
            child: text,
          ),
        );
      },
    );
  }

  /// The narrowest width, to the pixel, at which [data] takes no more lines
  /// than it does at [maxWidth].
  double _balancedWidth(BuildContext context, double maxWidth) {
    // Measured exactly as [Text] will lay it out.
    final defaults = DefaultTextStyle.of(context);
    var effectiveStyle = style == null || style!.inherit
        ? defaults.style.merge(style)
        : style!;
    if (MediaQuery.boldTextOf(context)) {
      effectiveStyle = effectiveStyle.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    final painter = TextPainter(
      text: TextSpan(text: data, style: effectiveStyle),
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      locale: Localizations.maybeLocaleOf(context),
      textScaler: MediaQuery.textScalerOf(context),
      textWidthBasis: defaults.textWidthBasis,
      textHeightBehavior:
          defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
    );
    try {
      int linesAt(double width) {
        painter.layout(maxWidth: width);
        return painter.computeLineMetrics().length;
      }

      final lines = linesAt(maxWidth);
      if (lines < 2) return maxWidth;
      var fits = maxWidth;
      var tooNarrow = 0.0;
      while (fits - tooNarrow > 1) {
        final width = (fits + tooNarrow) / 2;
        if (linesAt(width) > lines) {
          tooNarrow = width;
        } else {
          fits = width;
        }
      }
      return math.min(fits.ceilToDouble(), maxWidth);
    } finally {
      painter.dispose();
    }
  }
}
