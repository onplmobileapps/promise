import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// The form kit shared by the PRAMS and inspection forms: spacing, an
/// app bar, titled field groups and side-by-side fields.
class AppFormStyle {
  static const double cardRadius = 16.0;
  static const double inputRadius = 12.0;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  );

  static BoxDecoration cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class ResponsiveFieldGroup extends StatelessWidget {
  final Widget left;
  final Widget right;

  const ResponsiveFieldGroup({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

// ── SHARED: STANDARD NAVIGATION APP BAR ───────────────────────────────────

class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const FormAppBar({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: const Center(child: AppBackButton()),
      leadingWidth: AppSizes.minTapTarget + AppSpacing.md,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class FormGroup extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  const FormGroup({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = true,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text.rich(
              TextSpan(
                text: label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                children: isRequired
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
        child,
      ],
    );
  }
}
