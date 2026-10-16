import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/screens/work_area_map_screen.dart';

/// Checks made before the camera opens for a check-in: the phone is
/// genuine, its location isn't faked, and it is inside one of the
/// employee's work areas. When it isn't inside, the work area map opens so
/// they can find their way in. True when the check-in may go ahead.
///
/// [area] is the screen's own work area, if it has one; otherwise one is
/// started just for this check.
Future<bool> confirmAtWork(BuildContext context, {WorkAreaCubit? area}) async {
  final blocked = (await DeviceIntegrity.check()).blockReason();
  if (!context.mounted) return false;
  if (blocked != null) {
    _refuse(context, context.l10n.gateNotAllowedTitle, blocked);
    return false;
  }
  final own = area == null ? (WorkAreaCubit()..start()) : null;
  final cubit = area ?? own!;
  try {
    // An old fix may be where the employee was, not where they are now.
    final stale = cubit.state.isStale(DateTime.now());
    final state = _settled(cubit.state) && !stale
        ? cubit.state
        : await _settle(context, cubit, refresh: stale);
    if (!context.mounted) return false;
    if (state.spoofed) {
      _refuse(
        context,
        context.l10n.gateFakeLocationTitle,
        const LocationSpoofedException().message,
      );
      return false;
    }
    // No work area assigned, or none could be loaded: the server checks the
    // location itself.
    if (state.offices.isEmpty) return true;
    if (state.presence == Presence.inside) return true;
    return await openWorkAreaMap(context, cubit, fromCheckIn: true);
  } finally {
    await own?.close();
  }
}

/// Opens the work area map over everything; true when the employee asked to
/// mark attendance from inside an area.
Future<bool> openWorkAreaMap(
  BuildContext context,
  WorkAreaCubit area, {
  bool fromCheckIn = false,
}) async {
  final go = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: area,
        child: WorkAreaMapScreen(fromCheckIn: fromCheckIn),
      ),
    ),
  );
  return go == true;
}

/// Enough is known to decide.
bool _settled(WorkAreaState s) =>
    !s.loadingOffices &&
    (s.offices.isEmpty ||
        s.spoofed ||
        s.access == LocationAccess.serviceOff ||
        s.access == LocationAccess.denied ||
        s.presence != Presence.unknown);

/// Waits, with a short "checking" dialog, until [cubit] knows where the
/// employee is, or gives up after a while with what it has.
Future<WorkAreaState> _settle(
  BuildContext context,
  WorkAreaCubit cubit, {
  bool refresh = false,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  unawaited(
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const _CheckingDialog(),
    ).whenComplete(() => open = false),
  );
  WorkAreaState state;
  try {
    if (refresh) {
      await cubit.refreshLocation().timeout(
        CurrentLocationService.fixTimeLimit + const Duration(seconds: 3),
      );
    }
    state = _settled(cubit.state)
        ? cubit.state
        : await cubit.stream
              .firstWhere(_settled)
              .timeout(const Duration(seconds: 12));
  } catch (_) {
    state = cubit.state;
  }
  if (open) navigator.pop();
  return state;
}

void _refuse(BuildContext context, String title, String message) {
  showAppDialog(
    context: context,
    tone: AppDialogTone.error,
    glyph: AppGlyphs.mapPinX,
    title: title,
    message: message,
    primaryLabel: context.l10n.actionOk,
  );
}

/// A short wait while the location is found: a spinner and what is being
/// checked.
class _CheckingDialog extends StatelessWidget {
  const _CheckingDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderSheet,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              const AppLoader(size: AppSizes.loaderSmall),
              AppSpacing.gapLg,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.gateCheckingTitle, style: text.titleSmall),
                    AppSpacing.gapXxs,
                    Text(l10n.gateCheckingMessage, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
