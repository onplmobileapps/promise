import 'package:flutter/material.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/hrms/screens/others_attendance_view.dart';

/// The way to mark a team member's attendance, as a card no one can miss:
/// the 3D check-in icon, what it does, and a chevron. Shown only to those
/// with a team.
class MarkTeamCard extends StatelessWidget {
  const MarkTeamCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppLinkCard(
      leading: AppShadowedImage(
        asset: AppAssets.hrmsCheckIn,
        size: AppSizes.linkThumb,
        shadow: context.elevations.iconDrop.scale(
          AppSizes.linkThumb / AppSizes.moduleIcon,
        ),
      ),
      title: l10n.teamMarkTitle,
      subtitle: l10n.teamMarkSubtitle,
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => const OthersAttendanceView()),
      ),
    );
  }
}
