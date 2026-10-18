import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';

/// [child] giving a little while a finger holds it down, and springing
/// back when let go, as a key does; still for those who ask for less
/// motion. It only watches the finger: what a tap does is the caller's.
class AppPressScale extends StatefulWidget {
  const AppPressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<AppPressScale> createState() => _AppPressScaleState();
}

class _AppPressScaleState extends State<AppPressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? AppMotion.pressScale : 1,
        duration: _down ? AppMotion.short * 0.5 : AppMotion.short,
        curve: _down ? Curves.easeOut : AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}
