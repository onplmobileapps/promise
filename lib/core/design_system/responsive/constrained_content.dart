import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';

/// Centres its child and caps its width, so forms and text keep a readable
/// measure on tablets while filling a phone.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.formMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
