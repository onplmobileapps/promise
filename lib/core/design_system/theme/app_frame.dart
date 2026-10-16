import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/scaled_text_scaler.dart';
import 'package:railway_hrms/core/design_system/theme/app_system_ui.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// What every screen sits in: system bars that match the active theme, and
/// text that grows with the phone's setting no larger than the layouts are
/// built for, then by [textScale] and in bold with [boldText], as the user
/// sets them in the app. [displayScale] draws everything larger, as the
/// iPhone's Display Zoom does, while keeping the screen at least
/// [AppSizes.zoomMinWidth] wide so the layouts still fit.
///
/// Flutter restyles the system bars only where something on screen asks
/// for a style, and otherwise leaves the last one in place. This frame asks
/// for the theme's style beneath everything, so when a screen that styled
/// the bars its own way goes, the bars go back to the theme's.
class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
    this.textScale = 1,
    this.boldText = false,
    this.displayScale = 1,
  });

  final Widget child;
  final double textScale;
  final bool boldText;
  final double displayScale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final media = MediaQuery.of(context);
    final system = media.textScaler.clamp(
      maxScaleFactor: AppFonts.maxTextScale,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.of(Theme.of(context).brightness),
      child: MediaQuery(
        data: media.copyWith(
          textScaler: textScale == 1
              ? system
              : ScaledTextScaler(system, textScale),
          boldText: media.boldText || boldText,
        ),
        child: SkeletonizerConfig(
          data: SkeletonizerConfigData(
            effect: PulseEffect(
              from: colors.surfaceMuted,
              to: colors.outline,
              duration: AppMotion.skeletonPulse,
            ),
            containersColor: colors.surfaceRaised,
          ),
          child: displayScale == 1
              ? child
              : _Zoom(scale: displayScale, child: child),
        ),
      ),
    );
  }
}

/// Lays [child] out on a screen [scale] times smaller than the phone's and
/// draws it enlarged to fill the phone, so all of it, touches included, is
/// [scale] times larger.
class _Zoom extends StatelessWidget {
  const _Zoom({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Never narrower than the layouts are built for.
    final zoom = math.max(
      1.0,
      math.min(scale, media.size.width / AppSizes.zoomMinWidth),
    );
    if (zoom == 1) return child;
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: media.size / zoom,
        child: MediaQuery(
          data: media.copyWith(
            size: media.size / zoom,
            padding: media.padding / zoom,
            viewPadding: media.viewPadding / zoom,
            viewInsets: media.viewInsets / zoom,
            systemGestureInsets: media.systemGestureInsets / zoom,
          ),
          child: child,
        ),
      ),
    );
  }
}
