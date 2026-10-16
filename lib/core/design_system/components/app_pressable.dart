import 'package:flutter/material.dart';

/// Builds a face for its state: whether it is held down, and whether it has
/// the keyboard's focus.
typedef PressableBuilder =
    Widget Function(BuildContext context, bool pressed, bool focused);

/// Makes any face behave like a key. It can be tapped, it can be reached and
/// pressed from a keyboard, and a screen reader announces it as a button
/// named [label]. [builder] is told when the face is held down or focused,
/// so a 3D key can draw itself sunk or ringed. The change is instant, with
/// no animation.
///
/// A null [onPressed] disables it.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.label,
    required this.onPressed,
    required this.builder,
  });

  final String label;
  final VoidCallback? onPressed;
  final PressableBuilder builder;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // The gesture and focus detectors give the node its tap and focus
    // actions; the label replaces whatever the face says.
    return FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onPressed?.call(),
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: Semantics(
          button: true,
          enabled: _enabled,
          label: widget.label,
          child: ExcludeSemantics(
            child: widget.builder(context, _pressed && _enabled, _focused),
          ),
        ),
      ),
    );
  }
}
