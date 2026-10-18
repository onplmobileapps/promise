import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_lottie_mark.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
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
/// secondary one, and null when dismissed. The phone answers its [tone]
/// with a tap: a firm one for an error, a light one for a warning or a
/// question, none for a note.
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
  switch (tone) {
    case AppDialogTone.success:
      AppHaptics.success();
    case AppDialogTone.error:
      AppHaptics.error();
    case AppDialogTone.warning || AppDialogTone.confirm:
      AppHaptics.warning();
    case AppDialogTone.info:
      break;
  }
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
    // The mark draws itself on: the one given, where it has a drawing, or
    // the tone's own; any other stands.
    final given = glyph;
    final drawn = given != null
        ? AppLottie.of(given)
        : switch (tone) {
            AppDialogTone.success => AppLottie.check,
            AppDialogTone.error => AppLottie.cross,
            AppDialogTone.warning => AppLottie.warning,
            AppDialogTone.info => AppLottie.info,
            AppDialogTone.confirm => null,
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
                            drawn: drawn,
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
/// on it. It swells into place as the dialog opens, its halo spreading
/// after it, and [drawn], when given, draws the mark on stroke by stroke.
class _SphereBadge extends StatefulWidget {
  const _SphereBadge({required this.sphere, required this.mark, this.drawn});

  final SphereColors sphere;
  final AppGlyph mark;
  final AppLottie? drawn;

  @override
  State<_SphereBadge> createState() => _SphereBadgeState();
}

class _SphereBadgeState extends State<_SphereBadge>
    with SingleTickerProviderStateMixin {
  /// Where the light comes from, and where it fades.
  static const Alignment _light = Alignment(-0.3, -0.44);
  static const List<double> _stops = [0, 0.5, 1];

  /// How small the badge starts, and the shares of its arrival the sphere
  /// swells, the halo spreads and a standing mark fades in over.
  static const double _from = 0.72;
  static const Interval _swell = Interval(0, 0.8, curve: AppMotion.spring);
  static const Interval _spread = Interval(0.25, 1, curve: AppMotion.enter);
  static const Interval _show = Interval(0.35, 0.85, curve: AppMotion.enter);

  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: AppMotion.badge,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _arrival.value = 1;
    } else {
      _arrival.forward();
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sphere = widget.sphere;
    final drawn = widget.drawn;
    final elevations = context.elevations;
    final mark = drawn != null
        ? AppLottieMark(drawn, color: sphere.mark, size: AppSizes.dialogMark)
        : FadeTransition(
            opacity: _arrival.drive(CurveTween(curve: _show)),
            child: AppGlyphIcon(
              widget.mark,
              size: AppSizes.dialogMark,
              color: sphere.mark,
            ),
          );
    return AnimatedBuilder(
      animation: _arrival,
      builder: (context, child) {
        final t = _arrival.value;
        final swell = _swell.transform(t);
        return Opacity(
          opacity: Curves.easeOut.transform(t.clamp(0, 0.4) / 0.4),
          child: Transform.scale(
            scale: _from + (1 - _from) * swell,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: _light,
                  colors: [sphere.highlight, sphere.body, sphere.shade],
                  stops: _stops,
                ),
                boxShadow: [
                  BoxShadow(
                    color: sphere.halo,
                    spreadRadius: AppSizes.dialogHalo * _spread.transform(t),
                  ),
                  ...elevations.sphere,
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: CustomPaint(
        painter: InsetShadowPainter(shadows: elevations.sphereInset),
        child: SizedBox.square(
          dimension: AppSizes.dialogBadge,
          child: Center(child: mark),
        ),
      ),
    );
  }
}
