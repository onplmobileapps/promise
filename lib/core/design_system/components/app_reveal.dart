import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';

/// [child] coming into view: it rises a little and fades in, once, as it
/// first appears — the [index]th of a list a moment after the one before,
/// so the list arrives in a ripple. Built again, it stays put.
///
/// Still, and at once, for those who ask for less motion and on a phone
/// drawing lite.
class AppReveal extends StatefulWidget {
  const AppReveal({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Its place in the list it is part of.
  final int index;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: AppMotion.reveal,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _in,
    curve: AppMotion.enter,
  );
  bool _started = false;
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context) ||
        AppPerformance.liteOf(context)) {
      _in.value = 1;
      return;
    }
    final turn = widget.index.clamp(0, AppMotion.revealStaggerMost);
    if (turn == 0) {
      _in.forward();
    } else {
      _wait = Timer(AppMotion.revealStagger * turn, _in.forward);
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      // A screen reader finds it while it is still fading in.
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, AppMotion.revealRise * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
