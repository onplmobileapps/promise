import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/face_verification/face_remote_datasource.dart';
import 'package:railway_hrms/core/face_verification/face_repository_impl.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/data/auth_remote_datasource.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_register_states.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/data/leave_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository_impl.dart';
import 'package:railway_hrms/modules/hrms/data/team_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/team_repository.dart';
import 'package:railway_hrms/modules/hrms/screens/apply_leave_view.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_history_view.dart';
import 'package:railway_hrms/modules/hrms/screens/hrms_home_view.dart';
import 'package:railway_hrms/modules/hrms/screens/team_view.dart';

/// HRMS's tabs, in the order of its bar. Team shows only to those who have
/// a team.
enum HrmsTab { home, attendance, leave, team }

/// The HRMS tab shown, by [HrmsTab.index]. The app's shell reads it to
/// leave back to HRMS while a tab other than home is open.
final ValueNotifier<int> bottomNavIndexNotifier = ValueNotifier<int>(0);

/// HRMS: the employee's home, attendance and leave, and for an admin with
/// a team, the team; under a bar of its own.
class HrmsDashboardView extends StatelessWidget {
  const HrmsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FaceRepositoryImpl>(
          create: (_) =>
              FaceRepositoryImpl(FaceRemoteDataSourceImpl(DioClient())),
        ),
        RepositoryProvider<AuthRepository>(
          create: (_) =>
              AuthRepositoryImpl(AuthRemoteDataSourceImpl(DioClient())),
        ),
        RepositoryProvider<LeaveRepository>(
          create: (_) =>
              LeaveRepositoryImpl(LeaveRemoteDataSourceImpl(DioClient())),
        ),
        RepositoryProvider<EmployeeAttendanceRepository>(
          create: (_) => EmployeeAttendanceRepositoryImpl(
            EmployeeAttendanceRemoteDataSourceImpl(DioClient()),
          ),
        ),
        RepositoryProvider<TeamRepository>(
          create: (_) =>
              TeamRepositoryImpl(TeamRemoteDataSourceImpl(DioClient())),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<FaceVerificationCubit>(
            create: (context) =>
                FaceVerificationCubit(context.read<FaceRepositoryImpl>()),
          ),
          BlocProvider<AttendanceCubit>(
            create: (context) =>
                AttendanceCubit(context.read<EmployeeAttendanceRepository>())
                  ..fetchAttendance(),
          ),
          BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(context.read<AuthRepository>())..loadUserData(),
          ),
          BlocProvider<LeaveCubit>(
            create: (context) => LeaveCubit(context.read<LeaveRepository>())
              ..fetchLeaveLeadger()
              ..fetchHistory(),
          ),
          BlocProvider<WorkAreaCubit>(create: (_) => WorkAreaCubit()..start()),
          BlocProvider<TeamCubit>(
            create: (context) =>
                TeamCubit(context.read<TeamRepository>())..load(),
          ),
        ],
        child: const _ReloadOnAttendance(child: _HrmsTabs()),
      ),
    );
  }
}

class _HrmsTabs extends StatefulWidget {
  const _HrmsTabs();

  @override
  State<_HrmsTabs> createState() => _HrmsTabsState();
}

class _HrmsTabsState extends State<_HrmsTabs> {
  /// Tabs opened so far; the rest aren't built until they are.
  final _opened = <HrmsTab>{HrmsTab.home};

  /// The type of leave to apply for, from a balance tapped on the home;
  /// the leave form takes it up.
  final _leaveType = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    // The tab outlives the screen; start on the home.
    bottomNavIndexNotifier.value = HrmsTab.home.index;
  }

  @override
  void dispose() {
    _leaveType.dispose();
    super.dispose();
  }

  void _open(HrmsTab tab) => bottomNavIndexNotifier.value = tab.index;

  void _applyFor(int type) {
    _leaveType.value = type;
    _open(HrmsTab.leave);
  }

  void _home() => _open(HrmsTab.home);

  void _onAttendance(BuildContext context, FaceRegisterStates state) {
    final l10n = context.l10n;
    if (state is FaceVerified) {
      showAppDialog(
        context: context,
        tone: AppDialogTone.success,
        title: l10n.attendanceMarkedTitle,
        message: state.message,
        primaryLabel: l10n.actionOk,
      );
    } else if (state is FaceVerifyError) {
      showAppDialog(
        context: context,
        tone: AppDialogTone.error,
        title: l10n.attendanceFailedTitle,
        message: state.error,
        primaryLabel: l10n.actionOk,
      );
    }
  }

  Widget _page(HrmsTab tab) => switch (tab) {
    HrmsTab.home => HrmsHomeView(
      onOpenAttendance: () => _open(HrmsTab.attendance),
      onOpenLeave: () => _open(HrmsTab.leave),
      onApplyFor: _applyFor,
    ),
    HrmsTab.attendance => AttendanceHistoryView(onBack: _home),
    HrmsTab.leave => ApplyLeaveView(onBack: _home, applyFor: _leaveType),
    // The team's page is the heaviest: a loader shows while it is built.
    HrmsTab.team => AppDeferred(builder: (_) => TeamView(onBack: _home)),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<FaceVerificationCubit, FaceRegisterStates>(
          listenWhen: (_, state) =>
              state is FaceVerified || state is FaceVerifyError,
          listener: _onAttendance,
        ),
        // Should the team go, so does its tab.
        BlocListener<TeamCubit, TeamState>(
          listenWhen: (a, b) => a.hasTeam != b.hasTeam,
          listener: (context, team) {
            if (!team.hasTeam &&
                bottomNavIndexNotifier.value == HrmsTab.team.index) {
              _home();
            }
          },
        ),
      ],
      child: ValueListenableBuilder<int>(
        valueListenable: bottomNavIndexNotifier,
        builder: (context, index, _) {
          final tab = HrmsTab.values[index];
          _opened.add(tab);
          // From HRMS's home, back and the iOS swipe close HRMS; from
          // another of its tabs they go to its home first, and a swipe in
          // from the edge does the same.
          final home = tab == HrmsTab.home;
          return PopScope(
            canPop: home,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _home();
            },
            child: AppSwipeBack(
              enabled: !home,
              onBack: _home,
              child: Scaffold(
                extendBody: true,
                body: IndexedStack(
                  index: index,
                  children: [
                    for (final each in HrmsTab.values)
                      _opened.contains(each)
                          ? _page(each)
                          : const SizedBox.shrink(),
                  ],
                ),
                bottomNavigationBar: BlocBuilder<TeamCubit, TeamState>(
                  buildWhen: (a, b) => a.hasTeam != b.hasTeam,
                  builder: (context, team) {
                    // Every tab stays in the bar; the team's folds in once
                    // a team loads, and away if it goes.
                    const tabs = HrmsTab.values;
                    return AppNavigationBar(
                      items: [
                        for (final each in tabs)
                          switch (each) {
                            HrmsTab.home => AppNavItem(
                              glyph: AppGlyphs.home,
                              label: l10n.navHome,
                            ),
                            HrmsTab.attendance => AppNavItem(
                              glyph: AppGlyphs.navAttendance,
                              label: l10n.hrmsNavAttendance,
                            ),
                            HrmsTab.leave => AppNavItem(
                              glyph: AppGlyphs.navLeave,
                              label: l10n.hrmsNavLeave,
                            ),
                            HrmsTab.team => AppNavItem(
                              glyph: AppGlyphs.navTeam,
                              label: l10n.hrmsNavTeam,
                              visible: team.hasTeam,
                            ),
                          },
                      ],
                      selectedIndex: tabs.indexOf(tab),
                      onSelected: (position) => _open(tabs[position]),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reloads the attendance whenever it is marked anywhere in the app, again
/// a moment later in case the server is still saving it.
class _ReloadOnAttendance extends StatefulWidget {
  const _ReloadOnAttendance({required this.child});

  final Widget child;

  @override
  State<_ReloadOnAttendance> createState() => _ReloadOnAttendanceState();
}

class _ReloadOnAttendanceState extends State<_ReloadOnAttendance> {
  Timer? _again;

  @override
  void initState() {
    super.initState();
    FaceVerificationCubit.attendanceMarked.addListener(_reload);
  }

  @override
  void dispose() {
    FaceVerificationCubit.attendanceMarked.removeListener(_reload);
    _again?.cancel();
    super.dispose();
  }

  void _reload() {
    final attendance = context.read<AttendanceCubit>();
    final team = context.read<TeamCubit>();
    attendance.fetchAttendance(silent: true);
    team.load(silent: true);
    _again?.cancel();
    _again = Timer(const Duration(seconds: 2), () {
      if (!attendance.isClosed) attendance.fetchAttendance(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
