import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_register_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_helpers.dart';
import 'package:railway_hrms/modules/hrms/utils/face_registration.dart';
import 'package:railway_hrms/modules/hrms/utils/timer_notifier.dart';
import 'package:railway_hrms/modules/hrms/widgets/attendance_gate.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A shift's length when the record doesn't give one.
const _defaultShift = Duration(hours: 9);

/// Today's attendance: how the day stands, the time at work running live
/// against the shift, the check-in and check-out times, and the key that
/// checks in or out with the face.
class ShiftCard extends StatefulWidget {
  const ShiftCard({super.key, this.now});

  /// The clock; the device's by default.
  final DateTime Function()? now;

  @override
  State<ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<ShiftCard> {
  final _timer = TimerNotifier();
  User? _user;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  Future<void> _checkFaceRegistration() async {
    final user = (await StorageService.getUser())?.user;
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  void _sync(AttendanceState state) {
    _checkFaceRegistration();
    if (state is! AttendanceLoaded) return;
    final today = AttendanceRecord.forDay(state.records, _now());
    _timer.syncWithAttendance(
      checkIn: parseAttendanceTime(today?.checkin),
      checkOut: parseAttendanceTime(today?.checkout),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkFaceRegistration();
    _sync(context.read<AttendanceCubit>().state);
  }

  /// Checks in or out, but only from a genuine phone inside a work area;
  /// from outside, the map shows the way in first.
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
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.jm(locale);
    return BlocListener<WorkAreaCubit, WorkAreaState>(
      listener: (context, areaState) {
        if (!areaState.loadingOffices) {
          _checkFaceRegistration();
        }
      },
      child: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (context, state) => _sync(state),
        builder: (context, state) {
          final now = _now();
          final record = state is AttendanceLoaded
              ? AttendanceRecord.forDay(state.records, now)
              : null;
          final day = AttendanceDay.of(now, record);
          final checkedIn = day.checkIn != null;
          final checkedOut = day.checkOut != null;
          final (String status, AppTone tone, Color dot) = switch (day.mark) {
            _ when checkedOut => (
              l10n.shiftCheckedOut,
              AppTone.neutral,
              colors.textTertiary,
            ),
            AttendanceMark.late => (
              l10n.shiftLate,
              AppTone.warning,
              colors.warningMark,
            ),
            AttendanceMark.onTime => (
              l10n.shiftOnTime,
              AppTone.brand,
              colors.success,
            ),
            AttendanceMark.leave => (
              l10n.shiftOnLeave,
              AppTone.info,
              colors.infoMark,
            ),
            AttendanceMark.absent => (
              l10n.shiftAbsent,
              AppTone.danger,
              colors.danger,
            ),
            _ => (l10n.shiftNotIn, AppTone.neutral, colors.textTertiary),
          };
          final start = day.shiftStart;
          final end = day.shiftEnd;
          final shift = start != null && end != null && end.isAfter(start)
              ? end.difference(start)
              : _defaultShift;
          final loading =
              state is AttendanceInitial || state is AttendanceLoading;

          return Semantics(
            container: true,
            label: l10n.shiftTodayLabel,
            child: DecoratedBox(
              decoration: appCardDecoration(
                context,
                radius: AppRadius.borderHeroCard,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Skeletonizer(
                  enabled: loading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppPill(status, tone: tone, dot: dot),
                          ),
                          AppSpacing.gapSm,
                          const Spacer(),
                          Text(
                            DateFormat('EEE d MMM', locale).format(now),
                            style: text.bodySmall?.copyWith(
                              fontWeight: AppFonts.semiBold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      ListenableBuilder(
                        listenable: _timer,
                        builder: (context, _) {
                          final worked =
                              _timer.status == SessionStatus.notCheckedIn
                              ? Duration.zero
                              : _timer.elapsed;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.end,
                                spacing: AppSpacing.sm,
                                children: [
                                  Text(
                                    _clock(worked),
                                    style: text.displayLarge?.copyWith(
                                      fontSize: AppFonts.metricHero,
                                      letterSpacing:
                                          AppFonts.metricHeroLetterSpacing,
                                      height: 1,
                                      fontFeatures: AppFonts.tabularFigures,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      l10n.shiftHoursAtWork,
                                      style: text.bodyMedium?.copyWith(
                                        fontWeight: AppFonts.medium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapLg,
                              AppProgressTrack(
                                to: worked.inSeconds / shift.inSeconds,
                                semanticLabel: l10n.shiftProgress(
                                  (worked.inSeconds / shift.inSeconds * 100)
                                      .clamp(0, 100)
                                      .round(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (start != null && end != null) ...[
                        AppSpacing.gapXs,
                        ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final edge in [start, end])
                                Text(
                                  time.format(edge),
                                  style: text.labelSmall?.copyWith(
                                    letterSpacing: 0,
                                    fontFeatures: AppFonts.tabularFigures,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      AppSpacing.gapMd,
                      Row(
                        children: [
                          Expanded(
                            child: AppStatTile(
                              labelFirst: true,
                              label: l10n.shiftCheckIn,
                              value: checkedIn
                                  ? time.format(day.checkIn!)
                                  : l10n.shiftNotYet,
                              muted: !checkedIn,
                            ),
                          ),
                          AppSpacing.gapSmd,
                          Expanded(
                            child: AppStatTile(
                              labelFirst: true,
                              label: l10n.shiftCheckOut,
                              value: checkedOut
                                  ? time.format(day.checkOut!)
                                  : l10n.shiftNotYet,
                              muted: !checkedOut,
                            ),
                          ),
                        ],
                      ),
                      if (state is AttendanceError) ...[
                        AppSpacing.gapMd,
                        _LoadFailed(
                          onRetry: () =>
                              context.read<AttendanceCubit>().fetchAttendance(),
                        ),
                      ],
                      AppSpacing.gapMd,
                      BlocBuilder<FaceVerificationCubit, FaceRegisterStates>(
                        builder: (context, face) {
                          final user = _user;
                          final String buttonLabel;
                          final AppGlyph buttonGlyph;
                          if (user?.isApproved == true) {
                            buttonLabel = checkedIn && !checkedOut
                                ? l10n.shiftActionCheckOut
                                : l10n.shiftActionCheckIn;
                            buttonGlyph = AppGlyphs.scanFace;
                          } else if (user != null &&
                              (user.isInProgress || user.isRejected)) {
                            buttonLabel = user.formattedVerificationStatus;
                            buttonGlyph = user.isInProgress
                                ? AppGlyphs.clock
                                : AppGlyphs.scanFace;
                          } else {
                            // Not registered yet: the key starts that.
                            buttonLabel = l10n.shiftRegisterFace;
                            buttonGlyph = AppGlyphs.scanFace;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppButton(
                                label: buttonLabel,
                                leadingGlyph: buttonGlyph,
                                isLoading: face is FaceVerifying,
                                onPressed: _checkIn,
                              ),
                              if (user?.isRejected == true) ...[
                                AppSpacing.gapSm,
                                Text(
                                  'Verification rejected. Please tap above to re-register your face.',
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall?.copyWith(
                                    color: colors.onDangerContainer,
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
              ),
            ),
          );
        },
      ),
    );
  }

  /// "05:42": hours and minutes.
  static String _clock(Duration worked) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(worked.inHours)}:${two(worked.inMinutes.remainder(60))}';
  }
}

/// Today's attendance couldn't be loaded, with a way to try again.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Row(
      children: [
        AppGlyphIcon(
          AppGlyphs.wifiOff,
          size: AppSizes.iconSm,
          color: colors.onDangerContainer,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            l10n.shiftLoadFailed,
            style: context.textTheme.bodySmall?.copyWith(
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
          onPressed: onRetry,
        ),
      ],
    );
  }
}
