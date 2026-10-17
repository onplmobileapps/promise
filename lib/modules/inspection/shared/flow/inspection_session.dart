import 'package:flutter/material.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';

/// An inspection under way: who started it, with the face check they
/// started it with. Everything below it is filled in by that person, and
/// its report goes out signed with the check.
class InspectionSession extends InheritedWidget {
  const InspectionSession({
    super.key,
    required this.start,
    required super.child,
  });

  /// The face check the inspection was started with.
  final InspectionIdentity start;

  /// The inspection [context] is part of, if one has been started.
  static InspectionSession? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<InspectionSession>();

  @override
  bool updateShouldNotify(InspectionSession old) => old.start != start;
}

/// Asks for the inspector's face before an inspection's form opens, and
/// opens it, under an [InspectionSession], once the face is verified.
/// Within an inspection already started (a form opened from another) it
/// opens the form at once.
class InspectionStartGate extends StatefulWidget {
  const InspectionStartGate({
    super.key,
    required this.title,
    required this.child,
    this.verifier,
  });

  /// The kind of inspection, as the form calls itself.
  final String title;
  final Widget child;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  State<InspectionStartGate> createState() => _InspectionStartGateState();
}

class _InspectionStartGateState extends State<InspectionStartGate> {
  InspectionIdentity? _start;
  bool _busy = false;

  InspectionFaceVerifier get _verifier =>
      widget.verifier ?? sl<InspectionFaceVerifier>();

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _verifier.verify(context, InspectionMoment.start);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case FaceCheckPassed(:final identity):
        setState(() => _start = identity);
        if (!identity.matched) {
          await showAppMessage(context, context.l10n.inspFaceKeptOffline);
        }
      case FaceCheckFailed(:final message):
        await showAppDialog(
          context: context,
          tone: AppDialogTone.error,
          title: context.l10n.inspVerifyFailedTitle,
          message: message,
          primaryLabel: context.l10n.actionOk,
        );
      case FaceCheckCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (InspectionSession.maybeOf(context) != null) return widget.child;
    final start = _start;
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.enter,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: start == null
          ? _GatePage(
              key: const ValueKey('gate'),
              title: widget.title,
              busy: _busy,
              onVerify: _verify,
            )
          : InspectionSession(
              key: const ValueKey('form'),
              start: start,
              child: widget.child,
            ),
    );
  }
}

class _GatePage extends StatelessWidget {
  const _GatePage({
    super.key,
    required this.title,
    required this.busy,
    required this.onVerify,
  });

  final String title;
  final bool busy;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final media = MediaQuery.sizeOf(context);
    Widget check(AppGlyph glyph, String label) => AppListRow(
      leading: AppIconTile(
        size: AppSizes.rowTile,
        child: AppGlyphIcon(
          glyph,
          size: AppSizes.iconMd,
          color: colors.iconAccent,
          depth: true,
        ),
      ),
      title: label,
    );
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: title,
            subtitle: l10n.moduleInspectionTitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapXl,
          Center(
            child: AppMedallion(
              diameter: AppMedallion.diameterFor(media.shortestSide),
              child: AppShadowedImage(
                asset: AppAssets.moduleInspection,
                size: AppSizes.moduleIcon,
                shadow: context.elevations.iconDrop,
              ),
            ),
          ),
          AppSpacing.gapXl,
          Text(
            l10n.inspGateTitle,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          AppSpacing.gapSm,
          Text(
            l10n.inspGateMessage,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          AppSpacing.gapXl,
          AppListGroup(
            children: [
              check(AppGlyphs.scanFace, l10n.inspGateCheckLive),
              check(AppGlyphs.badgeCheck, l10n.inspGateCheckMatch),
              check(AppGlyphs.mapPin, l10n.inspGateCheckStamp),
            ],
          ),
          AppSpacing.gapXl,
          AppButton(
            label: l10n.inspGateStart,
            leadingGlyph: AppGlyphs.scanFace,
            isLoading: busy,
            onPressed: onVerify,
          ),
        ],
      ),
    );
  }
}

/// Opens [page] as part of the inspection [context] belongs to, so a form
/// it opens doesn't ask for the face again; with [replace], in place of
/// the page [context] is on.
Future<T?> pushInspectionPage<T extends Object?>(
  BuildContext context,
  WidgetBuilder page, {
  bool replace = false,
}) {
  final session = InspectionSession.maybeOf(context);
  final route = MaterialPageRoute<T>(
    builder: (context) => session == null
        ? page(context)
        : InspectionSession(start: session.start, child: page(context)),
  );
  final navigator = Navigator.of(context);
  return replace ? navigator.pushReplacement(route) : navigator.push(route);
}
