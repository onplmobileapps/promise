import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/responsive/window_size_class.dart';

/// Builds for the space it is actually given (not the whole screen), so the
/// same widget lays out right in a phone, a tablet, a split screen or a
/// dialog.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, LayoutInfo layout) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, LayoutInfo(constraints)),
    );
  }
}
