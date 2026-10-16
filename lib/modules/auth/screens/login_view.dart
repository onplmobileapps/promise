import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/widgets/powered_by_badge.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/widgets/auth_scaffold.dart';
import 'package:railway_hrms/modules/auth/widgets/employee_sign_in_form.dart';

// import 'package:railway_hrms/modules/auth/widgets/mobile_sign_in_form.dart';

/// The two ways in.
enum LoginTab {
  /// Travellers, by mobile number and a one-time code.
  // trainTracking,

  /// Employees, by employee ID and password.
  promise,
}

/// Sign-in: the PROMISE lockup in the middle, the two tabs under it, and the
/// chosen tab's form in a card. Nothing animates; switching tabs is instant
/// and each form keeps what was typed into it.
class LoginView extends StatefulWidget {
  const LoginView({super.key, this.initialTab = LoginTab.promise});

  final LoginTab initialTab;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: LoginTab.values.length,
    initialIndex: widget.initialTab.index,
    animationDuration: Duration.zero,
    vsync: this,
  );

  /// The screen coming in: the logo, the greeting and the card rise into
  /// place one after another.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.loginEntrance,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.isAnimating || _entrance.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _tabs.dispose();
    super.dispose();
  }

  /// [child] rising into place as the [order]th piece of the screen.
  ///
  /// Keyed by its order: with the keyboard up the wordmark and greeting
  /// step aside, and without keys the card would be taken for one of them
  /// and built anew, its fields losing focus and the keyboard closing.
  Widget _rise(int order, Widget child) => _Rise(
    key: ValueKey(order),
    entrance: _entrance,
    order: order,
    child: child,
  );

  void _openHome() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>(),
      child: AuthScaffold(
        footer: Center(child: const CreditsFooter()),
        builder: (context, layout) {
          // With the keyboard up or the phone on its side the medallion
          // shrinks and the wordmark steps aside, so the form stays in view.
          // It also gives way on a phone not tall enough for it and the card,
          // so the footer stays in view.
          // Not tall enough for all of it, as most phones once their bars
          // are taken off: the greeting's line and the card's notes step
          // aside and the medallion is at its least, so it all fits.
          final height = layout.constraints.biggest.height;
          final compact = height < AppBreakpoints.loginRoomy;
          // Tighter still, the greeting steps aside too.
          final tight = height < AppBreakpoints.loginTight;
          final medallion = layout.isShort || compact
              ? AppSizes.medallionMin
              : math.max(
                  AppSizes.medallionMin,
                  math.min(
                    AppMedallion.diameterFor(
                      layout.constraints.biggest.shortestSide,
                    ),
                    layout.constraints.biggest.height *
                        AppSizes.loginMedallionHeightShare,
                  ),
                );
          return ConstrainedContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _rise(
                  0,
                  Center(
                    child: AppMedallion(
                      diameter: medallion,
                      child: const AppEmblem(),
                    ),
                  ),
                ),
                if (!layout.isShort) ...[
                  tight ? AppSpacing.gapXs : AppSpacing.gapSm,
                  _rise(
                    1,
                    Center(
                      child: AppWordmark(
                        width: medallion * AppSizes.wordmarkToMedallion,
                      ),
                    ),
                  ),
                  if (!tight) ...[
                    AppSpacing.gapLg,
                    _rise(
                      2,
                      _Welcome(
                        title: l10n.loginWelcomeTitle,
                        detail: compact
                            ? null
                            : l10n.loginWelcomeDetail(l10n.appName),
                        bold: l10n.appName,
                      ),
                    ),
                  ],
                ],
                tight ? AppSpacing.gapSm : AppSpacing.gapLg,
                // AppSegmentedTabs(
                //   controller: _tabs,
                //   segments: [
                //     AppSegment(
                //       label: l10n.loginTabTrainTracking,
                //       glyph: AppGlyphs.train,
                //     ),
                //     AppSegment(
                //       label: l10n.loginTabPromise,
                //       leading: const AppEmblem(width: AppSizes.tabLogo),
                //     ),
                //   ],
                // ),
                // AppSpacing.gapLg,
                _rise(
                  3,
                  AppCard.glass(
                    edge: context.colors.primaryEdge,
                    child: EmployeeSignInForm(
                      onSignedIn: _openHome,
                      compact: compact,
                      tight: tight,
                    ),
                    // child: ListenableBuilder(
                    //   listenable: _tabs,
                    //   builder: (context, _) => Column(
                    //     crossAxisAlignment: CrossAxisAlignment.stretch,
                    //     children: [
                    //       Visibility(
                    //         visible: _tabs.index == LoginTab.trainTracking.index,
                    //         maintainState: true,
                    //         child: const MobileSignInForm(),
                    //       ),
                    //       Visibility(
                    //         visible: _tabs.index == LoginTab.promise.index,
                    //         maintainState: true,
                    //         child: EmployeeSignInForm(onSignedIn: _openHome),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ),
                ),
                if (!tight) ...[
                  AppSpacing.gapMd,
                  _rise(
                    4,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppGlyphIcon(
                          AppGlyphs.train,
                          size: AppSizes.iconSm,
                          color: context.colors.iconAccent,
                        ),
                        AppSpacing.gapXs,
                        Flexible(
                          child: Text(
                            l10n.loginSecure,
                            style: context.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The greeting over the sign-in card: a heading, and a line under it with
/// [bold] in it set bold.
class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.title,
    required this.detail,
    required this.bold,
  });

  final String title;

  /// The line under the heading; none where room is short.
  final String? detail;
  final String bold;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineLarge,
          ),
        ),
        if (detail case final detail?) ...[
          AppSpacing.gapXs,
          Text.rich(
            TextSpan(
              children: [
                for (final (i, part) in detail.split(bold).indexed) ...[
                  if (i > 0)
                    TextSpan(
                      text: bold,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                  TextSpan(text: part),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// [child] fading in and rising a little into place, the [order]th piece
/// of the screen to arrive as [entrance] runs.
class _Rise extends StatelessWidget {
  const _Rise({
    super.key,
    required this.entrance,
    required this.order,
    required this.child,
  });

  final Animation<double> entrance;
  final int order;
  final Widget child;

  /// Where each piece starts, as a share of the entrance, and how much of
  /// it it takes.
  static const _stagger = 0.12;
  static const _span = 0.52;

  @override
  Widget build(BuildContext context) {
    final start = order * _stagger;
    final progress = CurvedAnimation(
      parent: entrance,
      curve: Interval(start, start + _span, curve: AppMotion.enter),
    );
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) => Opacity(
        opacity: progress.value,
        child: Transform.translate(
          offset: Offset(0, AppSizes.riseDistance * (1 - progress.value)),
          child: child,
        ),
      ),
    );
  }
}
