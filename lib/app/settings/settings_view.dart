import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/app/settings/settings_cubit.dart';
import 'package:railway_hrms/app/settings/settings_states.dart';
import 'package:railway_hrms/app/settings/text_display_view.dart';
import 'package:railway_hrms/app/settings/text_look_card.dart';
import 'package:railway_hrms/core/config/app_flags.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/profile/profile_photo_sheet.dart';
import 'package:railway_hrms/core/profile/user_avatar.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:railway_hrms/core/update/app_info.dart';
import 'package:railway_hrms/core/utils/field_rules.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The profile: who is signed in, their account and preferences, and the
/// way out.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, this.user});

  /// Who is signed in; read from storage by default.
  final SignedInUser? user;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SignedInUser _user = widget.user ?? SignedInUser.nobody;
  final Future<AppInfo?> _appInfo = AppInfo.load();

  @override
  void initState() {
    super.initState();
    if (widget.user == null) _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SignedInUser.load();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _toggleBiometrics(BuildContext context, bool enabled) async {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final done = await cubit.toggleBiometrics(
      enabled,
      reason: l10n.biometricEnableReason,
    );
    if (done || !context.mounted) return;
    await showAppDialog(
      context: context,
      tone: AppDialogTone.error,
      glyph: AppGlyphs.fingerprint,
      title: l10n.biometricEnableFailedTitle,
      message: l10n.biometricEnableFailedMessage,
      primaryLabel: l10n.actionOk,
    );
  }

  Future<void> _showChangePasswordSheet(BuildContext context) {
    final l10n = context.l10n;
    return showAppSheet(
      context: context,
      title: 'Change Password',
      subtitle: 'Enter your current password and a new password.',
      closeLabel: l10n.actionCancel,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _showWhatsNewSheet(BuildContext context) async {
    final l10n = context.l10n;

    // Show immediate custom AppLoader so user gets instant feedback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Material(type: MaterialType.transparency, child: AppLoader.page()),
    );

    final app = await _appInfo;

    if (app == null) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.profileAppVersion,
        message: 'App version information is currently unavailable.',
        primaryLabel: l10n.actionOk,
      );
      return;
    }

    String? releaseNotes;
    String? storeVersion;
    bool updateAvailable = false;
    String message = '';

    try {
      if (Platform.isIOS) {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 8);
        final request = await client.getUrl(
          Uri.https('itunes.apple.com', '/lookup', {
            'bundleId': app.id,
            'country': 'pk',
          }),
        );
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        if (response.statusCode == HttpStatus.ok) {
          final body = await response.transform(utf8.decoder).join();
          final results = (jsonDecode(body) as Map)['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final first = results.first as Map;
            releaseNotes = first['releaseNotes']?.toString();
            storeVersion = first['version']?.toString();
            if (storeVersion != null && app.isOlderThan(storeVersion)) {
              updateAvailable = true;
            }
          }
        }
        client.close(force: true);
      } else if (Platform.isAndroid) {
        try {
          final info = await InAppUpdate.checkForUpdate();
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            updateAvailable = true;
            storeVersion = '${info.availableVersionCode}';
          }
        } catch (_) {}

        releaseNotes = await _fetchPlayStoreWhatsNew(app.id);
      }
    } catch (_) {
      // Fallback
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

    if (releaseNotes != null && releaseNotes.trim().isNotEmpty) {
      message = releaseNotes;
    } else if (updateAvailable) {
      message =
          'A new update (Version $storeVersion) is available on Google Play.';
    } else {
      message = 'Your app is up to date.';
    }

    final subtitleStr =
        'Version ${storeVersion ?? app.version} (Build ${app.build})';

    await showAppSheet<bool>(
      context: context,
      title: updateAvailable ? 'Update Available' : "What's New",
      closeLabel: l10n.actionCancel,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              updateAvailable ? 'Update Available' : "What's New",
              style: context.textTheme.headlineSmall,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            subtitleStr,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: AppFonts.medium,
            ),
          ),
        ],
      ),
      builder: (sheetCtx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                height: 1.5,
              ),
            ),
            AppSpacing.gapXl,
            AppButton(
              label: updateAvailable ? 'Update' : l10n.actionOk,
              onPressed: () {
                Navigator.of(sheetCtx).pop(true);
              },
            ),
            if (updateAvailable) ...[
              AppSpacing.gapMd,
              AppButton(
                label: l10n.actionCancel,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(sheetCtx).pop(false);
                },
              ),
            ],
          ],
        ),
      ),
    ).then((result) {
      if (updateAvailable && result == true) {
        AppInfo.openStore();
      }
    });
  }

  Future<String?> _fetchPlayStoreWhatsNew(String packageName) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(
        Uri.https('play.google.com', '/store/apps/details', {
          'id': packageName,
          'hl': 'en',
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode == HttpStatus.ok) {
        final html = await response.transform(utf8.decoder).join();
        final match = RegExp(
          r'''What's new.*?<div[^>]*>(.*?)</div>''',
          dotAll: true,
          caseSensitive: false,
        ).firstMatch(html);
        if (match != null) {
          final cleanText = match
              .group(1)
              ?.replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (cleanText != null && cleanText.isNotEmpty) {
            return cleanText;
          }
        }
      }
    } catch (_) {
    } finally {
      client.close(force: true);
    }
    return null;
  }

  Future<void> _confirmLogout() async {
    final l10n = context.l10n;
    final leave = await showAppDialog(
      context: context,
      tone: AppDialogTone.confirm,
      glyph: AppGlyphs.logOut,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      primaryLabel: l10n.logoutButton,
      secondaryLabel: l10n.actionCancel,
    );
    if (!(leave ?? false)) return;
    // The session goes before the screens do, so nothing stale is left.
    await StorageService.clearAuthData(navigate: false);
    if (!mounted) return;
    await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    Widget rowGlyph(AppGlyph glyph) =>
        AppGlyphIcon(glyph, size: AppSizes.glyphRow, color: colors.iconAccent);
    return BlocProvider(
      create: (_) =>
          SettingsCubit(sl<BiometricAuthenticator>())..loadSettings(),
      child: Scaffold(
        body: AppBackdrop.blobs(
          blobIntensity: AppSizes.blobIntensityStrong,
          child: SafeArea(
            bottom: false,
            child: ResponsiveBuilder(
              builder: (context, layout) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  layout.gutter,
                  AppSpacing.md,
                  layout.gutter,
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
                          _ProfileCard(user: _user),
                          AppSpacing.gapXl,
                          AppSectionLabel(l10n.profileSectionAppearance),
                          AppSpacing.gapSm,
                          const _AppearancePicker(),
                          AppSpacing.gapXl,
                          AppSpacing.gapSm,
                          ValueListenableBuilder<TextLook>(
                            valueListenable: sl<TextLookController>(),
                            builder: (context, look, _) => AppListGroup(
                              children: [
                                AppListRow(
                                  leading: rowGlyph(AppGlyphs.textSize),
                                  title: l10n.profileTextDisplay,
                                  subtitle: l10n.profileTextDisplayDetail(
                                    switch (look.display) {
                                      DisplaySize.standard =>
                                        l10n.displaySizeStandard,
                                      DisplaySize.large =>
                                        l10n.displaySizeLarge,
                                    },
                                    TextLookCard.textSizeNames(l10n)[look.size],
                                  ),
                                  showChevron: true,
                                  onTap: () => TextDisplayView.open(context),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapXl,
                          AppSectionLabel(l10n.profileSectionAccount),
                          AppSpacing.gapSm,
                          BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, state) {
                              final loaded = state is SettingsLoaded
                                  ? state
                                  : null;
                              return AppListGroup(
                                children: [
                                  AppListRow(
                                    leading: rowGlyph(AppGlyphs.fingerprint),
                                    title: l10n.profileBiometric,
                                    trailing: AppSwitch(
                                      value:
                                          loaded?.isBiometricEnabled ?? false,
                                      onChanged:
                                          loaded?.canCheckBiometrics ?? false
                                          ? (on) =>
                                                _toggleBiometrics(context, on)
                                          : null,
                                    ),
                                  ),
                                  AppListRow(
                                    leading: rowGlyph(AppGlyphs.lock),
                                    title: l10n.profileSecurity,
                                    showChevron: true,
                                    onTap: () =>
                                        _showChangePasswordSheet(context),
                                  ),
                                ],
                              );
                            },
                          ),
                          AppSpacing.gapXl,
                          AppSectionLabel(l10n.profileSectionPreferences),
                          AppSpacing.gapSm,
                          AppListGroup(
                            children: [
                              AppListRow(
                                leading: rowGlyph(AppGlyphs.info),
                                title: l10n.profileAppVersion,
                                showChevron: true,
                                onTap: () => _showWhatsNewSheet(context),
                                trailing: FutureBuilder<AppInfo?>(
                                  future: _appInfo,
                                  builder: (context, info) => Text(
                                    switch (info.data) {
                                      final app? =>
                                        '${app.version}+${app.build}',
                                      null => '',
                                    },
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(color: colors.textTertiary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Never in a release.
                          if (AppFlags.testingTools) ...[
                            AppSpacing.gapXl,
                            const AppSectionLabel('Testing'),
                            AppSpacing.gapSm,
                            const _InspectionChecksSwitch(),
                          ],
                          AppSpacing.gapXl,
                          _LogoutCard(onTap: _confirmLogout),
                        ],
                      ),
                    ),
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

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final repository = sl<AuthRepository>();
    final result = await repository.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final l10n = context.l10n;

    result.fold(
      (failure) {
        showAppDialog(
          context: context,
          tone: AppDialogTone.error,
          title: l10n.messageErrorTitle,
          message: failure.message,
          primaryLabel: l10n.actionOk,
        );
      },
      (response) {
        String msg = 'Password updated successfully.';
        final data = response.data;
        if (data is Map) {
          msg =
              data['message']?.toString() ??
              data['msg']?.toString() ??
              data['detail']?.toString() ??
              data['Success']?.toString() ??
              msg;
        }

        Navigator.of(context).pop();

        showAppDialog(
          context: context,
          tone: AppDialogTone.success,
          title: l10n.messageSuccessTitle,
          message: msg,
          primaryLabel: l10n.actionOk,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _oldPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              glyph: AppGlyphs.lock,
              obscureText: _obscureOld,
              textInputAction: TextInputAction.next,
              inputFormatters: FieldInput.noSpaces(maxLength: 30),
              validator: FieldRules.all([
                FieldRules.required('Current password is required'),
              ]),
              suffix: AppVisibilityToggle(
                visible: !_obscureOld,
                showLabel: l10n.passwordShow,
                hideLabel: l10n.passwordHide,
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
              ),
            ),
            AppSpacing.gapMd,
            AppTextField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: 'Enter new password',
              glyph: AppGlyphs.lock,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              inputFormatters: FieldInput.noSpaces(maxLength: 30),
              validator: FieldRules.all([
                FieldRules.required('New password is required'),
                FieldRules.minLength(
                  6,
                  'Password must be at least 6 characters',
                ),
              ]),
              suffix: AppVisibilityToggle(
                visible: !_obscureNew,
                showLabel: l10n.passwordShow,
                hideLabel: l10n.passwordHide,
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            AppSpacing.gapMd,
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Re-enter new password',
              glyph: AppGlyphs.lock,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              inputFormatters: FieldInput.noSpaces(maxLength: 30),
              validator: FieldRules.all([
                FieldRules.required('Please confirm your new password'),
                FieldRules.sameAs(
                  () => _newPasswordController.text,
                  'Passwords do not match',
                ),
              ]),
              suffix: AppVisibilityToggle(
                visible: !_obscureConfirm,
                showLabel: l10n.passwordShow,
                hideLabel: l10n.passwordHide,
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            AppSpacing.gapXl,
            AppButton(
              label: 'Update Password',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Who is signed in, as the page's banner: "Profile" over their initials
/// on a jade key, their name and job, and their employee number, on a soft
/// jade wash with the pattern.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final SignedInUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surface],
        ),
        borderRadius: AppRadius.borderXxl,
        border: Border.all(color: colors.outline),
        boxShadow: context.elevations.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderXxl,
        child: CustomPaint(
          painter: KhatamPatternPainter(
            color: colors.pattern,
            fadeHeight: AppSizes.heroPattern,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.profileTitle.toUpperCase(),
                    style: text.labelSmall,
                  ),
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    UserAvatar(
                      name: user.name.isEmpty ? l10n.appName : user.name,
                      employeeId: user.employeeId,
                      style: UserAvatarStyle.key,
                      size: AppSizes.profileHeroAvatar,
                      semanticLabel: l10n.profilePhotoChange,
                      badge: user.employeeId.isEmpty ? null : AppGlyphs.camera,
                      onTap: user.employeeId.isEmpty
                          ? null
                          : () => showProfilePhotoSheet(
                              context,
                              name: user.name.isEmpty
                                  ? l10n.appName
                                  : user.name,
                            ),
                    ),
                    AppSpacing.gapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.name.isNotEmpty)
                            Text(user.name, style: text.headlineSmall),
                          if (user.role.isNotEmpty)
                            Text(
                              user.role,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: AppFonts.medium,
                              ),
                            ),
                          if (user.employeeId.isNotEmpty ||
                              user.sapId.isNotEmpty) ...[
                            AppSpacing.gapSm,
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                if (user.employeeId.isNotEmpty)
                                  AppTag('Emp ID: ${user.employeeId}'),
                                if (user.sapId.isNotEmpty)
                                  AppTag('SAP ID: ${user.sapId}'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The way out, on a card of its own: a coral sphere with the door, what
/// it does, and what signing in again takes.
class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final sphere = context.spheres.coral;
    return Semantics(
      button: true,
      label: l10n.logoutButton,
      excludeSemantics: true,
      child: AppInkSurface(
        onTap: onTap,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceRaised, colors.dangerContainer],
          ),
          borderRadius: AppRadius.borderLinkCard,
          border: Border.all(color: colors.dangerHighlight),
          boxShadow: context.elevations.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.44),
                    colors: [sphere.highlight, sphere.body, sphere.shade],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: context.elevations.sphere.scaled(0.5),
                ),
                child: SizedBox.square(
                  dimension: AppSizes.avatarMedium,
                  child: Center(
                    child: AppGlyphIcon(
                      AppGlyphs.logOut,
                      size: AppSizes.iconMd,
                      color: sphere.mark,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.logoutButton,
                      style: text.labelLarge?.copyWith(
                        color: colors.onDangerContainer,
                      ),
                    ),
                    Text(l10n.logoutSubtitle, style: text.bodySmall),
                  ],
                ),
              ),
              AppGlyphIcon(
                AppGlyphs.chevronRight,
                size: AppSizes.iconSm,
                color: colors.onDangerContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light, dark, or the phone's own setting, each shown as a tiny screen in
/// that look. The pick applies at once and is remembered.
class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appearance = sl<AppearanceController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appearance,
      builder: (context, picked, _) => Semantics(
        label: l10n.profileSectionAppearance,
        container: true,
        child: AppGrid(
          columns: 3,
          spacing: AppSpacing.sm,
          children: [
            for (final (mode, label) in [
              (ThemeMode.light, l10n.appearanceLight),
              (ThemeMode.dark, l10n.appearanceDark),
              (ThemeMode.system, l10n.appearanceSystem),
            ])
              _AppearanceOption(
                mode: mode,
                label: label,
                selected: picked == mode,
                onTap: () => appearance.pick(mode),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppInkSurface(
        onTap: onTap,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
          ),
          borderRadius: AppRadius.borderTile,
          border: Border.all(
            color: selected ? colors.primaryShade : colors.outline,
            width: 1.5,
          ),
          boxShadow: context.elevations.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.smd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: AppSizes.appearanceSwatch,
                child: switch (mode) {
                  ThemeMode.light => const _Swatch(AppColors.light),
                  ThemeMode.dark => const _Swatch(AppColors.dark),
                  ThemeMode.system => const _SplitSwatch(),
                },
              ),
              AppSpacing.gapXs,
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: AppFonts.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny screen in [palette]: a bar of the brand over a card.
class _Swatch extends StatelessWidget {
  const _Swatch(this.palette);

  final AppColors palette;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: palette.background,
      borderRadius: AppRadius.borderSm,
      border: Border.all(color: palette.outline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xs + AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.primaryShade,
              borderRadius: AppRadius.borderPill,
            ),
            child: const SizedBox(
              width: AppSizes.appearanceBarWidth,
              height: AppSizes.appearanceBarHeight,
            ),
          ),
          AppSpacing.gapXs,
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.borderXs,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Half light and half dark: whichever the phone is set to.
class _SplitSwatch extends StatelessWidget {
  const _SplitSwatch();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppRadius.borderSm,
      border: Border.all(color: context.colors.outline),
    ),
    child: ClipRRect(
      borderRadius: AppRadius.borderSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: AppColors.light.background)),
          Expanded(child: ColoredBox(color: AppColors.dark.background)),
        ],
      ),
    ),
  );
}

/// Turns eInspection's face and location check off for testing away from
/// the office, and on again. Shown outside a release only.
class _InspectionChecksSwitch extends StatefulWidget {
  const _InspectionChecksSwitch();

  @override
  State<_InspectionChecksSwitch> createState() =>
      _InspectionChecksSwitchState();
}

class _InspectionChecksSwitchState extends State<_InspectionChecksSwitch> {
  bool _on = AppFlags.inspectionFaceCheck;

  Future<void> _set(bool on) async {
    setState(() => _on = on);
    await AppFlags.setInspectionChecks(
      on,
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListGroup(
      children: [
        AppListRow(
          leading: AppGlyphIcon(
            AppGlyphs.scanFace,
            size: AppSizes.iconMd,
            color: context.colors.iconAccent,
          ),
          title: 'eInspection face check',
          subtitle: _on
              ? 'On: face and office location are checked'
              : 'Off: inspections open without face or location',
          trailing: AppSwitch(value: _on, onChanged: _set),
        ),
      ],
    );
  }
}
