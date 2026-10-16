import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// A form's title and the line under it, with an optional action beside
/// them.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall),
              AppSpacing.gapXs,
              Text(subtitle, style: text.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...[AppSpacing.gapMd, trailing!],
      ],
    );
  }
}
