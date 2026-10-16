import 'package:flutter/material.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The PROMISE lockup: the emblem, and the wordmark under it.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.emblemWidth,
    this.showWordmark = true,
  });

  /// An emblem width that suits a screen whose shorter side is
  /// [shortestSide].
  static double emblemWidthFor(double shortestSide) =>
      (shortestSide * AppSizes.emblemShare).clamp(
        AppSizes.emblemMin,
        AppSizes.emblemMax,
      );

  final double emblemWidth;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppEmblem(width: emblemWidth),
        if (showWordmark) ...[
          SizedBox(height: emblemWidth * 0.12 + AppSpacing.xs),
          AppWordmark(width: emblemWidth * AppSizes.wordmarkToEmblem),
        ],
      ],
    );
  }
}

/// The PROMISE emblem on its own, [width] across. Without a width it fills
/// the width its parent allows, such as the middle of an `AppDome`.
class AppEmblem extends StatelessWidget {
  const AppEmblem({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) => _FittedAsset(
    asset: AppAssets.emblem,
    aspectRatio: AppSizes.emblemAspectRatio,
    semanticLabel: context.l10n.appEmblemLabel,
    width: width,
  );
}

/// The PROMISE wordmark on its own, [width] across. Without a width it
/// fills the width its parent allows.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) => _FittedAsset(
    asset: AppAssets.wordmark,
    aspectRatio: AppSizes.wordmarkAspectRatio,
    semanticLabel: context.l10n.appName,
    width: width,
  );
}

/// An image asset of a known [aspectRatio], decoded at the size it is shown
/// rather than the file's own.
class _FittedAsset extends StatelessWidget {
  const _FittedAsset({
    required this.asset,
    required this.aspectRatio,
    required this.semanticLabel,
    this.width,
  });

  final String asset;
  final double aspectRatio;
  final String semanticLabel;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final width = this.width;
    if (width != null) return _image(context, width);
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'Give $asset a width, or a parent that bounds it.',
        );
        return _image(context, constraints.maxWidth);
      },
    );
  }

  Widget _image(BuildContext context, double width) => Image.asset(
    asset,
    width: width,
    height: width / aspectRatio,
    fit: BoxFit.contain,
    cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
    semanticLabel: semanticLabel,
  );
}
