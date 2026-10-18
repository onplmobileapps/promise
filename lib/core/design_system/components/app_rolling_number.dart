import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';

/// [value] in [style], each digit rolling to its new figure as on an iOS
/// picker or a flip calendar: the old figure slides out of its slot as the
/// new one slides in, up when the number grows and down when it falls,
/// the digits on the right going a moment before those on the left.
///
/// Shown at once, still, for those who ask for less motion.
class AppRollingNumber extends StatelessWidget {
  const AppRollingNumber(this.value, {super.key, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style
        .merge(this.style)
        .copyWith(
          // Every figure the same width, so the number doesn't shuffle.
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final text = '$value';
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < text.length; i++)
              _Digit(
                // Keyed from the right, so a units digit stays a units digit
                // as the number gains a figure.
                key: ValueKey(text.length - i),
                char: text[i],
                style: style,
                still: still,
                delay: AppMotion.revealStagger * (text.length - 1 - i),
              ),
          ],
        ),
      ),
    );
  }
}

class _Digit extends StatefulWidget {
  const _Digit({
    super.key,
    required this.char,
    required this.style,
    required this.still,
    required this.delay,
  });

  final String char;
  final TextStyle style;
  final bool still;
  final Duration delay;

  @override
  State<_Digit> createState() => _DigitState();
}

class _DigitState extends State<_Digit> with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late String _from = widget.char;
  bool _up = true;
  Timer? _wait;

  @override
  void didUpdateWidget(_Digit old) {
    super.didUpdateWidget(old);
    if (old.char == widget.char) return;
    _from = old.char;
    final a = int.tryParse(old.char) ?? 0;
    final b = int.tryParse(widget.char) ?? 0;
    _up = b >= a;
    if (widget.still) {
      _roll.value = 1;
      return;
    }
    _roll.value = 0;
    _wait?.cancel();
    _wait = Timer(widget.delay, _roll.forward);
  }

  @override
  void dispose() {
    _wait?.cancel();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: '0', style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.height;
    final width = painter.width;
    painter.dispose();
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _roll,
          builder: (context, _) {
            final t = Curves.easeOutBack.transform(_roll.value);
            if (_roll.value == 1) return Text(widget.char, style: widget.style);
            final dir = _up ? -1.0 : 1.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(0, dir * height * t),
                  child: Opacity(
                    opacity: (1 - _roll.value).clamp(0.0, 1.0),
                    child: Text(_from, style: widget.style),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -dir * height * (1 - t)),
                  child: Text(widget.char, style: widget.style),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
