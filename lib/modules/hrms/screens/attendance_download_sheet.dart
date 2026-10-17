import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/files/app_downloads.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/reports/attendance_pdf.dart';
import 'package:railway_hrms/modules/hrms/reports/attendance_report.dart';

/// Whether a report covers a calendar month or days picked.
enum ReportSpan { monthly, range }

/// Opens the sheet that downloads attendance as a PDF: a month or a run of
/// days, for oneself or, for someone with a team, any of its members.
/// [forTeam] starts on the team.
Future<void> showAttendanceDownload(
  BuildContext context, {
  bool forTeam = false,
}) {
  final l10n = context.l10n;
  final attendance = context.read<EmployeeAttendanceRepository>();
  final leaves = context.read<LeaveRepository>();
  final team = context.read<TeamCubit?>()?.state.members ?? const [];
  return showAppSheet<void>(
    context: context,
    title: l10n.downloadTitle,
    closeLabel: l10n.actionClose,
    builder: (_) => AttendanceDownloadSheet(
      loader: AttendanceReportLoader(attendance, leaves),
      team: team,
      forTeam: forTeam && team.isNotEmpty,
    ),
  );
}

class AttendanceDownloadSheet extends StatefulWidget {
  const AttendanceDownloadSheet({
    super.key,
    required this.loader,
    required this.team,
    this.forTeam = false,
    this.save = AppDownloads.save,
    this.now = DateTime.now,
  });

  final AttendanceReportLoader loader;

  /// The people who report to the signed-in employee; empty for most.
  final List<TeamMember> team;
  final bool forTeam;

  /// Saves the PDF; tests stand in for the phone.
  final Future<SavedFile> Function(
    Uint8List bytes, {
    required String name,
    required String mime,
  })
  save;
  final DateTime Function() now;

  @override
  State<AttendanceDownloadSheet> createState() =>
      _AttendanceDownloadSheetState();
}

class _AttendanceDownloadSheetState extends State<AttendanceDownloadSheet> {
  late final DateTime _today = DateUtils.dateOnly(widget.now());
  late DateTime _month = DateTime(_today.year, _today.month);
  ReportSpan _span = ReportSpan.monthly;
  DateTimeRange? _range;
  late bool _forTeam = widget.forTeam;
  late final Set<String> _picked = {
    for (final member in widget.team) member.employeeId,
  };
  String _query = '';
  bool _tried = false;

  /// While working: how many people are loaded, of how many.
  (int, int)? _progress;

  bool get _busy => _progress != null;

  static const _monthsBack = 24;

  DateTime get _from => _span == ReportSpan.monthly ? _month : _range!.start;

  DateTime get _to {
    if (_span == ReportSpan.range) return _range!.end;
    final last = DateTime(_month.year, _month.month + 1, 0);
    return last.isAfter(_today) ? _today : last;
  }

  List<TeamMember> get _shown {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.team;
    return [
      for (final member in widget.team)
        if (member.name.toLowerCase().contains(query) ||
            member.employeeId.contains(query) ||
            member.designation.toLowerCase().contains(query))
          member,
    ];
  }

  Future<List<ReportSubject>> _subjects() async {
    if (!_forTeam) {
      final user = (await StorageService.getUser())?.user;
      return [
        ReportSubject(
          employeeId: user?.empid ?? '',
          name: (user?.fullName ?? user?.name ?? '').trim(),
          designation: (user?.designation ?? '').trim(),
        ),
      ];
    }
    return [
      for (final member in widget.team)
        if (_picked.contains(member.employeeId))
          ReportSubject(
            employeeId: member.employeeId,
            name: member.name,
            designation: member.designation,
            department: member.department,
            division: member.division,
            location: member.location,
            shift: member.shift,
          ),
    ];
  }

  String _fileName(AttendanceReport report, String locale) {
    final who = report.isTeam
        ? 'Team'
        : report.people.first.subject.name.replaceAll(RegExp(r'\s+'), '_');
    final day = DateFormat('yyyy-MM-dd');
    final period = report.monthly
        ? DateFormat('MMMM_yyyy', 'en').format(report.from)
        : '${day.format(report.from)}_to_${day.format(report.to)}';
    final safe = '${who}_Attendance_$period'.replaceAll(
      RegExp(r'[^A-Za-z0-9_\-]'),
      '',
    );
    return '$safe.pdf';
  }

  Future<void> _download() async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() => _tried = true);
    if (_span == ReportSpan.range && _range == null) return;
    if (_forTeam && _picked.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = navigator.context;
    setState(() => _progress = (0, 1));
    try {
      final subjects = await _subjects();
      final report = await widget.loader.load(
        subjects: subjects,
        from: _from,
        to: _to,
        monthly: _span == ReportSpan.monthly,
        madeBy: _forTeam ? await _myName() : '',
        onProgress: (done, total) {
          if (mounted) setState(() => _progress = (done, total));
        },
      );
      final assets = await ReportAssets.load();
      final bytes = await AttendancePdf(
        report,
        l10n,
        assets,
        locale: locale,
      ).build();
      final file = await widget.save(
        bytes,
        name: _fileName(report, locale),
        mime: 'application/pdf',
      );
      if (!mounted) return;
      navigator.pop();
      if (messenger.mounted) await _saved(messenger, file);
    } on SaveException catch (error) {
      if (!mounted) return;
      showAppMessage(
        context,
        error.reason == SaveFailure.permission
            ? l10n.downloadNeedsStorage
            : l10n.downloadFailed,
        tone: AppDialogTone.error,
      );
    } on Exception catch (error) {
      debugPrint('Attendance PDF failed: $error');
      if (mounted) {
        showAppMessage(context, l10n.downloadFailed, tone: AppDialogTone.error);
      }
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  static Future<String> _myName() async {
    final user = (await StorageService.getUser())?.user;
    return (user?.fullName ?? user?.name ?? '').trim();
  }

  /// Says where the PDF went and offers to open or share it.
  static Future<void> _saved(BuildContext context, SavedFile file) async {
    final l10n = context.l10n;
    final open = await showAppDialog(
      context: context,
      tone: AppDialogTone.success,
      glyph: AppGlyphs.download,
      title: l10n.downloadSavedTitle,
      message: l10n.downloadSavedMessage(file.name),
      primaryLabel: l10n.downloadOpen,
      secondaryLabel: l10n.downloadShare,
    );
    if (open == null) return;
    final done = open
        ? await AppDownloads.open(file)
        : await AppDownloads.share(file, title: file.name);
    if (!done && open && context.mounted) {
      showAppMessage(context, l10n.downloadNoViewer, tone: AppDialogTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final oldest = DateTime(_today.year, _today.month - _monthsBack);
    final progress = _progress;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.downloadIntro,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          AppSpacing.gapLg,
          AppSectionLabel(l10n.downloadStepDates),
          AppSpacing.gapSm,
          AppChoiceChips<ReportSpan>(
            choices: [
              AppChoice(ReportSpan.monthly, l10n.downloadMonthly),
              AppChoice(ReportSpan.range, l10n.downloadRange),
            ],
            selected: _span,
            onSelected: _busy ? (_) {} : (span) => setState(() => _span = span),
          ),
          AppSpacing.gapMd,
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: _span == ReportSpan.monthly
                ? AppCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        AppTileButton(
                          icon: const AppGlyphIcon(AppGlyphs.chevronLeft),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).previousMonthTooltip,
                          onPressed: _month.isAfter(oldest)
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month - 1,
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                DateFormat.yMMMM(locale).format(_month),
                                style: text.titleMedium,
                              ),
                              Text(
                                '${DateFormat.MMMd(locale).format(_from)} – '
                                '${DateFormat.MMMd(locale).format(_to)}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        AppTileButton(
                          icon: const AppGlyphIcon(AppGlyphs.chevronRight),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).nextMonthTooltip,
                          onPressed:
                              _month.isBefore(
                                DateTime(_today.year, _today.month),
                              )
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month + 1,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  )
                : AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppDateRangeCalendar(
                      firstDate: oldest,
                      lastDate: _today,
                      today: _today,
                      selected: _range,
                      startLabel: l10n.leaveFrom,
                      endLabel: l10n.leaveTo,
                      emptyLabel: l10n.leaveNoDay,
                      onChanged: (range) => setState(() => _range = range),
                    ),
                  ),
          ),
          if (_tried && _span == ReportSpan.range && _range == null)
            AppFieldError(l10n.downloadPickRange),
          if (widget.team.isNotEmpty) ...[
            AppSpacing.gapLg,
            AppSectionLabel(l10n.downloadStepWhose),
            AppSpacing.gapSm,
            AppChoiceChips<bool>(
              choices: [
                AppChoice(false, l10n.downloadOnlyMe),
                AppChoice(true, l10n.downloadMyTeam),
              ],
              selected: _forTeam,
              onSelected: _busy
                  ? (_) {}
                  : (team) => setState(() => _forTeam = team),
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _forTeam ? _teamPicker(context) : const SizedBox.shrink(),
            ),
          ],
          AppSpacing.gapLg,
          AppButton(
            label: progress == null
                ? l10n.downloadButton
                : l10n.downloadPreparing(progress.$1, progress.$2),
            variant: AppButtonVariant.primary,
            leadingGlyph: AppGlyphs.download,
            isLoading: _busy,
            onPressed: _busy ? null : _download,
          ),
          if (progress != null && progress.$2 > 1) ...[
            AppSpacing.gapSm,
            ClipRRect(
              borderRadius: AppRadius.borderPill,
              child: LinearProgressIndicator(
                value: progress.$1 / progress.$2,
                minHeight: 4,
                color: colors.primary,
                backgroundColor: colors.surfaceSunken,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamPicker(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final shown = _shown;
    final allShownPicked =
        shown.isNotEmpty && shown.every((m) => _picked.contains(m.employeeId));
    void toggle(TeamMember member) => setState(() {
      if (!_picked.remove(member.employeeId)) _picked.add(member.employeeId);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.gapMd,
        if (widget.team.length > 5) ...[
          AppSearchField(
            hint: l10n.downloadSearch,
            onChanged: (query) => setState(() => _query = query),
          ),
          AppSpacing.gapSm,
        ],
        AppListGroup(
          children: [
            AppListRow(
              title: l10n.downloadSelectAll,
              subtitle: l10n.downloadSelected(
                _picked.length,
                widget.team.length,
              ),
              trailing: AppCheckbox(
                value: allShownPicked,
                onChanged: _busy
                    ? null
                    : (on) => setState(() {
                        for (final member in shown) {
                          if (on) {
                            _picked.add(member.employeeId);
                          } else {
                            _picked.remove(member.employeeId);
                          }
                        }
                      }),
              ),
            ),
            for (final member in shown)
              AppListRow(
                leading: AppAvatar(name: member.name),
                title: member.name.isEmpty ? member.employeeId : member.name,
                subtitle: [
                  member.employeeId,
                  member.designation,
                ].where((part) => part.isNotEmpty).join(' · '),
                onTap: _busy ? null : () => toggle(member),
                trailing: AppCheckbox(
                  value: _picked.contains(member.employeeId),
                  onChanged: _busy ? null : (_) => toggle(member),
                ),
              ),
          ],
        ),
        if (_tried && _picked.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.downloadPickPeople,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.danger,
              ),
            ),
          ),
      ],
    );
  }
}
