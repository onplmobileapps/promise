import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_backdrop.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/responsive/responsive_builder.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The backdrop an [AppScrollPage] scrolls over.
enum AppPageBackdrop {
  /// The sage wash and pattern at the top, as on a module's home.
  wash,

  /// Soft blobs of colour, as on a form or a calendar.
  blobs,

  /// The wash and pattern in coral, as on a report of an accident.
  alert,
}

/// A screen's page that scrolls over the design's backdrop: [children] in
/// the readable width, inside the screen's gutter, clear of the status bar
/// and of a bottom bar laid over the page. [onRefresh] lets it be pulled to
/// reload. Its first cards rise into place one after another as it opens,
/// unless the phone asks for less motion or has little to spare.
class AppScrollPage extends StatefulWidget {
  const AppScrollPage({
    super.key,
    required this.children,
    this.onRefresh,
    this.backdrop = AppPageBackdrop.wash,
    this.tightGutter = false,
    this.controller,
  });

  final List<Widget> children;
  final RefreshCallback? onRefresh;
  final AppPageBackdrop backdrop;

  /// On phones, the narrower gutter of a dashboard full of cards.
  final bool tightGutter;

  /// Scrolls the page, as a sheet holding it does.
  final ScrollController? controller;

  @override
  State<AppScrollPage> createState() => _AppScrollPageState();
}

class _AppScrollPageState extends State<AppScrollPage>
    with SingleTickerProviderStateMixin {
  /// The whole entrance: each card's rise, the last one's starting the
  /// most steps behind the first.
  static final Duration _entranceLength =
      AppMotion.medium +
      AppMotion.entranceStep * (AppMotion.entranceStaggered - 1);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _entranceLength,
  );
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _entered = true;
    if (MediaQuery.disableAnimationsOf(context) || AppPerformance.lite) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// The share of the entrance the [index]th card rises in.
  Curve _riseOf(int index) {
    final total = _entranceLength.inMicroseconds;
    final start =
        AppMotion.entranceStep.inMicroseconds *
        index.clamp(0, AppMotion.entranceStaggered - 1) /
        total;
    return Interval(
      start,
      start + AppMotion.medium.inMicroseconds / total,
      curve: AppMotion.enter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    final page = SafeArea(
      bottom: false,
      child: ResponsiveBuilder(
        builder: (context, layout) {
          final gutter = widget.tightGutter && layout.isCompact
              ? AppSpacing.gutterHome
              : layout.gutter;
          final scroll = SingleChildScrollView(
            controller: widget.controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.md,
              gutter,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            // Scrolled as one picture, not painted afresh every frame.
            child: RepaintBoundary(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Every card is wrapped alike, before and after the
                      // entrance, so none loses its state to it.
                      for (final (index, child) in children.indexed)
                        _Rise(
                          key: switch (child.key) {
                            null => null,
                            final key => ValueKey<Key>(key),
                          },
                          entrance: _entrance,
                          curve: _riseOf(index),
                          child: child,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final onRefresh = widget.onRefresh;
          if (onRefresh == null) return scroll;
          return RefreshIndicator(
            color: context.colors.accent,
            onRefresh: onRefresh,
            child: scroll,
          );
        },
      ),
    );
    return switch (widget.backdrop) {
      AppPageBackdrop.wash => AppBackdrop(
        washHeight: AppSizes.pageWash,
        patternFade: AppSizes.pagePattern,
        child: page,
      ),
      AppPageBackdrop.alert => AppBackdrop(
        washHeight: AppSizes.pageWash,
        patternFade: AppSizes.pagePattern,
        washColor: context.colors.dangerContainer,
        patternColor: context.colors.dangerRing,
        child: page,
      ),
      AppPageBackdrop.blobs => AppBackdrop.blobs(
        blobIntensity: AppSizes.blobIntensityStrong,
        child: page,
      ),
    };
  }
}

/// One of a page's cards, faded in and risen into place as [entrance] runs
/// through its [curve].
class _Rise extends AnimatedWidget {
  const _Rise({
    super.key,
    required Animation<double> entrance,
    required this.curve,
    required this.child,
  }) : super(listenable: entrance);

  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = curve.transform((listenable as Animation<double>).value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, AppSizes.entranceRise * (1 - t)),
        child: child,
      ),
    );
  }
}
