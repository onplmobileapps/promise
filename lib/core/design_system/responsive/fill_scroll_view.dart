import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A screen's [body] at the top and an optional [footer] at the foot. When
/// they fit, the footer sits at the bottom of the viewport; when they don't
/// (a short phone, landscape, the keyboard up), the whole thing scrolls.
///
/// It sizes from real layout rather than intrinsic heights, which some
/// widgets under-report, so nothing can overflow.
class FillScrollView extends StatelessWidget {
  const FillScrollView({
    super.key,
    required this.body,
    this.footer,
    this.padding = EdgeInsets.zero,
  });

  final Widget body;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // Scrolling, as to reach the key under a field, leaves the keyboard
        // up: the form is still being filled in.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: padding,
        // Scrolled as one picture, not painted afresh every frame.
        child: RepaintBoundary(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - padding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [body, ?footer],
            ),
          ),
        ),
      ),
    );
  }
}
