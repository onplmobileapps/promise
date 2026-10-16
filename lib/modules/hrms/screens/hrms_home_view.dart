import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/profile/user_avatar.dart';
import 'package:railway_hrms/core/utils/module_notifications.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_helpers.dart';
import 'package:railway_hrms/modules/hrms/widgets/attendance_gate.dart';
import 'package:railway_hrms/modules/hrms/widgets/leave_cards.dart';
import 'package:railway_hrms/modules/hrms/widgets/mark_team_card.dart';
import 'package:railway_hrms/modules/hrms/widgets/shift_card.dart';
import 'package:railway_hrms/modules/hrms/widgets/work_area_card.dart';

/// The HRMS home: today's shift with check-in, the work area, the way to
/// leave and attendance, the leave balance and the employee's requests.
class HrmsHomeView extends StatelessWidget {
  const HrmsHomeView({
    super.key,
    required this.onOpenAttendance,
    required this.onOpenLeave,
    this.onApplyFor,
    this.now,
  });

  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenLeave;

  /// Opens the leave form on the given type of leave.
  final ValueChanged<int>? onApplyFor;

  /// The clock; the device's by default.
  final DateTime Function()? now;

  Future<void> _refresh(BuildContext context) => Future.wait([
    context.read<AttendanceCubit>().refresh(),
    context.read<LeaveCubit>().refresh(),
    context.read<LeaveCubit>().fetchHistory(),
    context.read<WorkAreaCubit>().refresh(),
  ]);

  /// The map shows the way in; from inside it, the employee can go on to
  /// mark attendance.
  Future<void> _openMap(BuildContext context) async {
    final area = context.read<WorkAreaCubit>();
    if (!await openWorkAreaMap(context, area) || !context.mounted) return;
    await onCheckInTap(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = (now ?? DateTime.now)();
    final drop = context.elevations.iconDrop.scale(
      AppSizes.actionIcon / AppSizes.moduleIcon,
    );
    return AppScrollPage(
      tightGutter: true,
      onRefresh: () => _refresh(context),
      children: [
        AppHeaderBar(
          title: l10n.hrmsTitle,
          subtitle: l10n.hrmsSubtitle,
          backTooltip: l10n.hrmsBackHome,
          onBack: () => ModuleBackNotification().dispatch(context),
          actions: [
            AppTileButton(
              icon: const AppGlyphIcon(AppGlyphs.history),
              tooltip: l10n.hrmsHistoryTooltip,
              onPressed: onOpenAttendance,
            ),
          ],
        ),
        AppSpacing.gapLg,
        const _Who(),
        AppSpacing.gapMd,
        ShiftCard(now: now),
        AppSpacing.gapMd,
        // Those with a team mark its attendance from here too.
        BlocBuilder<TeamCubit, TeamState>(
          buildWhen: (a, b) => a.hasTeam != b.hasTeam,
          builder: (context, team) => AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.enter,
            child: team.hasTeam
                ? const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: MarkTeamCard(),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
        WorkAreaCard(onOpenMap: () => _openMap(context)),
        AppSpacing.gapMd,
        AppGrid(
          columns: 2,
          children: [
            BlocBuilder<LeaveCubit, LeaveState>(
              buildWhen: (a, b) => a.records != b.records,
              builder: (context, state) => AppActionCard(
                icon: AppShadowedImage(
                  asset: AppAssets.hrmsLeave,
                  size: AppSizes.actionIcon,
                  shadow: drop,
                ),
                title: l10n.hrmsApplyLeave,
                subtitle: l10n.hrmsLeaveDaysLeft(
                  state.records
                      .fold<num>(0, (sum, type) => sum + leaveDaysLeft(type))
                      .floor(),
                ),
                onTap: onOpenLeave,
              ),
            ),
            BlocBuilder<AttendanceCubit, AttendanceState>(
              builder: (context, state) => AppActionCard(
                icon: AppShadowedImage(
                  asset: AppAssets.hrmsAttendance,
                  size: AppSizes.actionIcon,
                  shadow: drop,
                ),
                title: l10n.hrmsAttendanceCard,
                subtitle: l10n.hrmsDaysIn(
                  state is AttendanceLoaded
                      ? state.records
                            .where(
                              (record) =>
                                  parseAttendanceTime(record.checkin) != null,
                            )
                            .length
                      : 0,
                  DateFormat.MMMM(locale).format(today),
                ),
                onTap: onOpenAttendance,
              ),
            ),
          ],
        ),
        AppSpacing.gapXl,
        AppSectionTitle(l10n.hrmsLeaveBalance),
        AppSpacing.gapSmd,
        LeaveBalanceCard(
          onPick: onApplyFor == null
              ? null
              : (type) => onApplyFor!(type.leaveType),
        ),
        AppSpacing.gapXl,
        AppSectionTitle(
          l10n.hrmsMyRequests,
          trailing: AppButton(
            label: l10n.leaveHistory,
            variant: AppButtonVariant.text,
            size: AppButtonSize.small,
            expand: false,
            underlined: false,
            onPressed: () => showAllLeaveRequests(context),
          ),
        ),
        AppSpacing.gapSm,
        const LeaveRequestsCard(),
      ],
    );
  }
}

/// Who is signed in: their initials in a ring, their name, and their
/// designation on a chip.
class _Who extends StatelessWidget {
  const _Who();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final user = auth is AuthSuccess ? auth.message.user : null;
        final name = user?.fullName?.trim() ?? '';
        final role = user?.designation?.trim() ?? '';
        final empId = user?.empid?.toString() ?? '';
        final sapId = user?.sapid?.toString() ?? '';
        if (name.isEmpty && role.isEmpty) return const SizedBox.shrink();
        return Row(
          children: [
            UserAvatar(
              name: name,
              employeeId: empId,
              size: AppSizes.avatarMedium + AppSpacing.xs,
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge,
                    ),
                  if (role.isNotEmpty) ...[
                    AppSpacing.gapXxs,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryContainer,
                            colors.goldContainer,
                          ],
                        ),
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.smd,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppGlyphIcon(
                              AppGlyphs.briefcase,
                              size: AppSizes.iconXs,
                              color: colors.iconAccent,
                            ),
                            AppSpacing.gapXs,
                            Flexible(
                              child: Text(
                                role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: AppFonts.semiBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (empId.isNotEmpty || sapId.isNotEmpty) ...[
                    AppSpacing.gapXs,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (empId.isNotEmpty)
                          AppTag('Emp ID: $empId', tone: AppTone.brand),
                        if (sapId.isNotEmpty)
                          AppTag('SAP ID: $sapId', tone: AppTone.neutral),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
