import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_register_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_attendance_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_status.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_download_sheet.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_helpers.dart';
import 'package:railway_hrms/modules/hrms/utils/face_registration.dart';
import 'package:railway_hrms/modules/hrms/widgets/attendance_gate.dart';
import 'package:railway_hrms/modules/hrms/widgets/mark_team_card.dart';
import 'package:railway_hrms/modules/hrms/widgets/team_member_sheets.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// How many of the team the page lists before "All".
const _listed = 5;

/// The admin's team: their own day at the top, the board of who is in,
/// late, on leave and absent, and the team itself. Each count and "All"
/// open the members in a sheet; each member opens their profile.
class TeamView extends StatelessWidget {
  const TeamView({super.key, this.onBack});

  /// Goes back; there is no back tile without it.
  final VoidCallback? onBack;

  /// Says the team couldn't be loaded and offers to try again, when the
  /// team's tab is the one in front.
  Future<void> _onFailed(BuildContext context, TeamState state) async {
    if (!TickerMode.valuesOf(context).enabled) return;
    final l10n = context.l10n;
    final again = await showAppDialog(
      context: context,
      tone: AppDialogTone.error,
      glyph: AppGlyphs.wifiOff,
      title: l10n.teamLoadFailedTitle,
      message: l10n.teamLoadFailedMessage,
      primaryLabel: l10n.actionRefresh,
      secondaryLabel: l10n.actionCancel,
    );
    if ((again ?? false) && context.mounted) {
      await context.read<TeamCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TeamCubit, TeamState>(
      listenWhen: (before, now) =>
          now.load == TeamLoad.ready && now.failed && before != now,
      listener: _onFailed,
      builder: (context, state) {
        final loading = state.load != TeamLoad.ready;
        return AppScrollPage(
          tightGutter: true,
          onRefresh: () => context.read<TeamCubit>().load(silent: true),
          children: [
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, auth) {
                final user = auth is AuthSuccess ? auth.message.user : null;
                return AppHeaderBar(
                  title: l10n.teamTitle,
                  subtitle: [
                    user?.fullName?.trim() ?? '',
                    user?.designation?.trim() ?? '',
                    if (state.size > 0) l10n.teamPeople(state.size),
                  ].where((part) => part.isNotEmpty).join(' · '),
                  onBack: onBack,
                );
              },
            ),
            AppSpacing.gapLg,
            const _MyDay(),
            AppSpacing.gapMd,
            const MarkTeamCard(),
            AppSpacing.gapMd,
            AppFeatureCard(
              glyph: AppGlyphs.download,
              title: l10n.downloadTeamCardTitle,
              message: l10n.downloadTeamCardMessage,
              tags: [
                l10n.downloadMonthly,
                l10n.downloadTagAnyDates,
                l10n.downloadTagLeaves,
              ],
              actionLabel: l10n.downloadButton,
              actionGlyph: AppGlyphs.download,
              onPressed: () => showAttendanceDownload(context, forTeam: true),
            ),
            AppSpacing.gapMd,
            Skeletonizer(
              enabled: loading,
              child: _Board(state: state),
            ),
            AppSpacing.gapXl,
            AppSectionTitle(l10n.teamRightNow),
            AppSpacing.gapSm,
            if (state.members.isEmpty)
              DecoratedBox(
                decoration: appCardDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: loading
                      ? Center(child: AppLoader())
                      : Text(
                          state.membersFailed
                              ? l10n.teamMembersFailed
                              : l10n.teamNobody,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium,
                        ),
                ),
              )
            else
              AppListGroup(
                children: [
                  for (final member in state.members.take(_listed))
                    TeamMemberRow(
                      member: member,
                      onTap: () => showTeamMember(context, member),
                    ),
                ],
              ),
            if (state.members.isNotEmpty) ...[
              AppSpacing.gapMd,
              AppButton(
                label: l10n.teamViewAll(state.members.length),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                leadingGlyph: AppGlyphs.users,
                onPressed: () => showTeamMembers(context),
              ),
            ],
            AppSpacing.gapXl,
            _TeamRequestsSection(
              requests: state.requests,
              loading: loading,
              failed: state.requestsFailed,
            ),
          ],
        );
      },
    );
  }
}

/// The admin's own day: in since when and for how long, and the key that
/// checks in or out.
class _MyDay extends StatefulWidget {
  const _MyDay();

  @override
  State<_MyDay> createState() => _MyDayState();
}

class _MyDayState extends State<_MyDay> {
  late final Timer _tick;
  User? _user;

  Future<void> _checkFaceRegistration() async {
    final user = (await StorageService.getUser())?.user;
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkFaceRegistration();
    // The time at work moves on by the minute.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (_user?.isInProgress == true) {
      showVerificationProgressDialog(context);
      return;
    }
    final area = context.read<WorkAreaCubit>();
    if (!await confirmAtWork(context, area: area) || !mounted) return;
    await onCheckInTap(context);
    await _checkFaceRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        final now = DateTime.now();
        final record = state is AttendanceLoaded
            ? AttendanceRecord.forDay(state.records, now)
            : null;
        final checkIn = parseAttendanceTime(record?.checkin);
        final checkOut = parseAttendanceTime(record?.checkout);
        final inNow = checkIn != null && checkOut == null;
        final worked = checkIn == null
            ? null
            : (checkOut ?? now).difference(checkIn);
        return DecoratedBox(
          decoration: appCardDecoration(
            context,
            radius: AppRadius.borderLinkCard,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md + AppSpacing.xxs,
              AppSpacing.smd,
              AppSpacing.smd,
              AppSpacing.smd,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inNow ? colors.success : colors.textTertiary,
                    boxShadow: [
                      BoxShadow(
                        color: inNow
                            ? colors.navIndicator
                            : colors.surfaceMuted,
                        spreadRadius: AppSpacing.xs,
                      ),
                    ],
                  ),
                  child: const SizedBox.square(dimension: AppSizes.statMark),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Text(
                    checkIn == null || worked == null
                        ? l10n.teamYouAreOut
                        : l10n.teamYouAreIn(
                            DateFormat.jm(locale).format(checkIn),
                            l10n.attendanceWorked(
                              worked.inHours,
                              worked.inMinutes.remainder(60),
                            ),
                          ),
                    style: context.textTheme.titleSmall,
                  ),
                ),
                AppSpacing.gapSm,
                BlocBuilder<FaceVerificationCubit, FaceRegisterStates>(
                  builder: (context, face) {
                    final user = _user;
                    final String label;
                    if (user?.isApproved == true) {
                      label = inNow
                          ? l10n.shiftActionCheckOut
                          : l10n.shiftActionCheckIn;
                    } else {
                      label =
                          user?.formattedVerificationStatus ??
                          'Verification Pending';
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: label,
                          size: AppButtonSize.small,
                          expand: false,
                          isLoading: face is FaceVerifying,
                          onPressed: _checkIn,
                        ),
                        if (user?.isRejected == true) ...[
                          AppSpacing.gapXs,
                          Text(
                            'Verification rejected. Please tap above to re-register.',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.onDangerContainer,
                              fontWeight: AppFonts.semiBold,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Team today": a count for each status over a bar of their shares.
class _Board extends StatelessWidget {
  const _Board({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final counts = state.counts;
    const shown = [
      TeamStatus.present,
      TeamStatus.late,
      TeamStatus.leave,
      TeamStatus.absent,
    ];
    final updated = state.updatedAt;
    return DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.teamToday,
                      style: text.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                  ),
                ),
                if (updated != null)
                  Text(
                    l10n.teamUpdated(DateFormat.jm(locale).format(updated)),
                    style: text.labelMedium?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: AppFonts.semiBold,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                for (final (index, status) in shown.indexed) ...[
                  if (index > 0) AppSpacing.gapSm,
                  Expanded(
                    child: AppStatTile(
                      value: '${counts.of(status)}',
                      label: teamStatusLabel(l10n, status),
                      mark: teamStatusColor(colors, status),
                      valueStyle: text.headlineMedium?.copyWith(
                        fontSize: AppFonts.metricLarge,
                      ),
                      onTap: state.members.isEmpty
                          ? null
                          : () => showTeamMembers(context, status: status),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.gapMd,
            AppStackedBar(
              semanticLabel: l10n.teamBarLabel(
                counts.of(TeamStatus.present),
                counts.of(TeamStatus.late),
                counts.of(TeamStatus.leave),
                counts.of(TeamStatus.absent),
              ),
              segments: [
                for (final status in shown)
                  (
                    value: counts.of(status),
                    color: teamStatusColor(colors, status),
                  ),
              ],
            ),
            if (counts.restDay > 0 ||
                counts.joiners > 0 ||
                counts.leavers > 0) ...[
              AppSpacing.gapSm,
              Text(
                [
                  if (counts.restDay > 0) l10n.teamRestDay(counts.restDay),
                  if (counts.joiners > 0 || counts.leavers > 0)
                    l10n.teamMonthChanges(counts.joiners, counts.leavers),
                ].join(' · '),
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum RequestFilter { all, leaves, changeRequests }

class _TeamRequestsSection extends StatefulWidget {
  const _TeamRequestsSection({
    required this.requests,
    required this.loading,
    required this.failed,
  });

  final List<TeamAttendanceRequest> requests;
  final bool loading;
  final bool failed;

  @override
  State<_TeamRequestsSection> createState() => _TeamRequestsSectionState();
}

class _TeamRequestsSectionState extends State<_TeamRequestsSection> {
  bool _expanded = false;
  RequestFilter _filter = RequestFilter.all;

  List<TeamAttendanceRequest> _getFilteredRequests(
    List<TeamAttendanceRequest> requests,
  ) {
    switch (_filter) {
      case RequestFilter.leaves:
        return requests.where((r) {
          final t = r.requestType.toLowerCase();
          return t.contains('leave');
        }).toList();
      case RequestFilter.changeRequests:
        return requests.where((r) {
          final t = r.requestType.toLowerCase();
          return !t.contains('leave');
        }).toList();
      case RequestFilter.all:
        return requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRequests = widget.requests;
    final filtered = _getFilteredRequests(allRequests);
    final shown = _expanded ? filtered : filtered.take(3).toList();

    final leaveCount = allRequests
        .where((r) => r.requestType.toLowerCase().contains('leave'))
        .length;
    final changeCount = allRequests
        .where((r) => !r.requestType.toLowerCase().contains('leave'))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle('Team Leaves & Change Requests'),
        AppSpacing.gapSm,
        if (allRequests.isNotEmpty) ...[
          AppFilterChips<RequestFilter>(
            selected: _filter,
            onSelected: (selected) {
              setState(() {
                _filter = selected;
              });
            },
            options: [
              AppFilterOption(
                value: RequestFilter.all,
                label: 'All',
                count: allRequests.length,
              ),
              AppFilterOption(
                value: RequestFilter.leaves,
                label: 'Leaves',
                count: leaveCount,
              ),
              AppFilterOption(
                value: RequestFilter.changeRequests,
                label: 'Change Requests',
                count: changeCount,
              ),
            ],
          ),
          AppSpacing.gapMd,
        ],
        if (filtered.isEmpty)
          DecoratedBox(
            decoration: appCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: widget.loading
                  ? Center(child: AppLoader())
                  : Text(
                      widget.failed
                          ? 'Failed to load team requests'
                          : (allRequests.isEmpty
                                ? 'No leave or change requests'
                                : 'No matching requests found'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium,
                    ),
            ),
          )
        else ...[
          AppListGroup(
            children: [
              for (final request in shown)
                _TeamRequestRow(
                  request: request,
                  onTap: () => _showRequestDetail(context, request),
                ),
            ],
          ),
          if (filtered.length > 3) ...[
            AppSpacing.gapMd,
            AppButton(
              label: _expanded
                  ? 'Show less'
                  : 'View all requests (${filtered.length})',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              leadingGlyph: _expanded
                  ? AppGlyphs.chevronUp
                  : AppGlyphs.clipboardList,
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _TeamRequestRow extends StatelessWidget {
  const _TeamRequestRow({required this.request, required this.onTap});

  final TeamAttendanceRequest request;
  final VoidCallback onTap;

  AppTone _statusTone(String status) {
    final s = status.toLowerCase();
    if (s.contains('approve') || s.contains('accept')) return AppTone.brand;
    if (s.contains('pend') || s.contains('wait') || s.contains('process')) {
      return AppTone.warning;
    }
    if (s.contains('reject') || s.contains('decline') || s.contains('cancel')) {
      return AppTone.danger;
    }
    return AppTone.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = request.employeeName.isNotEmpty
        ? request.employeeName
        : (request.empId.isNotEmpty
              ? 'Employee #${request.empId}'
              : 'Request #${request.requestId}');

    final dates = _formatDates(request);
    final detailParts = [
      if (request.requestType.isNotEmpty) request.requestType,
      if (request.designation.isNotEmpty) request.designation,
      if (dates.isNotEmpty) dates,
    ];
    final subtitle = detailParts.join(' · ');

    final tone = _statusTone(request.status);

    return AppListRow(
      leading: AppAvatar.soft(
        name: name,
        size: AppSizes.avatarMedium,
        tint: tone == AppTone.brand
            ? colors.primaryContainer
            : (tone == AppTone.warning
                  ? colors.goldContainer
                  : colors.surfaceMuted),
        ring: tone == AppTone.brand
            ? colors.success
            : (tone == AppTone.warning
                  ? colors.warningMark
                  : colors.textTertiary),
      ),
      title: name,
      subtitle: subtitle.isNotEmpty ? subtitle : null,
      trailing: AppPill(
        request.status.isNotEmpty ? request.status : 'Pending',
        tone: tone,
      ),
      showChevron: true,
      onTap: onTap,
    );
  }

  String _formatDates(TeamAttendanceRequest request) {
    if (request.fromDate.isNotEmpty && request.toDate.isNotEmpty) {
      if (request.fromDate == request.toDate) {
        return request.fromDate;
      }
      return '${request.fromDate} → ${request.toDate}';
    }
    if (request.fromDate.isNotEmpty) return request.fromDate;
    if (request.appliedDate.isNotEmpty) return request.appliedDate;
    return '';
  }
}

void _showRequestDetail(BuildContext context, TeamAttendanceRequest request) {
  final cubit = context.read<TeamCubit>();
  showAppSheet<void>(
    context: context,
    title: 'Request Details',
    closeLabel: 'Close',
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _RequestDetailSheet(request: request),
    ),
  );
}

class _RequestDetailSheet extends StatefulWidget {
  const _RequestDetailSheet({required this.request});

  final TeamAttendanceRequest request;

  @override
  State<_RequestDetailSheet> createState() => _RequestDetailSheetState();
}

class _RequestDetailSheetState extends State<_RequestDetailSheet> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _handleAction(String action) async {
    if (_isApproving || _isRejecting) return;
    setState(() {
      if (action == 'Approved') {
        _isApproving = true;
      } else {
        _isRejecting = true;
      }
    });

    final cubit = context.read<TeamCubit>();
    final bool success;
    if (widget.request.isChangeRequest) {
      final crId = widget.request.crId ?? widget.request.requestId;
      final requestType = action == 'Approved' ? 'Approve' : 'Reject';
      success = await cubit.approveChangeRequest(
        crId: crId,
        requestType: requestType,
      );
    } else {
      success = await cubit.approveLeave(
        leaveId: widget.request.requestId,
        empId: widget.request.empId,
        action: action,
      );
    }

    if (!mounted) return;

    setState(() {
      _isApproving = false;
      _isRejecting = false;
    });

    final message = success
        ? 'Request successfully ${action.toLowerCase()}'
        : 'Failed to update request. Please try again.';

    showAppMessage(context, message, tone: AppDialogTone.success);

    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final colors = context.colors;
    final request = widget.request;
    final name = request.employeeName.isNotEmpty
        ? request.employeeName
        : (request.empId.isNotEmpty
              ? 'Employee #${request.empId}'
              : 'Request #${request.requestId}');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar.soft(name: name, size: AppSizes.avatarLarge),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleLarge),
                    if (request.designation.isNotEmpty ||
                        request.department.isNotEmpty ||
                        request.empId.isNotEmpty)
                      Text(
                        [
                          if (request.designation.isNotEmpty)
                            request.designation,
                          if (request.department.isNotEmpty) request.department,
                          if (request.empId.isNotEmpty) 'ID: ${request.empId}',
                        ].join(' · '),
                        style: text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          AppListGroup(
            children: [
              if (request.requestType.isNotEmpty)
                AppListRow(
                  title: 'Request Type',
                  subtitle: request.requestType,
                ),
              if (request.fromDate.isNotEmpty || request.toDate.isNotEmpty)
                AppListRow(
                  title: 'Date',
                  subtitle:
                      request.fromDate == request.toDate ||
                          request.toDate.isEmpty
                      ? request.fromDate
                      : '${request.fromDate} → ${request.toDate}',
                ),
              if (request.appliedDate.isNotEmpty)
                AppListRow(title: 'Applied On', subtitle: request.appliedDate),
              AppListRow(
                title: 'Status',
                subtitle: request.status.isNotEmpty
                    ? request.status
                    : 'Pending',
              ),
              if (request.remarks.isNotEmpty)
                AppListRow(
                  title: 'Remarks / Reason',
                  subtitle: request.remarks,
                ),
            ],
          ),
          AppSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.medium,
                  leadingGlyph: AppGlyphs.close,
                  isLoading: _isRejecting,
                  onPressed: (_isApproving || _isRejecting)
                      ? null
                      : () => _handleAction('Rejected'),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.medium,
                  leadingGlyph: AppGlyphs.check,
                  isLoading: _isApproving,
                  onPressed: (_isApproving || _isRejecting)
                      ? null
                      : () => _handleAction('Approved'),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
        ],
      ),
    );
  }
}
