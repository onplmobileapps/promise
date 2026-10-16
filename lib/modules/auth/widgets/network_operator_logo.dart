import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/auth/data/models/network_operator.dart';

/// A network's logo in a rounded square, [size] across, with a tower icon
/// if the image can't be read.
class NetworkOperatorLogo extends StatelessWidget {
  const NetworkOperatorLogo({
    super.key,
    required this.operator,
    required this.size,
  });

  final NetworkOperator operator;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderSm,
      child: Image.asset(
        operator.logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (context, _, _) => AppGlyphIcon(
          AppGlyphs.signal,
          size: size * 0.8,
          color: context.colors.iconAccent,
        ),
      ),
    );
  }
}
