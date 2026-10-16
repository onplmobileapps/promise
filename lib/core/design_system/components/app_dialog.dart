import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/app_spheres.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// What a dialog is telling the user; it sets the badge's colour and mark.
enum AppDialogTone { success, error, warning, info, confirm }

/// Tells the user [message] in the app's dialog, as every passing message
/// is shown (the app has no toasts): titled for its [tone] unless given a
/// [title], with an OK to close it.
Future<void> showAppMessage(
  BuildContext context,
  String message, {
  AppDialogTone tone = AppDialogTone.info,
  String? title,
}) async {
  if (!context.mounted) return;
  final l10n = context.l10n;
  await showAppDialog(
    context: context,
    tone: tone,
    title:
        title ??
        switch (tone) {
          AppDialogTone.success => l10n.messageSuccessTitle,
          AppDialogTone.error => l10n.messageErrorTitle,
          AppDialogTone.warning => l10n.messageWarningTitle,
          AppDialogTone.info || AppDialogTone.confirm => l10n.messageInfoTitle,
        },
    message: message,
    primaryLabel: l10n.actionOk,
  );
}

/// Shows the app's one dialog for every message, error and confirmation.
///
/// Resolves to true when the primary action was chosen, false for the
/// secondary one, and null when dismissed.
Future<bool?> showAppDialog({
  required BuildContext context,
  required AppDialogTone tone,
  required String title,
  required String primaryLabel,
  String? message,
  Widget? content,
  String? secondaryLabel,
  AppGlyph? glyph,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppDialog(
      tone: tone,
      title: title,
      message: message,
      content: content,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      glyph: glyph,
    ),
  );
}

/// The dialog itself; use [showAppDialog] to present it. A 3D sphere badges
/// it, coloured and marked by its [tone].
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.tone,
    required this.title,
    required this.primaryLabel,
    this.message,
    this.content,
    this.secondaryLabel,
    this.glyph,
  });

  final AppDialogTone tone;
  final String title;
  final String? message;
  final Widget? content;
  final String primaryLabel;
  final String? secondaryLabel;

  /// The mark on the badge; the tone's own by default.
  final AppGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final spheres = context.spheres;
    final text = context.textTheme;
    final (sphere, mark) = switch (tone) {
      AppDialogTone.success => (spheres.jade, AppGlyphs.check),
      AppDialogTone.error => (spheres.coral, AppGlyphs.close),
      AppDialogTone.warning => (spheres.gold, AppGlyphs.triangleAlert),
      AppDialogTone.info => (spheres.sky, AppGlyphs.info),
      AppDialogTone.confirm => (spheres.coral, AppGlyphs.circleHelp),
    };
    return Dialog(
      backgroundColor: AppPalette.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.surface, colors.surfaceEnd],
            ),
            borderRadius: AppRadius.borderSheet,
            boxShadow: elevations.dialog,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // What the dialog says scrolls when it doesn't fit; the
              // actions stay in view below it.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl + AppSpacing.xs,
                    AppSpacing.xl,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Padding(
                          // Room for the halo.
                          padding: const EdgeInsets.all(AppSizes.dialogHalo),
                          child: _SphereBadge(
                            sphere: sphere,
                            mark: glyph ?? mark,
                          ),
                        ),
                      ),
                      AppSpacing.gapLg,
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall,
                      ),
                      if (message != null) ...[
                        AppSpacing.gapSm,
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium,
                        ),
                      ],
                      if (content != null) ...[AppSpacing.gapLg, content!],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg + AppSpacing.xxs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: primaryLabel,
                      size: AppButtonSize.medium,
                      variant: tone == AppDialogTone.confirm
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    if (secondaryLabel != null) ...[
                      AppSpacing.gapMd,
                      AppButton(
                        label: secondaryLabel!,
                        size: AppButtonSize.medium,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 3D sphere lit from the upper left, ringed by a soft halo, with [mark]
/// on it.
class _SphereBadge extends StatelessWidget {
  const _SphereBadge({required this.sphere, required this.mark});

  final SphereColors sphere;
  final AppGlyph mark;

  /// Where the light comes from, and where it fades.
  static const Alignment _light = Alignment(-0.3, -0.44);
  static const List<double> _stops = [0, 0.5, 1];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: _light,
          colors: [sphere.highlight, sphere.body, sphere.shade],
          stops: _stops,
        ),
        boxShadow: [
          BoxShadow(color: sphere.halo, spreadRadius: AppSizes.dialogHalo),
          ...context.elevations.sphere,
        ],
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(shadows: context.elevations.sphereInset),
        child: SizedBox.square(
          dimension: AppSizes.dialogBadge,
          child: Center(
            child: AppGlyphIcon(
              mark,
              size: AppSizes.dialogMark,
              color: sphere.mark,
            ),
          ),
        ),
      ),
    );
  }
}
