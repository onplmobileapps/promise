import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Shows a bottom sheet with the design's handle, title and close button.
/// On tablets it is capped at a readable width and centred.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required String closeLabel,
  required WidgetBuilder builder,
  String? subtitle,
  Widget? header,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
    builder: (sheetContext) => AppSheet(
      title: title,
      subtitle: subtitle,
      header: header,
      closeLabel: closeLabel,
      child: builder(sheetContext),
    ),
  );
}

/// The frame of a bottom sheet; [showAppSheet] presents it.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.closeLabel,
    required this.child,
    this.subtitle,
    this.header,
  });

  /// Named for screen readers; shown unless a [header] takes its place.
  final String title;

  /// A header of the sheet's own, like a banner, in place of the title,
  /// the subtitle and the close button; it can hold an
  /// [AppSheetCloseButton] itself.
  final Widget? header;

  /// A quiet line under the title, like what the sheet lists.
  final String? subtitle;
  final String closeLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final subtitle = this.subtitle;
    final header = this.header;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.smd,
        bottom: AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.outlineStrong,
                borderRadius: AppRadius.borderPill,
              ),
              child: const SizedBox(
                width: AppSizes.sheetHandleWidth,
                height: AppSizes.sheetHandleHeight,
              ),
            ),
          ),
          AppSpacing.gapMd,
          header ??
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(title, style: text.headlineSmall),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(subtitle, style: text.bodySmall),
                      ],
                    ),
                  ),
                  AppSheetCloseButton(label: closeLabel),
                ],
              ),
          AppSpacing.gapMd,
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// A sheet's close button: a small raised disc with a cross, inside a full
/// tap target.
class AppSheetCloseButton extends StatelessWidget {
  const AppSheetCloseButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Center(
            child: AppInkSurface(
              onTap: () => Navigator.of(context).pop(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
                ),
                boxShadow: context.elevations.raised,
              ),
              child: SizedBox.square(
                dimension: AppSizes.sheetClose,
                child: Center(
                  child: AppGlyphIcon(
                    AppGlyphs.close,
                    size: AppSizes.iconSm,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
