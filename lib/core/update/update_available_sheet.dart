import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// Asks the user to update to the store's newer version. It can't be
/// dismissed: the only way on is the store.
Future<void> showUpdateAvailableSheet({
  required BuildContext context,
  required String? version,
  required VoidCallback onUpdate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
    builder: (_) => UpdateAvailableSheet(version: version, onUpdate: onUpdate),
  );
}

class UpdateAvailableSheet extends StatelessWidget {
  const UpdateAvailableSheet({
    super.key,
    required this.version,
    required this.onUpdate,
  });

  final String? version;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final text = context.textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.infoContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: AppSizes.dialogBadge,
                child: AppGlyphIcon(
                  AppGlyphs.download,
                  size: AppSizes.iconXl,
                  color: colors.onInfoContainer,
                ),
              ),
            ),
          ),
          AppSpacing.gapXl,
          Text(
            l10n.updateAvailableTitle,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          if (version != null) ...[
            AppSpacing.gapXs,
            Text(
              l10n.updateAvailableVersion(version!),
              textAlign: TextAlign.center,
              style: text.labelMedium,
            ),
          ],
          AppSpacing.gapSm,
          Text(
            l10n.updateAvailableMessage,
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          AppSpacing.gapXxl,
          AppButton(label: l10n.updateNow, onPressed: onUpdate),
        ],
      ),
    );
  }
}
