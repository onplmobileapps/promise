import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/app/routes/app_route_registry.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/core/widgets/powered_by_badge.dart';

/// The first screen: the PROMISE lockup, centred and still, while the app
/// clears the last session and asks the store for a newer version. It then
/// opens sign-in, and offers the update over it if there is one.
class SplashView extends StatefulWidget {
  const SplashView({super.key, this.updater});

  /// How long the lockup stays up at the least.
  static const minimumDisplay = Duration(seconds: 2);

  /// The longest the splash waits for the store. A slower answer is let go
  /// for this launch; the next one asks again.
  static const updateCheckLimit = Duration(seconds: 4);

  /// Where updates come from; the app's own by default.
  final AppUpdater? updater;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final AppUpdater _updater = widget.updater ?? sl<AppUpdater>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final (_, _, update) = await (
      Future<void>.delayed(SplashView.minimumDisplay),
      StorageService.clearAuthData(navigate: false),
      _updater.check().timeout(
        SplashView.updateCheckLimit,
        onTimeout: () => null,
      ),
    ).wait;
    if (!mounted) return;

    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.login),
      builder: AppRouteRegistry.builderFor(AppRoutes.login)!,
    );
    Navigator.of(context).pushReplacement(route);
    if (update == null) return;
    // Offered over sign-in, once that screen has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screen = route.subtreeContext;
      if (screen == null || !screen.mounted) return;
      update.start(screen);
    });
  }

  @override
  Widget build(BuildContext context) => const SplashBody();
}

/// What the splash screen shows: the lockup centred on the ivory wash, and
/// the organisation's name at the foot. It has no behaviour of its own.
class SplashBody extends StatelessWidget {
  const SplashBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Always light, whatever the phone or the app is set to: the brand's
    // first face is its ivory and jade.
    return Theme(
      data: AppTheme.lightTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppSystemUi.lightTheme,
        child: Builder(builder: _build),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AppBackdrop.blobs(
        child: SafeArea(
          child: ResponsiveBuilder(
            builder: (context, layout) {
              final emblem = AppLogo.emblemWidthFor(
                layout.constraints.biggest.shortestSide,
              );
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.gutter,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Expanded(
                      // The lockup sits in the middle of the screen and
                      // shrinks rather than overflow on a short one.
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _Lockup(
                            emblemWidth: emblem,
                            taglineWidth: math.min(
                              AppSizes.splashTagline,
                              layout.constraints.maxWidth - layout.gutter * 2,
                            ),
                            tagline: l10n.splashTagline,
                          ),
                        ),
                      ),
                    ),
                    _Organisation(name: l10n.organisationName),
                    AppSpacing.gapLg,
                    const CreditsFooter(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Lockup extends StatelessWidget {
  const _Lockup({
    required this.emblemWidth,
    required this.taglineWidth,
    required this.tagline,
  });

  final double emblemWidth;
  final double taglineWidth;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(emblemWidth: emblemWidth),
        AppSpacing.gapXl,
        // Two lines, made smaller rather than broken into a third.
        SizedBox(
          width: taglineWidth,
          child: FittedBox(fit: BoxFit.scaleDown, child: _Tagline(tagline)),
        ),
      ],
    );
  }
}

/// The name the app spells, on two lines as even as its words allow: each
/// capitalised word's first letter in jade and bold, so "P R O M I S E"
/// reads along it.
class _Tagline extends StatelessWidget {
  const _Tagline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.textTheme.titleMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: AppFonts.medium,
      height: AppFonts.taglineHeight,
    );
    final initial = base?.copyWith(
      color: colors.accent,
      fontWeight: AppFonts.bold,
    );
    final words = text.split(' ');
    final breakAt = _evenBreak(words);
    return Text.rich(
      TextSpan(
        children: [
          for (final (index, word) in words.indexed) ...[
            if (index > 0) TextSpan(text: index == breakAt ? '\n' : ' '),
            if (word.isNotEmpty &&
                word[0] == word[0].toUpperCase() &&
                word[0] != word[0].toLowerCase()) ...[
              TextSpan(text: word[0], style: initial),
              TextSpan(text: word.substring(1)),
            ] else
              TextSpan(text: word),
          ],
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      style: base,
    );
  }

  /// The word the second line starts with, so the longer line is as short
  /// as it can be.
  static int _evenBreak(List<String> words) {
    if (words.length < 2) return words.length;
    var best = 1;
    var bestLongest = double.infinity;
    for (var at = 1; at < words.length; at++) {
      final first = words.take(at).join(' ').length;
      final second = words.skip(at).join(' ').length;
      final longest = math.max(first, second).toDouble();
      if (longest < bestLongest) {
        bestLongest = longest;
        best = at;
      }
    }
    return best;
  }
}

/// The organisation's name at the foot, spaced out between two short rules.
class _Organisation extends StatelessWidget {
  const _Organisation({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget rule() => SizedBox(
      width: AppSpacing.xxl,
      height: AppSizes.ruleThickness,
      child: ColoredBox(color: colors.ornamentAccent),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        rule(),
        AppSpacing.gapMd,
        Flexible(
          child: Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.accent,
              letterSpacing: AppFonts.brandLetterSpacing * 2,
            ),
          ),
        ),
        AppSpacing.gapMd,
        rule(),
      ],
    );
  }
}
