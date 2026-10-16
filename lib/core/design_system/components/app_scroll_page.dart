import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_backdrop.dart';
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
/// reload.
class AppScrollPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final page = SafeArea(
      bottom: false,
      child: ResponsiveBuilder(
        builder: (context, layout) {
          final gutter = tightGutter && layout.isCompact
              ? AppSpacing.gutterHome
              : layout.gutter;
          final scroll = SingleChildScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.md,
              gutter,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          );
          final onRefresh = this.onRefresh;
          if (onRefresh == null) return scroll;
          return RefreshIndicator(
            color: context.colors.accent,
            onRefresh: onRefresh,
            child: scroll,
          );
        },
      ),
    );
    return switch (backdrop) {
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
