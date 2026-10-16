import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Goes back with a swipe in from the leading edge, as iOS does between
/// pages, for content that changes in place rather than as a page of its
/// own, such as a module's tabs. [child] follows the finger, casting a soft
/// shadow on its edge; let go far enough or fast enough and it slides away
/// and [onBack] runs, else it springs back.
///
/// Only a touch that starts at the edge takes part, so lists that scroll
/// sideways inside keep their own drags.
class AppSwipeBack extends StatefulWidget {
  const AppSwipeBack({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
  });

  final VoidCallback onBack;
  final Widget child;
  final bool enabled;

  @override
  State<AppSwipeBack> createState() => _AppSwipeBackState();
}

class _AppSwipeBackState extends State<AppSwipeBack>
    with SingleTickerProviderStateMixin {
  /// How far the content is out, as a share of the width.
  late final AnimationController _out = AnimationController.unbounded(
    vsync: this,
  );

  double _width = 1;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: AppMotion.swipeStiffness,
    damping: AppMotion.swipeDamping,
  );

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails details) {
    _out.value = (_out.value + details.primaryDelta! / _width).clamp(0.0, 1.0);
  }

  Future<void> _end(DragEndDetails details) async {
    final speed = details.primaryVelocity ?? 0;
    final away =
        _out.value > AppSizes.swipeBackShare || speed > AppSizes.swipeBackFling;
    if (!away) {
      await _out.animateWith(
        SpringSimulation(_spring, _out.value, 0, speed / _width),
      );
      return;
    }
    await _out.animateWith(
      SpringSimulation(_spring, _out.value, 1, speed / _width)
        ..tolerance = const Tolerance(distance: 0.01, velocity: 0.1),
    );
    if (!mounted) return;
    widget.onBack();
    _out.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    // The same tree whether or not it is enabled, so turning it on or off
    // never rebuilds [child] afresh and loses its state.
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth <= 0 ? 1 : box.maxWidth;
        return RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            if (widget.enabled)
              _EdgeDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<_EdgeDragRecognizer>(
                    () => _EdgeDragRecognizer(
                      edge: AppSizes.swipeBackEdge,
                      rtl: Directionality.of(context) == TextDirection.rtl,
                      width: _width,
                    ),
                    (recognizer) {
                      recognizer
                        ..onStart = (_) {
                          _out.stop();
                        }
                        ..onUpdate = _update
                        ..onEnd = (details) {
                          _end(details);
                        }
                        ..onCancel = () {
                          _end(DragEndDetails());
                        };
                    },
                  ),
          },
          child: ColoredBox(
            color: colors.background,
            child: AnimatedBuilder(
              animation: _out,
              builder: (context, child) {
                final out = _out.value;
                // Wrapped the same way at rest, so [child] keeps its state
                // when a swipe begins.
                return Transform.translate(
                  offset: Offset(out * _width, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (out > 0)
                          BoxShadow(
                            color: colors.shadow.withValues(
                              alpha: 0.18 * (1 - out),
                            ),
                            blurRadius: AppSizes.swipeBackShadow,
                          ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// A sideways drag that only takes touches starting at the leading edge.
class _EdgeDragRecognizer extends HorizontalDragGestureRecognizer {
  _EdgeDragRecognizer({
    required this.edge,
    required this.rtl,
    required this.width,
  });

  final double edge;
  final bool rtl;
  final double width;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final x = event.localPosition.dx;
    final atEdge = rtl ? x >= width - edge : x <= edge;
    if (atEdge) super.addAllowedPointer(event);
  }
}
