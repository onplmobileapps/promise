import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/network/network_monitor.dart';

/// Shows the connection on every screen as a strip stuck to the top edge:
/// red while offline, amber while slow, and green for a moment when the
/// connection is back. The screen below moves down to make room rather
/// than being covered.
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;
  final NetworkMonitor? monitor;

  const NetworkStatusBanner({super.key, required this.child, this.monitor});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner>
    with SingleTickerProviderStateMixin {
  late final NetworkMonitor _monitor =
      widget.monitor ?? NetworkMonitor.instance;
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  Timer? _hideTimer;

  /// What the strip shows, kept while it slides away.
  NetworkStatus _shown = NetworkStatus.online;
  bool _checking = false;

  static const Duration _backOnlineFor = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _monitor.status.addListener(_onStatus);
    final now = _monitor.status.value;
    if (now != NetworkStatus.online) {
      _shown = now;
      _reveal.value = 1;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _monitor.status.removeListener(_onStatus);
    _reveal.dispose();
    super.dispose();
  }

  void _onStatus() {
    final next = _monitor.status.value;
    _hideTimer?.cancel();
    if (next == NetworkStatus.online) {
      // Only worth saying after a problem.
      if (_reveal.isDismissed) return;
      setState(() => _shown = NetworkStatus.online);
      _hideTimer = Timer(_backOnlineFor, () {
        if (mounted) _reveal.reverse();
      });
    } else {
      setState(() => _shown = next);
      _reveal.forward();
    }
  }

  Future<void> _retry() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await _monitor.check();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.padding.top;
    return AnimatedBuilder(
      animation: _reveal,
      // The app keeps its place in the tree whatever the strip does, so no
      // screen loses its state.
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.enter.transform(_reveal.value);
        // The strip takes over the status bar, so the screen below no
        // longer needs to keep clear of it.
        final screenInset = inset * (1 - t);
        return Column(
          // Laid out from the bottom so the strip paints after the app:
          // a route's modal barrier hides whatever painted before it from
          // screen readers.
          verticalDirection: VerticalDirection.up,
          children: [
            Expanded(
              child: MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(top: screenInset),
                  viewPadding: media.viewPadding.copyWith(
                    top: media.viewPadding.top * (1 - t),
                  ),
                ),
                child: child!,
              ),
            ),
            SizedBox(
              height: (inset + AppSizes.bannerHeight) * t,
              width: double.infinity,
              child: t == 0
                  ? null
                  : ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: inset + AppSizes.bannerHeight,
                        maxHeight: inset + AppSizes.bannerHeight,
                        child: _Strip(
                          status: _shown,
                          reason: _monitor.offlineReason,
                          topInset: inset,
                          checking: _checking,
                          onRetry: _retry,
                          onClose: () {
                            _hideTimer?.cancel();
                            _reveal.reverse();
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.status,
    required this.reason,
    required this.topInset,
    required this.checking,
    required this.onRetry,
    required this.onClose,
  });

  final NetworkStatus status;
  final OfflineReason reason;
  final double topInset;
  final bool checking;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  /// Between the title and the message.
  static const _separator = '  ·  ';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final noConnection = reason == OfflineReason.noConnection;
    final (
      Color tint,
      Color ink,
      AppGlyph glyph,
      String title,
      String message,
    ) = switch (status) {
      NetworkStatus.offline => (
        colors.dangerContainer,
        colors.onDangerContainer,
        AppGlyphs.wifiOff,
        noConnection ? l10n.networkOfflineTitle : l10n.networkNoInternetTitle,
        noConnection
            ? l10n.networkOfflineMessage
            : l10n.networkNoInternetMessage,
      ),
      NetworkStatus.slow => (
        colors.goldContainer,
        colors.onGoldContainer,
        AppGlyphs.gauge,
        l10n.networkSlowTitle,
        l10n.networkSlowMessage,
      ),
      NetworkStatus.online => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        AppGlyphs.wifi,
        l10n.networkBackOnlineTitle,
        l10n.networkBackOnlineMessage,
      ),
    };
    // The strip is pale in the light theme and deep in the dark one, like
    // the screens, so the status bar keeps the theme's style over it.
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.networkStatusAnnouncement(title, message),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        padding: EdgeInsets.only(top: topInset),
        // Over the surface, so the dark theme's see-through tints still
        // make a solid strip.
        color: Color.alphaBlend(tint, colors.surface),
        // Drawn over the strip rather than inside it, so the hairline takes
        // no height from the button.
        foregroundDecoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outline)),
        ),
        // Above the navigator, so the strip brings its own text defaults.
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: AppSizes.bannerHeight,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.short,
                    child: AppGlyphIcon(
                      glyph,
                      key: ValueKey(glyph),
                      color: ink,
                      size: AppSizes.iconSm,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: const TextStyle(fontWeight: AppFonts.bold),
                            ),
                            TextSpan(text: '$_separator$message'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                  switch (status) {
                    NetworkStatus.offline when checking => SizedBox.square(
                      dimension: AppSizes.minTapTarget,
                      child: Center(
                        child: SizedBox.square(
                          dimension: AppSizes.iconSm,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: AppSizes.spinnerStroke,
                            valueColor: AlwaysStoppedAnimation(ink),
                          ),
                        ),
                      ),
                    ),
                    NetworkStatus.offline => TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: ink,
                        textStyle: context.textTheme.labelLarge,
                        minimumSize: const Size.square(AppSizes.minTapTarget),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                      ),
                      child: Text(l10n.networkRetry),
                    ),
                    NetworkStatus.slow => IconButton(
                      // No tooltip: the strip sits above the navigator's
                      // overlay.
                      onPressed: onClose,
                      color: ink,
                      iconSize: AppSizes.iconSm,
                      icon: AppGlyphIcon(
                        AppGlyphs.close,
                        semanticLabel: l10n.actionClose,
                      ),
                    ),
                    NetworkStatus.online => AppSpacing.gapMd,
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
