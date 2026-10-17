import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/profile/user_avatar.dart';

/// A part of the app, as a card on the home screen.
@immutable
class HomeModule {
  const HomeModule({
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.fullScreen = false,
    this.comingSoon = false,
  });

  final String route;

  /// The module's 3D icon, an asset path.
  final String icon;
  final String title;
  final String subtitle;

  /// Opens over the whole app, with its own navigation, rather than inside
  /// the home tab.
  final bool fullScreen;

  /// Not open yet: tapping it says so instead.
  final bool comingSoon;

  /// The app's modules, in the order the home screen shows them.
  static List<HomeModule> all(AppLocalizations l10n) => [
    HomeModule(
      route: AppRoutes.hrms,
      icon: AppAssets.moduleHrms,
      title: l10n.moduleHrmsTitle,
      subtitle: l10n.moduleHrmsSubtitle,
    ),
    HomeModule(
      route: AppRoutes.liveTracking,
      icon: AppAssets.moduleTracking,
      title: l10n.moduleTrackingTitle,
      subtitle: l10n.moduleTrackingSubtitle,
      fullScreen: true,
    ),
    HomeModule(
      route: AppRoutes.inspection,
      icon: AppAssets.moduleInspection,
      title: l10n.moduleInspectionTitle,
      subtitle: l10n.moduleInspectionSubtitle,
    ),
    HomeModule(
      route: AppRoutes.prams,
      icon: AppAssets.modulePrams,
      title: l10n.modulePramsTitle,
      subtitle: l10n.modulePramsSubtitle,
    ),
  ];
}

/// The home tab: the brand, alerts and profile up top, a greeting with the
/// day's date, and the modules. It only shows modules; nothing moves.
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.onOpenModule,
    required this.onOpenAlerts,
    required this.onOpenProfile,
    this.user,
    this.now,
  });

  /// Opens a module inside the home tab.
  final ValueChanged<String> onOpenModule;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenProfile;

  /// Who to greet; read from storage by default.
  final SignedInUser? user;

  /// The time to greet for; the clock's by default.
  final DateTime Function()? now;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late SignedInUser _user = widget.user ?? SignedInUser.nobody;

  @override
  void initState() {
    super.initState();
    if (widget.user == null) _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SignedInUser.load();
    if (mounted) setState(() => _user = user);
  }

  void _open(BuildContext context, HomeModule module) {
    final l10n = context.l10n;
    if (module.comingSoon) {
      showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.featureInDevelopmentTitle,
        message: l10n.featureInDevelopmentMessage,
        primaryLabel: l10n.actionGotIt,
      );
    } else if (module.fullScreen) {
      Navigator.of(context, rootNavigator: true).pushNamed(module.route);
    } else {
      widget.onOpenModule(module.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final modules = HomeModule.all(l10n);
    return AppBackdrop(
      washHeight: AppSizes.homeWash,
      patternFade: AppSizes.homePattern,
      child: SafeArea(
        bottom: false,
        child: ResponsiveBuilder(
          builder: (context, layout) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              layout.isCompact ? AppSpacing.gutterHome : layout.gutter,
              AppSpacing.sm,
              layout.isCompact ? AppSpacing.gutterHome : layout.gutter,
              // Clear of the navigation bar the body runs under.
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
                      _HomeHeader(
                        user: _user,
                        onOpenAlerts: widget.onOpenAlerts,
                        onOpenProfile: widget.onOpenProfile,
                      ),
                      const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
                      _Greeting(
                        user: _user,
                        now: (widget.now ?? DateTime.now)(),
                      ),
                      const SizedBox(height: AppSpacing.xxl + AppSpacing.xxs),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.homeModulesTitle,
                          style: text.titleLarge,
                        ),
                      ),
                      AppSpacing.gapMd,
                      AppGrid(
                        columns: layout.sizeClass == WindowSizeClass.expanded
                            ? 4
                            : 2,
                        children: [
                          for (final module in modules)
                            AppModuleCard(
                              icon: AppShadowedImage(
                                asset: module.icon,
                                size: AppSizes.moduleIcon,
                                shadow: context.elevations.iconDrop,
                              ),
                              title: module.title,
                              titleSpan: _italicE(module.title),
                              subtitle: module.subtitle,
                              onTap: () => _open(context, module),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "e Inspection" with its "e" in italics, as the brand writes it.
InlineSpan? _italicE(String title) => title.startsWith('e ')
    ? TextSpan(
        children: [
          const TextSpan(
            text: 'e',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          TextSpan(text: title.substring(1)),
        ],
      )
    : null;

/// The brand on the left; alerts and the profile on the right.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.user,
    required this.onOpenAlerts,
    required this.onOpenProfile,
  });

  final SignedInUser user;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final text = context.textTheme;
    return Row(
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.outline),
              boxShadow: context.elevations.raised,
            ),
            child: const SizedBox.square(
              dimension: AppSizes.homeLogo,
              child: Center(child: AppEmblem(width: AppSizes.homeLogoEmblem)),
            ),
          ),
        ),
        AppSpacing.gapSmd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  letterSpacing: AppFonts.brandLetterSpacing,
                ),
              ),
            ],
          ),
        ),
        AppTileButton(
          icon: const AppGlyphIcon(AppGlyphs.bell, size: AppSizes.iconLg),
          tooltip: l10n.navAlerts,
          onPressed: onOpenAlerts,
        ),
        UserAvatar(
          name: user.name.isEmpty ? l10n.appName : user.name,
          employeeId: user.employeeId,
          semanticLabel: l10n.homeProfile,
          onTap: onOpenProfile,
        ),
      ],
    );
  }
}

/// Today's date, a greeting for the time of day, and the user's role.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.now});

  final SignedInUser user;
  final DateTime now;

  /// Morning before noon, afternoon until five, evening after.
  static String greetingFor(AppLocalizations l10n, DateTime now) =>
      now.hour < 12
      ? l10n.greetingMorning
      : now.hour < 17
      ? l10n.greetingAfternoon
      : l10n.greetingEvening;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final greeting = greetingFor(l10n, now);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.MMMMEEEEd(locale).format(now),
          style: text.labelMedium?.copyWith(
            color: colors.textTertiary,
            fontWeight: AppFonts.semiBold,
          ),
        ),
        AppSpacing.gapXxs,
        Semantics(
          header: true,
          child: Text(
            user.firstName.isEmpty
                ? greeting
                : l10n.greetingWithName(greeting, user.firstName),
            style: text.headlineLarge,
          ),
        ),
        if (user.role.isNotEmpty) ...[
          AppSpacing.gapSm,
          _RoleChip(role: user.role),
        ],
        if (user.employeeId.isNotEmpty || user.sapId.isNotEmpty) ...[
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (user.employeeId.isNotEmpty)
                AppTag('Emp ID: ${user.employeeId}', tone: AppTone.brand),
              if (user.sapId.isNotEmpty)
                AppTag('SAP ID: ${user.sapId}', tone: AppTone.neutral),
            ],
          ),
        ],
      ],
    );
  }
}

/// The user's designation on a soft jade-to-gold chip with a briefcase.
class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.goldContainer],
        ),
        borderRadius: AppRadius.borderPill,
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGlyphIcon(
              AppGlyphs.briefcase,
              size: AppSizes.iconXs,
              color: colors.iconAccent,
            ),
            AppSpacing.gapSm,
            Flexible(
              child: Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: AppFonts.semiBold,
                  letterSpacing: AppFonts.tagLetterSpacing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
