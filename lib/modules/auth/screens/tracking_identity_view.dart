import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/cnic/cnic_camera.dart';
import 'package:railway_hrms/core/media/cnic/cnic_capture_card.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/auth/widgets/auth_scaffold.dart';

/// Signs a traveller in to train tracking with their mobile number and
/// CNIC: null when it went through, or what went wrong, to say.
typedef TrackingSignIn =
    Future<String?> Function(String phoneNumber, CnicScan cnic);

/// Train tracking sign-in has no API yet, so every traveller with a CNIC
/// goes through. Once it is ready, it is called here with the number and
/// the CNIC's photo.
Future<String?> signInToTracking(String phoneNumber, CnicScan cnic) async =>
    null;

/// The second step of train tracking sign-in: the mobile number typed on
/// the first, shown fixed, and the traveller's CNIC, scanned with
/// on-device AI. Once the CNIC is in, Continue signs them in and opens live
/// train tracking.
class TrackingIdentityView extends StatefulWidget {
  const TrackingIdentityView({
    super.key,
    required this.phoneNumber,
    this.signIn = signInToTracking,
    this.camera,
  });

  /// The mobile number as it was typed, such as 03001234567.
  final String phoneNumber;
  final TrackingSignIn signIn;

  /// The CNIC camera; a stand-in in tests.
  final CnicCameraBuilder? camera;

  @override
  State<TrackingIdentityView> createState() => _TrackingIdentityViewState();
}

class _TrackingIdentityViewState extends State<TrackingIdentityView> {
  late final _phone = TextEditingController(text: widget.phoneNumber);
  CnicScan? _scan;
  bool _signingIn = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final scan = _scan;
    if (scan == null || _signingIn) return;
    setState(() => _signingIn = true);
    final problem = await widget.signIn(widget.phoneNumber, scan);
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (problem != null) {
      await showAppMessage(
        context,
        problem,
        tone: AppDialogTone.error,
        title: context.l10n.loginFailedTitle,
      );
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutes.liveTracking);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [l10n.identityStepMobile, l10n.identityStepCnic];
    final busy = _signingIn;
    return AuthScaffold(
      builder: (context, layout) => ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(
              title: l10n.identityTitle,
              subtitle: l10n.identitySubtitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            AppSpacing.gapLg,
            AppProgressSteps(
              steps: steps,
              current: 1,
              semanticLabel: l10n.cnicStepOf(2, steps.length, steps[1]),
            ),
            AppSpacing.gapXl,
            AppCard.glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _phone,
                    label: l10n.mobileNumberLabel,
                    glyph: AppGlyphs.smartphone,
                    enabled: false,
                    suffix: _ChangeKey(
                      label: l10n.identityChangeNumber,
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  AppSpacing.gapLg,
                  CnicCaptureCard(
                    scan: _scan,
                    onScanned: (scan) => setState(() => _scan = scan),
                    camera: widget.camera,
                  ),
                  AppSpacing.gapXl,
                  AppButton(
                    label: l10n.actionContinue,
                    loadingLabel: l10n.loginInProgress,
                    trailingGlyph: AppGlyphs.arrowRight,
                    isLoading: _signingIn,
                    onPressed: _scan == null || busy ? null : _continue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small jade pill with a pencil, at the end of the fixed number, that
/// goes back to change it. It sinks a little while held.
class _ChangeKey extends StatelessWidget {
  const _ChangeKey({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
      child: AppPressable(
        label: label,
        onPressed: onPressed,
        builder: (context, pressed, focused) => AnimatedScale(
          scale: pressed ? 0.94 : 1,
          duration: AppMotion.short,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? colors.primaryContainer : colors.surface,
              borderRadius: AppRadius.borderPill,
              border: Border.all(
                color: focused ? colors.focus : colors.primaryShade,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: pressed ? null : context.elevations.raised,
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
                    AppGlyphs.fileEdit,
                    size: AppSizes.iconXs,
                    color: colors.onPrimaryContainer,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    label,
                    style: text.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: AppFonts.semiBold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
