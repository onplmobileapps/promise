import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// The frame every sign-in screen shares: the ivory wash with its khatam
/// texture, the safe areas, the content at the top and a [footer] at the
/// foot, scrolling when they don't fit. Nothing in it moves.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.builder,
    this.footer,
    this.appBar,
  });

  /// The screen's content for the space it has.
  final Widget Function(BuildContext context, LayoutInfo layout) builder;

  /// Pinned to the foot of the screen when there is room.
  final Widget? footer;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      // The wash and texture run up behind the app bar.
      extendBodyBehindAppBar: true,
      body: AppBackdrop.blobs(
        child: SafeArea(
          child: ResponsiveBuilder(
            builder: (context, layout) => FillScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: layout.gutter,
                vertical: AppSpacing.xl,
              ),
              body: builder(context, layout),
              footer: footer == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: footer,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
