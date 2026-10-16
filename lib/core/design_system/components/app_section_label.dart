import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The small capitals over a group on a screen, like "ACCOUNT" or "TODAY".
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text.toUpperCase(), style: context.textTheme.labelSmall),
  );
}
