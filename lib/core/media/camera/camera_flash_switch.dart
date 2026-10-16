import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The switch for the phone's light: a pill with a bolt, "Flash", and the
/// switch. Off until switched on; the bolt turns gold while it is on.
class CameraFlashSwitch extends StatelessWidget {
  const CameraFlashSwitch({
    super.key,
    required this.on,
    required this.onChanged,
  });

  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!on),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.surface, colors.surfaceEnd],
            ),
            borderRadius: AppRadius.borderPill,
            border: Border.all(color: on ? colors.gold : colors.outline),
            boxShadow: context.elevations.raised,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.smd,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppGlyphIcon(
                  AppGlyphs.zap,
                  size: AppSizes.iconSm,
                  color: on ? colors.gold : colors.textSecondary,
                ),
                AppSpacing.gapXs,
                Text(l10n.cnicFlash, style: text.labelMedium),
                AppSpacing.gapSm,
                AppSwitch(
                  value: on,
                  onChanged: onChanged,
                  label: on ? l10n.cnicTorchOff : l10n.cnicTorchOn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
