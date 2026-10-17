import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/app/notifications/notification_view.dart';
import 'package:railway_hrms/app/routes/app_route_registry.dart';
import 'package:railway_hrms/app/settings/settings_view.dart';
import 'package:railway_hrms/app/shell/home_view.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/navigation/shell_requests.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/utils/module_notifications.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_register_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_helpers.dart';
import 'package:railway_hrms/modules/hrms/widgets/attendance_gate.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';

/// The app once signed in: the home tab with its modules, the alerts and
/// the profile, under one navigation bar with check-in in its middle.
class PromiseDashboardView extends StatefulWidget {
  const PromiseDashboardView({super.key});

  @override
  State<PromiseDashboardView> createState() => _PromiseDashboardViewState();
}

/// The bar's tabs. Trains and check-in are actions rather than tabs.
enum _Tab { home, alerts, profile }

class _PromiseDashboardViewState extends State<PromiseDashboardView> {
  _Tab _tab = _Tab.home;

  /// The module open inside the home tab; empty for the home screen.
  String _module = '';

  /// The home tab's own pages: the home, and a module opened over it as a
  /// page, so it slides in and can be swiped away as on iOS.
  final _homePages = GlobalKey<NavigatorState>();

  /// Modules with a bottom navigation of their own hide the shell's.
  static const _ownNavigation = {AppRoutes.hrms, AppRoutes.inspection};

  @override
  void initState() {
    super.initState();
    ShellRequests.alerts.addListener(_openRequestedAlerts);
    // Inspections submitted with no connection go out from here on, as
    // soon as there is one.
    if (sl.isRegistered<InspectionOutbox>()) {
      unawaited(sl<InspectionOutbox>().start());
    }
    // Notifications are asked for once the user is in, once only, and with
    // the reason before the system's prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // A notification tapped before signing in opens here, now.
      _openRequestedAlerts();
      await sl<PermissionGate>().request(
        AppPermission.notifications,
        context: context,
        once: true,
      );
    });
  }

  @override
  void dispose() {
    ShellRequests.alerts.removeListener(_openRequestedAlerts);
    super.dispose();
  }

  void _openRequestedAlerts() {
    if (mounted && ShellRequests.takeAlerts()) _select(_Tab.alerts);
  }

  void _select(_Tab tab) {
    if (!mounted) return;
    // Another tab closes any module over the home.
    if (tab != _Tab.home) _homePages.currentState?.popUntil((r) => r.isFirst);
    setState(() {
      _tab = tab;
      _module = '';
    });
  }

  Future<void> _openModule(String route) async {
    if (!mounted || route == _module) return;
    final builder = AppRouteRegistry.builderFor(route);
    final pages = _homePages.currentState;
    if (builder == null || pages == null) return;
    setState(() {
      _tab = _Tab.home;
      _module = route;
    });
    await pages.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: builder,
      ),
    );
    // Closed: by its back key, a swipe or the system's back.
    if (mounted && _module == route) setState(() => _module = '');
  }

  void _closeModule() => _homePages.currentState?.maybePop();

  /// Live tracking has its own navigation and back handling, so it opens
  /// over the whole app.
  void _openTrains() => Navigator.of(
    context,
    rootNavigator: true,
  ).pushNamed(AppRoutes.liveTracking);

  void _onBack() {
    if (_tab != _Tab.home) return _select(_Tab.home);
    final pages = _homePages.currentState;
    // A module's page, or one it opened: back off it, as the page allows
    // (HRMS first goes back to its own home).
    if (pages != null && pages.canPop()) {
      pages.maybePop();
      return;
    }
    _confirmExit();
  }

  Future<void> _confirmExit() async {
    final l10n = context.l10n;
    final close = await showAppDialog(
      context: context,
      tone: AppDialogTone.confirm,
      glyph: AppGlyphs.logOut,
      title: l10n.exitTitle,
      message: l10n.exitMessage,
      primaryLabel: l10n.exitConfirm,
      secondaryLabel: l10n.actionCancel,
    );
    if (close ?? false) await SystemNavigator.pop();
  }

  void _onAttendance(BuildContext context, FaceRegisterStates state) {
    final l10n = context.l10n;
    if (state is FaceVerified) {
      showAppDialog(
        context: context,
        tone: AppDialogTone.success,
        title: l10n.attendanceMarkedTitle,
        message: state.message,
        primaryLabel: l10n.actionOk,
      );
    } else if (state is FaceVerifyError) {
      showAppDialog(
        context: context,
        tone: AppDialogTone.error,
        title: l10n.attendanceFailedTitle,
        message: state.error,
        primaryLabel: l10n.actionOk,
      );
    }
  }

  Widget _page(BuildContext context) {
    final home = HomeView(
      onOpenModule: _openModule,
      onOpenAlerts: () => _select(_Tab.alerts),
      onOpenProfile: () => _select(_Tab.profile),
    );
    return switch (_tab) {
      _Tab.alerts => const NotificationView(),
      _Tab.profile => const SettingsView(),
      _Tab.home => Navigator(
        key: _homePages,
        onGenerateRoute: (settings) => shellPageRoute(settings, home),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: BlocProvider<FaceVerificationCubit>(
        create: (_) => sl<FaceVerificationCubit>(),
        child: BlocListener<FaceVerificationCubit, FaceRegisterStates>(
          listener: _onAttendance,
          child: Scaffold(
            // Pages run under the bar, so the check-in key can stand above
            // it over them.
            extendBody: true,
            body: NotificationListener<ModuleBackNotification>(
              onNotification: (_) {
                _closeModule();
                return true;
              },
              child: _page(context),
            ),
            bottomNavigationBar: _ownNavigation.contains(_module)
                ? null
                : _ShellNavigationBar(
                    tab: _tab,
                    onSelect: _select,
                    onOpenTrains: _openTrains,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.tab,
    required this.onSelect,
    required this.onOpenTrains,
  });

  final _Tab tab;
  final ValueChanged<_Tab> onSelect;
  final VoidCallback onOpenTrains;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return AppNavigationBar(
      items: [
        AppNavItem(glyph: AppGlyphs.home, label: l10n.navHome),
        AppNavItem(glyph: AppGlyphs.train, label: l10n.navTrains),
        AppNavItem(glyph: AppGlyphs.bell, label: l10n.navAlerts),
        AppNavItem(glyph: AppGlyphs.profile, label: l10n.navProfile),
      ],
      selectedIndex: switch (tab) {
        _Tab.home => 0,
        _Tab.alerts => 2,
        _Tab.profile => 3,
      },
      onSelected: (index) {
        switch (index) {
          case 1:
            onOpenTrains();
          case 2:
            onSelect(_Tab.alerts);
          case 3:
            onSelect(_Tab.profile);
          default:
            onSelect(_Tab.home);
        }
      },
      action: BlocBuilder<FaceVerificationCubit, FaceRegisterStates>(
        builder: (context, state) => AppActionKey(
          icon: AppGlyphIcon(
            AppGlyphs.scanFace,
            depth: true,
            size: AppSizes.iconLg,
            color: colors.onPrimary,
          ),
          label: l10n.navCheckIn,
          isLoading: state is FaceVerifying,
          ringColor: colors.surface,
          glow: true,
          // The same checks as HRMS before the camera opens: a genuine
          // phone, inside a work area.
          onPressed: () async {
            if (await confirmAtWork(context) && context.mounted) {
              await onCheckInTap(context);
            }
          },
        ),
      ),
    );
  }
}

/// A page of the home tab's own navigator: the home first, and a screen a
/// module opens by name as itself, not as the home again.
@visibleForTesting
Route<Object?> shellPageRoute(RouteSettings settings, Widget home) {
  final name = settings.name;
  final builder = name == null || name == Navigator.defaultRouteName
      ? null
      : AppRouteRegistry.builderFor(name);
  return MaterialPageRoute<Object?>(
    settings: settings,
    builder: builder ?? (_) => home,
  );
}
