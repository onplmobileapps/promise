import 'package:flutter/material.dart';

/// A raised face that answers a tap with ink: [decoration]'s fill and
/// border lie under the ink, and its shadows fall outside the face.
///
/// Shadows painted as ink (an [Ink] decoration) are clipped to the
/// material's rectangle, which leaves a square patch of shadow behind
/// rounded corners; here they never are.
///
/// [decoration] gives the shape: a `borderRadius`, or [BoxShape.circle].
class AppInkSurface extends StatelessWidget {
  const AppInkSurface({
    super.key,
    required this.decoration,
    required this.onTap,
    required this.child,
  });

  final BoxDecoration decoration;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final circle = decoration.shape == BoxShape.circle;
    final radius = decoration.borderRadius?.resolve(Directionality.of(context));
    final shadows = decoration.boxShadow ?? const <BoxShadow>[];
    final face = Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration.copyWith(boxShadow: const []),
        child: InkWell(
          onTap: onTap,
          borderRadius: circle ? null : radius,
          customBorder: circle ? const CircleBorder() : null,
          child: child,
        ),
      ),
    );
    if (shadows.isEmpty) return face;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: decoration.shape,
        borderRadius: circle ? null : decoration.borderRadius,
        boxShadow: shadows,
      ),
      child: face,
    );
  }
}
