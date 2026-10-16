import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';

/// [children] in rows of [columns], every row as tall as its tallest child
/// so the cards in it line up, [spacing] apart both ways. A short last row
/// keeps its cells the width of the rest.
class AppGrid extends StatelessWidget {
  const AppGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = AppSpacing.md,
  }) : assert(columns > 0);

  final int columns;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start > 0) SizedBox(height: spacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + columns; i++) ...[
                  if (i > start) SizedBox(width: spacing),
                  Expanded(
                    child: i < children.length
                        ? children[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
