import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/utils/date_ranges.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_state.dart';
import 'package:railway_hrms/modules/hrms/data/leave_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_types.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';
import 'package:railway_hrms/modules/hrms/widgets/leave_cards.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// How far ahead leave can be asked for.
const _bookingWindow = Duration(days: 30);

/// The maximum characters a reason may have.
const _reasonMaximum = 50;

/// Asks for leave: the type, picked from cards with the days left of each;
/// the days, on a calendar; and the reason. The request goes to the
/// reporting manager.
class ApplyLeaveView extends StatelessWidget {
  const ApplyLeaveView({
    super.key,
    this.onBack,
    this.applyFor,
    this.now,
    this.initialDays,
  });

  /// Goes back; there is no back tile without it.
  final VoidCallback? onBack;

  /// A type of leave to pick, as from a balance tapped elsewhere; the form
  /// picks it and clears it.
  final ValueNotifier<int?>? applyFor;

  /// The clock; the device's by default.
  final DateTime Function()? now;

  /// Initial days range to pre-select on calendar.
  final DateTimeRange? initialDays;

  @override
  Widget build(BuildContext context) {
    final form = _LeaveForm(
      onBack: onBack,
      applyFor: applyFor,
      now: now ?? DateTime.now,
      initialDays: initialDays,
    );
    // Inside HRMS, the balances are shared so the home updates on sending.
    LeaveCubit? shared;
    try {
      shared = context.read<LeaveCubit>();
    } on ProviderNotFoundException {
      shared = null;
    }
    if (shared != null) return BlocProvider.value(value: shared, child: form);
    return RepositoryProvider<LeaveRepository>(
      create: (_) =>
          LeaveRepositoryImpl(LeaveRemoteDataSourceImpl(DioClient())),
      child: BlocProvider<LeaveCubit>(
        create: (context) => LeaveCubit(context.read())
          ..fetchLeaveLeadger()
          ..fetchHistory(),
        child: form,
      ),
    );
  }
}

class _LeaveForm extends StatefulWidget {
  const _LeaveForm({
    required this.onBack,
    required this.applyFor,
    required this.now,
    this.initialDays,
  });

  final VoidCallback? onBack;
  final ValueNotifier<int?>? applyFor;
  final DateTime Function() now;
  final DateTimeRange? initialDays;

  @override
  State<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<_LeaveForm> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  int? _type;
  DateTimeRange? _days;

  /// Set once sending was tried, so missing parts say so.
  bool _tried = false;

  /// This form sent the request being applied; another open copy of it
  /// mustn't react.
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final asked = widget.applyFor;
    _type = asked?.value;
    asked?.value = null;
    asked?.addListener(_takeType);
    _days = widget.initialDays;
  }

  @override
  void dispose() {
    widget.applyFor?.removeListener(_takeType);
    _reason.dispose();
    super.dispose();
  }

  /// Picks the type of leave asked for elsewhere, once.
  void _takeType() {
    final asked = widget.applyFor;
    final type = asked?.value;
    if (asked == null || type == null) return;
    asked.value = null;
    if (mounted) setState(() => _type = type);
  }

  void _send() {
    setState(() => _tried = true);
    final reasonOk = _form.currentState?.validate() ?? false;
    final type = _type;
    final days = _days;
    if (!reasonOk || type == null || days == null) return;
    FocusScope.of(context).unfocus();
    _sending = true;
    context.read<LeaveCubit>().applyLeave(
      LeaveRequest(
        leaveTypeID: type,
        from: apiDay(days.start),
        to: apiDay(days.end),
        remarks: _reason.text.trim(),
      ),
    );
  }

  Future<void> _onApplied(BuildContext context, LeaveState state) async {
    if (!_sending || state.applyStatus == ApplyStatus.applying) return;
    _sending = false;
    final l10n = context.l10n;
    final sent = state.applyStatus == ApplyStatus.success;
    if (sent) {
      _form.currentState?.reset();
      _reason.clear();
      setState(() {
        _type = null;
        _days = null;
        _tried = false;
      });
    }
    await showAppDialog(
      context: context,
      tone: sent ? AppDialogTone.success : AppDialogTone.error,
      title: sent ? l10n.leaveSentTitle : l10n.leaveSendFailedTitle,
      message: state.applyMessage,
      primaryLabel: l10n.actionOk,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.dateOnly(widget.now());
    return BlocConsumer<LeaveCubit, LeaveState>(
      listenWhen: (a, b) => a.applyStatus != b.applyStatus,
      listener: _onApplied,
      builder: (context, state) {
        final loading =
            state.fetchStatus != LeaveStatus.loaded &&
            state.fetchStatus != LeaveStatus.error;
        final types = state.records;
        final picked = types.where((type) => type.leaveType == _type);
        final type = picked.isEmpty ? null : picked.first;
        final days = _days;
        final count = days == null
            ? 0
            : daysBetweenInclusive(days.start, days.end);
        return Scaffold(
          body: AppScrollPage(
            backdrop: AppPageBackdrop.blobs,
            onRefresh: () => Future.wait([
              context.read<LeaveCubit>().refresh(),
              context.read<LeaveCubit>().fetchHistory(),
            ]),
            children: [
              AppHeaderBar(
                large: true,
                title: l10n.leaveTitle,
                onBack: widget.onBack,
                actions: [
                  AppButton(
                    label: l10n.leaveHistory,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    expand: false,
                    underlined: false,
                    onPressed: () => showAllLeaveRequests(context),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              if (state.fetchStatus == LeaveStatus.error)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.leaveTypesFailed,
                        style: text.bodySmall?.copyWith(
                          color: colors.onDangerContainer,
                          fontWeight: AppFonts.semiBold,
                        ),
                      ),
                    ),
                    AppButton(
                      label: l10n.actionRetry,
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      expand: false,
                      underlined: false,
                      onPressed: () =>
                          context.read<LeaveCubit>().fetchLeaveLeadger(),
                    ),
                  ],
                )
              else
                Semantics(
                  label: l10n.leaveTypeGroup,
                  container: true,
                  child: Skeletonizer(
                    enabled: loading,
                    child: AppGrid(
                      columns: 3,
                      spacing: AppSpacing.smd,
                      children: [
                        for (final choice in loading ? _placeholders : types)
                          AppChoiceCard(
                            selected: choice.leaveType == _type,
                            onTap: () =>
                                setState(() => _type = choice.leaveType),
                            child: _TypeFace(type: choice),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_tried && type == null && !loading)
                AppFieldError(l10n.leavePickTypeError),
              AppSpacing.gapMd,
              AppCard.glass(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md + AppSpacing.xxs,
                  AppSpacing.md + AppSpacing.xxs,
                  AppSpacing.md + AppSpacing.xxs,
                  AppSpacing.smd,
                ),
                child: Semantics(
                  label: l10n.leavePickDates,
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppDateRangeCalendar(
                        firstDate: today,
                        lastDate: today.add(_bookingWindow),
                        today: today,
                        selected: days,
                        startLabel: l10n.leaveFrom,
                        endLabel: l10n.leaveTo,
                        emptyLabel: l10n.leaveNoDay,
                        startPrompt: l10n.leavePickFirstDay,
                        endPrompt: l10n.leavePickLastDay,
                        onChanged: (range) => setState(() => _days = range),
                      ),
                      if (days != null) ...[
                        AppSpacing.gapXs,
                        Divider(height: 1, color: colors.outline),
                        AppSpacing.gapSm,
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: AppSpacing.sm,
                          children: [
                            Text(
                              formatDayRange(days.start, days.end, locale),
                              style: text.labelMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: AppFonts.bold,
                              ),
                            ),
                            if (type != null)
                              Text(
                                l10n.leaveDaysAfter(
                                  count,
                                  formatDays(
                                    (leaveDaysLeft(type) - count).clamp(
                                      0,
                                      double.infinity,
                                    ),
                                  ),
                                ),
                                style: text.labelMedium?.copyWith(
                                  fontWeight: AppFonts.regular,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_tried && days == null)
                AppFieldError(l10n.leavePickDatesError),
              AppSpacing.gapMd,
              Form(
                key: _form,
                child: AppTextField(
                  controller: _reason,
                  label: l10n.leaveReason,
                  hint: l10n.leaveReasonHint,
                  glyph: AppGlyphs.fileEdit,
                  minLines: 2,
                  maxLines: 4,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_reasonMaximum),
                  ],
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  autovalidateMode: _tried
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Please enter a reason';
                    }
                    if (text.length > _reasonMaximum) {
                      return 'Reason cannot exceed $_reasonMaximum characters';
                    }
                    return null;
                  },
                ),
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  const _ManagerBadge(),
                  AppSpacing.gapSmd,
                  Expanded(
                    child: Text(
                      l10n.leaveGoesTo,
                      style: text.labelMedium?.copyWith(
                        fontWeight: AppFonts.regular,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXl,
              AppButton(
                label: l10n.leaveSend,
                loadingLabel: l10n.leaveSending,
                isLoading: state.applyStatus == ApplyStatus.applying,
                onPressed: loading ? null : _send,
              ),
            ],
          ),
        );
      },
    );
  }

  static final _placeholders = [
    for (var i = 0; i < 3; i++)
      LeaveTypesRecord(
        leaveType: -1 - i,
        leaveTypeName: 'Casual',
        leaveFlag: '',
        allotted: 10,
        remaining: 8,
        consumed: 2,
        status: true,
        applicationPeriod: 0,
        icon: '',
      ),
  ];
}

/// A leave type on its card: its name, the days left, and of how many.
class _TypeFace extends StatelessWidget {
  const _TypeFace({required this.type});

  final LeaveTypesRecord type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.leaveTypeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.labelMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: AppFonts.semiBold,
          ),
        ),
        AppSpacing.gapXs,
        Text(
          formatDays(leaveDaysLeft(type)),
          style: text.headlineMedium?.copyWith(
            fontFeatures: AppFonts.tabularFigures,
          ),
        ),
        Text(
          l10n.leaveLeftOf(formatDays(type.allotted)),
          style: text.labelSmall?.copyWith(
            letterSpacing: 0,
            fontWeight: AppFonts.medium,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The small gold sphere beside "Goes to your reporting manager".
class _ManagerBadge extends StatelessWidget {
  const _ManagerBadge();

  @override
  Widget build(BuildContext context) {
    final sphere = context.spheres.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.44),
          colors: [sphere.highlight, sphere.body, sphere.shade],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: sphere.shade.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -3,
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: AppSizes.optionLeading - AppSpacing.xxs,
        child: Center(
          child: AppGlyphIcon(
            AppGlyphs.userCheck,
            size: AppSizes.iconXs,
            color: sphere.mark,
          ),
        ),
      ),
    );
  }
}
