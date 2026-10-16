import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_status.dart';
import 'package:railway_hrms/modules/hrms/screens/others_attendance_view.dart';

/// The colour that marks [status] on the team's board and in its lists.
Color teamStatusColor(AppColors colors, TeamStatus status) => switch (status) {
  TeamStatus.present => colors.success,
  TeamStatus.late => colors.warningMark,
  TeamStatus.leave => colors.infoMark,
  TeamStatus.absent => colors.danger,
  TeamStatus.other => colors.textTertiary,
};

/// What [status] is called on the board.
String teamStatusLabel(AppLocalizations l10n, TeamStatus status) =>
    switch (status) {
      TeamStatus.present => l10n.teamStatusIn,
      TeamStatus.late => l10n.teamStatusLate,
      TeamStatus.leave => l10n.teamStatusLeave,
      TeamStatus.absent => l10n.teamStatusAbsent,
      TeamStatus.other => l10n.memberNotMarked,
    };

/// A member's status as a pill: "In 08:47", "Late 09:31", "On leave"…
class TeamMemberPill extends StatelessWidget {
  const TeamMemberPill({super.key, required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final checkIn = member.checkIn;
    final at = checkIn == null ? '' : DateFormat.jm(locale).format(checkIn);
    final (String label, AppTone tone) = switch (member.status) {
      TeamStatus.present when checkIn != null => (
        l10n.memberIn(at),
        AppTone.brand,
      ),
      TeamStatus.present => (l10n.teamStatusIn, AppTone.brand),
      TeamStatus.late when checkIn != null => (
        l10n.memberLate(at),
        AppTone.warning,
      ),
      TeamStatus.late => (l10n.teamStatusLate, AppTone.warning),
      TeamStatus.leave => (l10n.memberOnLeave, AppTone.info),
      TeamStatus.absent => (l10n.memberAbsent, AppTone.danger),
      TeamStatus.other => (
        member.statusText.isEmpty ? l10n.memberNotMarked : member.statusText,
        AppTone.neutral,
      ),
    };
    return AppPill(label, tone: tone);
  }
}

/// One member in a list: their initials ringed in their status colour,
/// their name, job and place, and their status.
class TeamMemberRow extends StatelessWidget {
  const TeamMemberRow({
    super.key,
    required this.member,
    required this.onTap,
    this.picked = false,
  });

  final TeamMember member;
  final VoidCallback onTap;

  /// Marks the row as the one chosen, in place of the status.
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = member.name.isEmpty ? member.employeeId : member.name;
    final detail = [
      member.designation,
      member.location,
    ].where((part) => part.isNotEmpty).join(' · ');
    return AppListRow(
      leading: AppAvatar.soft(
        name: name,
        size: AppSizes.avatarMedium,
        tint: _statusTint(colors, member.status),
        ring: teamStatusColor(colors, member.status),
      ),
      title: name,
      subtitle: detail.isEmpty ? null : detail,
      trailing: picked
          ? AppGlyphIcon(
              AppGlyphs.check,
              size: AppSizes.iconMd,
              color: colors.accent,
            )
          : TeamMemberPill(member: member),
      selected: picked,
      onTap: onTap,
    );
  }
}

/// Opens the whole team in a sheet under a banner of how the team's day
/// is going, grouped by where they are today, searchable, and filtered to
/// [status] when one is given. Tapping someone opens their profile.
Future<void> showTeamMembers(BuildContext context, {TeamStatus? status}) {
  final l10n = context.l10n;
  final cubit = context.read<TeamCubit>();
  return showAppSheet<void>(
    context: context,
    title: l10n.teamTitle,
    closeLabel: l10n.actionClose,
    header: BlocProvider.value(value: cubit, child: const _TeamHero()),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _MembersSheet(status: status),
    ),
  );
}

/// The banner over the team sheet: the title and when it was loaded, a few
/// of the team's faces, and how much of the team is in today.
class _TeamHero extends StatelessWidget {
  const _TeamHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, team) {
        final members = team.members;
        final people = members.isEmpty ? team.size : members.length;
        final inToday = members
            .where(
              (member) =>
                  member.status == TeamStatus.present ||
                  member.status == TeamStatus.late,
            )
            .length;
        final share = members.isEmpty ? 0.0 : inToday / members.length;
        final percent = (share * 100).round();
        final updated = team.updatedAt;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primaryContainer, colors.surface],
            ),
            borderRadius: AppRadius.borderHeroCard,
            border: Border.all(color: colors.outline),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderHeroCard,
            child: CustomPaint(
              painter: KhatamPatternPainter(
                color: colors.pattern,
                fadeHeight: AppSizes.heroPattern,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.teamTitle,
                                    style: text.headlineSmall,
                                  ),
                                ),
                                Text(
                                  updated == null
                                      ? l10n.teamPeople(people)
                                      : l10n.teamSheetSubtitle(
                                          l10n.teamPeople(people),
                                          DateFormat.jm(locale).format(updated),
                                        ),
                                  style: text.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSheetCloseButton(label: l10n.actionClose),
                      ],
                    ),
                    AppSpacing.gapMd,
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: AppAvatarStack(
                                names: [
                                  for (final member in members)
                                    member.name.isEmpty
                                        ? member.employeeId
                                        : member.name,
                                ],
                                tints: [
                                  colors.dayPresent,
                                  colors.goldContainer,
                                  colors.infoContainer,
                                  colors.surfaceMuted,
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapMd,
                          AppRingGauge(
                            fraction: share,
                            color: colors.success,
                            size: AppSizes.heroRing,
                            stroke: AppSizes.heroRingStroke,
                            semanticLabel: l10n.teamInTodaySemantics(percent),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.teamInToday(percent),
                                  style: text.titleSmall?.copyWith(
                                    fontFeatures: AppFonts.tabularFigures,
                                  ),
                                ),
                                Text(
                                  l10n.teamInTodayLabel,
                                  style: text.labelSmall?.copyWith(
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MembersSheet extends StatefulWidget {
  const _MembersSheet({this.status});

  final TeamStatus? status;

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  late TeamStatus? _status = widget.status;
  String _query = '';

  static const _statuses = [
    TeamStatus.present,
    TeamStatus.late,
    TeamStatus.leave,
    TeamStatus.absent,
  ];

  bool _matches(TeamMember member) {
    if (_status != null && member.status != _status) return false;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return member.name.toLowerCase().contains(query) ||
        member.employeeId.toLowerCase().contains(query) ||
        member.designation.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, state) {
        final members = state.members;
        final shown = members.where(_matches).toList();
        int count(TeamStatus status) =>
            members.where((member) => member.status == status).length;
        final groups = [
          for (final status in [..._statuses, TeamStatus.other])
            (
              status: status,
              members: [
                for (final member in shown)
                  if (member.status == status) member,
              ],
            ),
        ].where((group) => group.members.isNotEmpty).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              hint: l10n.teamSearchHint,
              clearLabel: l10n.actionClear,
              onChanged: (value) => setState(() => _query = value),
            ),
            AppSpacing.gapMd,
            AppStatFilter<TeamStatus>(
              selected: _status,
              onSelected: (status) => setState(() => _status = status),
              options: [
                for (final status in _statuses)
                  AppStatOption(
                    value: status,
                    label: teamStatusLabel(l10n, status),
                    count: count(status),
                    color: teamStatusColor(colors, status),
                    tint: _statusTint(colors, status),
                  ),
              ],
            ),
            AppSpacing.gapLg,
            Flexible(
              child: groups.isEmpty
                  ? _NobodyHere(failed: state.membersFailed)
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final (index, group) in groups.indexed) ...[
                          if (index > 0) AppSpacing.gapLg,
                          _GroupLabel(
                            status: group.status,
                            count: group.members.length,
                          ),
                          AppSpacing.gapSm,
                          for (final (row, member)
                              in group.members.indexed) ...[
                            if (row > 0) AppSpacing.gapSm,
                            TeamMemberCard(
                              member: member,
                              onTap: () => showTeamMember(context, member),
                            ),
                          ],
                        ],
                        AppSpacing.gapSm,
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A group's heading: its colour, what it is, and how many are in it.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.status, required this.count});

  final TeamStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final group = switch (status) {
      TeamStatus.present => l10n.teamGroupIn,
      TeamStatus.late => l10n.teamGroupLate,
      TeamStatus.leave => l10n.teamGroupLeave,
      TeamStatus.absent => l10n.teamGroupAbsent,
      TeamStatus.other => l10n.teamGroupOther,
    };
    return Semantics(
      header: true,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: teamStatusColor(colors, status),
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: AppSizes.statusDot),
          ),
          AppSpacing.gapSm,
          Flexible(
            child: Text(
              l10n.teamGroupCount(group, count).toUpperCase(),
              style: context.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tint behind a member's initials, by where they are today.
Color _statusTint(AppColors colors, TeamStatus status) => switch (status) {
  TeamStatus.present => colors.primaryContainer,
  TeamStatus.late => colors.goldContainer,
  TeamStatus.leave => colors.infoContainer,
  TeamStatus.absent => colors.dangerContainer,
  TeamStatus.other => colors.surfaceMuted,
};

/// Nobody matches, or the team couldn't be loaded.
class _NobodyHere extends StatelessWidget {
  const _NobodyHere({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppToneIcon(
            glyph: failed ? AppGlyphs.wifiOff : AppGlyphs.users,
            tone: failed ? AppTone.danger : AppTone.neutral,
          ),
          AppSpacing.gapSm,
          Text(
            failed ? l10n.teamMembersFailed : l10n.teamNobody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// A member on a card of their own: their initials ringed in their status
/// colour, their name and status, their job, and where they work.
class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({super.key, required this.member, required this.onTap});

  final TeamMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final name = member.name.isEmpty ? member.employeeId : member.name;
    return Semantics(
      button: true,
      child: AppInkSurface(
        onTap: onTap,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
          ),
          borderRadius: AppRadius.borderLinkCard,
          border: Border.all(color: colors.outline),
          boxShadow: context.elevations.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              AppAvatar.soft(
                name: name,
                size: AppSizes.avatarMedium,
                tint: _statusTint(colors, member.status),
                ring: teamStatusColor(colors, member.status),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge,
                          ),
                        ),
                        AppSpacing.gapSm,
                        TeamMemberPill(member: member),
                      ],
                    ),
                    if (member.designation.isNotEmpty)
                      Text(
                        member.designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    if (member.location.isNotEmpty) ...[
                      AppSpacing.gapXxs,
                      Row(
                        children: [
                          AppGlyphIcon(
                            AppGlyphs.mapPin,
                            size: AppSizes.iconXs,
                            color: colors.textTertiary,
                          ),
                          AppSpacing.gapXs,
                          Flexible(
                            child: Text(
                              member.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Opens [member]'s profile in a sheet.
Future<void> showTeamMember(BuildContext context, TeamMember member) {
  final l10n = context.l10n;
  return showAppSheet<void>(
    context: context,
    title: l10n.memberProfile,
    closeLabel: l10n.actionClose,
    builder: (_) => _MemberProfile(member: member),
  );
}

class _MemberProfile extends StatelessWidget {
  const _MemberProfile({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale);
    final name = member.name.isEmpty ? member.employeeId : member.name;
    final checkIn = member.checkIn;
    final checkOut = member.checkOut;
    final until = checkOut ?? DateTime.now();
    final worked = checkIn == null || until.isBefore(checkIn)
        ? null
        : until.difference(checkIn);
    Widget glyph(AppGlyph glyph) =>
        AppGlyphIcon(glyph, size: AppSizes.glyphRow, color: colors.iconAccent);
    final joined = member.joinedOn;
    final reportsTo = [
      member.reportsTo,
      member.reportsToDesignation,
    ].where((part) => part.isNotEmpty).join(' · ');
    final rows = [
      (AppGlyphs.idCard, l10n.memberEmployeeId, member.employeeId),
      (AppGlyphs.hash, l10n.memberSapId, member.sapId),
      (AppGlyphs.briefcase, l10n.memberDesignation, member.designation),
      (AppGlyphs.badgeCheck, l10n.memberRank, member.rank),
      (AppGlyphs.building, l10n.memberDepartment, member.department),
      (AppGlyphs.list, l10n.memberSubSection, member.subSection),
      (AppGlyphs.layers, l10n.memberDivision, member.division),
      (AppGlyphs.mapPin, l10n.memberLocation, member.location),
      (AppGlyphs.clock, l10n.memberShift, member.shift),
      (AppGlyphs.userCheck, l10n.memberReportsTo, reportsTo),
      (AppGlyphs.shieldCheck, l10n.memberRole, member.role),
      (
        AppGlyphs.calendarCheck,
        l10n.memberJoined,
        joined == null ? '' : DateFormat.yMMMd(locale).format(joined),
      ),
      (AppGlyphs.user, l10n.memberEmployment, member.employment),
    ].where((row) => row.$3.isNotEmpty);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Who they are, on a soft card.
          DecoratedBox(
            decoration: appCardDecoration(
              context,
              radius: AppRadius.borderHeroCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AppAvatar(name: name, size: AppSizes.avatarLarge),
                  AppSpacing.gapMd,
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall,
                  ),
                  if (member.designation.isNotEmpty) ...[
                    AppSpacing.gapXxs,
                    Text(
                      member.designation,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                  ],
                  AppSpacing.gapMd,
                  TeamMemberPill(member: member),
                  // The list gives times only for some; without one there
                  // is nothing to show.
                  if (checkIn != null) ...[
                    AppSpacing.gapLg,
                    Row(
                      children: [
                        Expanded(
                          child: AppStatTile(
                            labelFirst: true,
                            label: l10n.shiftCheckIn,
                            value: time.format(checkIn),
                          ),
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: AppStatTile(
                            labelFirst: true,
                            label: l10n.shiftCheckOut,
                            value: checkOut == null
                                ? l10n.shiftNotYet
                                : time.format(checkOut),
                            muted: checkOut == null,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: AppStatTile(
                            labelFirst: true,
                            label: l10n.memberAtWork,
                            value: worked == null
                                ? l10n.shiftNotYet
                                : l10n.attendanceWorked(
                                    worked.inHours,
                                    worked.inMinutes.remainder(60),
                                  ),
                            muted: worked == null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (rows.isNotEmpty) ...[
            AppSpacing.gapLg,
            AppListGroup(
              children: [
                for (final (icon, label, value) in rows)
                  AppListRow(
                    leading: glyph(icon),
                    title: label,
                    subtitle: value,
                  ),
              ],
            ),
          ],
          if (member.employeeId.isNotEmpty) ...[
            AppSpacing.gapLg,
            AppButton(
              label: l10n.memberMarkAttendance,
              variant: AppButtonVariant.secondary,
              leadingGlyph: AppGlyphs.scanFace,
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OthersAttendanceView(employeeId: member.employeeId),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
