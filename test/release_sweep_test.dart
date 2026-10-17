// Renders every screen at phone, iPhone, tablet and landscape sizes, with
// large text and dark mode, and reports each layout or runtime error.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/notifications/notification_view.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/app/settings/settings_view.dart';
import 'package:railway_hrms/app/shell/home_view.dart';
import 'package:railway_hrms/core/config/app_env.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';
import 'package:railway_hrms/modules/hrms/data/team_repository.dart';
import 'package:railway_hrms/modules/hrms/screens/apply_leave_view.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_history_view.dart';
import 'package:railway_hrms/modules/hrms/screens/face_registration_view.dart';
import 'package:railway_hrms/modules/hrms/screens/hrms_home_view.dart';
import 'package:railway_hrms/modules/hrms/screens/others_attendance_view.dart';
import 'package:railway_hrms/modules/hrms/screens/team_view.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_inspection_home_screen.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/sleepers_rails_sidings_screen.dart';
import 'package:railway_hrms/modules/inspection/dashboard/inspection_dashboard_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/electrical_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/inspection_approval_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_screen.dart';
import 'package:railway_hrms/modules/inspection/station/station_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_inspection_home.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/screens/accident_approval_screen.dart';
import 'package:railway_hrms/modules/prams/screens/accident_report_details_screen.dart';
import 'package:railway_hrms/modules/prams/screens/accident_report_form.dart';
import 'package:railway_hrms/modules/prams/screens/accident_submitted_screen.dart';
import 'package:railway_hrms/modules/prams/screens/accident_timeline_screen.dart';
import 'package:railway_hrms/modules/prams/screens/prams_dashboard_screen.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/screens/live_trains_home_content.dart';
import 'package:railway_hrms/modules/tracking/screens/train_tracking_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Response<dynamic> _ok(Object? data) =>
    Response(requestOptions: RequestOptions(), data: data);

final _today = DateTime(2026, 10, 6, 11);

String _day(int back) {
  final d = _today.subtract(Duration(days: back));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Attendance implements EmployeeAttendanceRepository {
  @override
  Future<Either<AppException, Response>> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  }) async => Left(AppException('offline'));

  @override
  Future<Either<AppException, Response>> getCheckImage({
    required int attId,
    required int empId,
  }) async => Left(AppException('offline'));

  @override
  Future<Either<AppException, Response>> getEmpAttendance({
    DateTime? month,
  }) async => Right(
    _ok([
      for (var back = 0; back < 9; back++)
        {
          'Emp_ID': 10482,
          'Date': _day(back),
          'Status': back == 2 ? 'Late' : (back == 4 ? 'Absent' : 'Present'),
          'Checkin': back == 4 ? null : '${_day(back)}T09:0${back % 9}:00',
          'Checkout': back == 0 || back == 4 ? null : '${_day(back)}T17:30:00',
          'ShiftStart': '09:00',
          'ShiftEnd': '17:00',
          'Shift': 'Morning',
        },
    ]),
  );

  @override
  Future<Either<AppException, Response>> getRecentEmployees() async =>
      Right(_ok({'Employees': const <Object>[]}));
}

class _Leaves implements LeaveRepository {
  @override
  Future<Either<AppException, Response>> getLeaveList({
    required String empId,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> getEmpLeaveLedger() async => Right(
    _ok([
      for (final (id, name) in [
        (1, 'Casual'),
        (2, 'Earned leave with a long name'),
        (3, 'Sick'),
      ])
        {
          'LeaveType': id,
          'LeaveTypeName': name,
          'Allotted': 10,
          'Remaining': 8,
          'Consumed': 2,
          'Status': true,
        },
    ]),
  );

  @override
  Future<Either<AppException, Response>> getLeaveHistory() async => Right(
    _ok([
      {
        'LeaveID': 1,
        'LeaveTypeID': 1,
        'LeaveName': 'Casual',
        'Remarks': 'Family function in the village, back on Monday',
        'AppliedDate': _day(3),
        'FromDate': _day(2),
        'ToDate': _day(1),
        'Status': 'Pending',
      },
    ]),
  );

  @override
  Future<Either<AppException, Response>> applyLeave(LeaveRequest r) async =>
      Right(_ok({'Success': 'Applied'}));
}

class _Team implements TeamRepository {
  @override
  Future<Either<AppException, Response>> getAllRequests({
    DateTime? day,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> getCounts(DateTime day) async => Right(
    _ok({
      'active': 12,
      'present': 7,
      'absent': 3,
      'leave': 2,
      'lateCheckin': 2,
      'OnRestDay': 1,
      'LeaversThisMonth': 0,
      'JoinersThisMonth': 1,
    }),
  );

  @override
  Future<Either<AppException, Response>> getMembers(DateTime day) async =>
      Right(
        _ok({
          'Employees': [
            for (var i = 0; i < 12; i++)
              {
                'Emp_ID': 100200 + i,
                'FullName': i.isEven
                    ? 'Muhammad Abdul Rehman Khan Niazi $i'
                    : 'Ali $i',
                'Designation': 'Assistant Executive Engineer (Works)',
                'Location': 'Lahore Divisional Office',
                'AttStatus': ['Present', 'Late', 'Leave', 'Absent'][i % 4],
                'Status': 'Active',
              },
          ],
        }),
      );
}

class _Faces implements FaceRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Accidents implements AccidentRepository {
  @override
  Future<Either<AppException, Response>> loadAccidentList() async =>
      Right(_ok({'accidents': _accidents}));

  @override
  Future<Either<AppException, Response>> loadAccidentTrainsData() async =>
      Left(AppException('offline'));

  @override
  Future<Either<AppException, Response>> loadAccidentById(int id) async =>
      Right(_ok({'accident': _accidents.first}));

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final _accidents = [
  {
    'id': 1,
    'train_number': '1',
    'train_direction': 'UP',
    'train_name': 'Khyber Mail',
    'accident_class_meaning':
        'Derailment of a passenger train on the main line',
    'kilometer_number': '1280/04',
    'block_section_label': 'Rohri Junction – Sukkur Main Station',
    'accident_date_time': '2026-10-04T10:20:00',
    'severity': 'CRITICAL',
    'status': 'UNDER_INVESTIGATION',
    'origin_station_name': 'Peshawar Cantt',
    'destination_station_name': 'Karachi Cantt',
    'description': 'Two coaches off the track near the outer signal.',
  },
];

/// HRMS's cubits, filled.
Widget _hrms(Widget child) => Scaffold(body: _hrmsCubits(child));

Widget _hrmsCubits(Widget child) => MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => FaceVerificationCubit(_Faces())),
    BlocProvider(
      create: (_) => AttendanceCubit(_Attendance())..fetchAttendance(),
    ),
    BlocProvider(
      create: (_) => AuthCubit(FailingAuthRepository())..loadUserData(),
    ),
    BlocProvider(
      create: (_) => LeaveCubit(_Leaves())
        ..fetchLeaveLeadger()
        ..fetchHistory(),
    ),
    BlocProvider(create: (_) => WorkAreaCubit()),
    BlocProvider(create: (_) => TeamCubit(_Team())..load()),
  ],
  child: child,
);

typedef _Config = ({
  String name,
  Size size,
  TargetPlatform platform,
  double text,
  bool dark,
});

const List<_Config> _configs = [
  (
    name: 'android-small',
    size: Size(320, 568),
    platform: TargetPlatform.android,
    text: 1,
    dark: false,
  ),
  (
    name: 'android-bigtext-dark',
    size: Size(412, 915),
    platform: TargetPlatform.android,
    text: 1.3,
    dark: true,
  ),
  (
    name: 'iphone',
    size: Size(393, 852),
    platform: TargetPlatform.iOS,
    text: 1,
    dark: false,
  ),
  (
    name: 'iphone-bigtext',
    size: Size(393, 852),
    platform: TargetPlatform.iOS,
    text: 1.5,
    dark: false,
  ),
  (
    name: 'phone-landscape',
    size: Size(852, 393),
    platform: TargetPlatform.iOS,
    text: 1,
    dark: false,
  ),
  (
    name: 'tablet-portrait-dark',
    size: Size(800, 1280),
    platform: TargetPlatform.android,
    text: 1,
    dark: true,
  ),
  (
    name: 'tablet-landscape',
    size: Size(1280, 800),
    platform: TargetPlatform.iOS,
    text: 1,
    dark: false,
  ),
  (
    name: 'galaxy-fold-cover',
    size: Size(302, 772),
    platform: TargetPlatform.android,
    text: 1,
    dark: false,
  ),
  (
    name: 'galaxy-fold-open',
    size: Size(674, 786),
    platform: TargetPlatform.android,
    text: 1,
    dark: false,
  ),
  (
    name: 'pixel-fold-open',
    size: Size(841, 701),
    platform: TargetPlatform.android,
    text: 1,
    dark: true,
  ),
  (
    name: 'galaxy-flip',
    size: Size(386, 943),
    platform: TargetPlatform.android,
    text: 1.15,
    dark: false,
  ),
  (
    name: 'samsung-zoomed-bigtext',
    size: Size(320, 693),
    platform: TargetPlatform.android,
    text: 1.3,
    dark: false,
  ),
  (
    name: 'iphone-pro-max',
    size: Size(440, 956),
    platform: TargetPlatform.iOS,
    text: 1,
    dark: false,
  ),
];

class _Trains implements TrainRepository {
  @override
  Future<Either<AppException, Response>> getStations({String? pageUrl}) async =>
      Right(_ok(const <Object>[]));

  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async =>
      Right(_ok(const <String, Object>{}));

  @override
  Future<Either<AppException, Response>> getTrains() async => Right(
    _ok([
      for (var i = 0; i < 8; i++)
        {
          'id': i,
          'train': {
            'name': i.isEven
                ? 'Allama Iqbal Express With A Very Long Service Name'
                : '13$i-UP',
            'train_no': 1000 + i,
            'direction': i.isEven ? 1 : 2,
          },
          'device_id': null,
          'origin_station': {
            'id': 1,
            'name': 'Karachi Cantonment Junction Station',
            'station_code': 'KC',
          },
          'destination_station': {
            'id': 2,
            'name': 'Peshawar Cantt',
            'station_code': 'PSC',
          },
        },
    ]),
  );
}

Widget _tracking(Widget child) => BlocProvider(
  create: (_) => RealTimeTrackingCubit(_Trains())..initialize(),
  child: child,
);

const _ahmed = SignedInUser(
  name: 'Muhammad Ahmed Raza Khan',
  role: 'Assistant Executive Engineer',
);

final Map<String, Widget Function()> _screens = {
  'shell-home': () => Scaffold(
    body: HomeView(
      user: _ahmed,
      now: () => _today,
      onOpenModule: (_) {},
      onOpenAlerts: () {},
      onOpenProfile: () {},
    ),
  ),
  'shell-profile': () => const SettingsView(user: _ahmed),
  'shell-alerts': () => NotificationView(now: () => _today),
  'tracking-home': () => _tracking(const LiveTrainsHomeContent()),
  'tracking-list': () => _tracking(const TrainTrackingView()),
  'hrms-home': () => _hrms(
    HrmsHomeView(
      onOpenAttendance: () {},
      onOpenLeave: () {},
      now: () => _today,
    ),
  ),
  'hrms-attendance': () =>
      _hrms(AttendanceHistoryView(onBack: () {}, now: () => _today)),
  'hrms-leave': () => _hrms(ApplyLeaveView(onBack: () {}, now: () => _today)),
  'hrms-team': () => _hrms(TeamView(onBack: () {})),
  'hrms-others': () => _hrms(const OthersAttendanceView()),
  'hrms-face-registration': () =>
      FaceRegistrationView(onRegister: (_) async => null),
  'insp-dashboard': () => InspectionDashboardScreen(now: () => _today),
  'insp-approval': () => const InspectionApprovalScreen(),
  'insp-footplate-wizard': () => const FootplateWizardScreen(),
  'insp-station': () => const StationInspectionScreen(),
  'insp-motor-trolley': () => const MotorTrolleyInspectionScreen(),
  'insp-locomotive': () => const LocomotiveInspectionScreen(),
  'insp-electrical': () => const ElectricalInspectionScreen(),
  'insp-civil-home': () => const CivilInspectionHomeScreen(),
  'insp-civil-sleepers': () => const SleepersRailsSidingsScreen(),
  'insp-traffic': () =>
      const TrafficInspectionHome(stationName: 'Lahore Junction'),
  'prams-dashboard': () => PramsDashboardScreen(
    cubit: AccidentCubit(repository: _Accidents())..loadAccidentList(),
    now: () => _today,
  ),
  'prams-report': () => const AccidentReportingScreen(),
  'prams-details': () =>
      AccidentReportDetailsScreen(accident: Accidents.fromJson(_accidents[0])),
  'prams-timeline': () => const AccidentTimelineScreen(),
  'prams-approval': () => const AccidentApprovalScreen(),
  'prams-submitted': () => const AccidentReportSubmittedScreen(),
};

/// The first line that says what went wrong.
String _gist(FlutterErrorDetails details) {
  final text = details.exceptionAsString().split('\n').first;
  // Where in the app it happened: the widget the error names.
  final at = RegExp(
    r'lib/[\w/]+\.dart:\d+',
  ).firstMatch(details.toString())?.group(0);
  final gist = text.length > 160 ? '${text.substring(0, 160)}…' : text;
  return at == null ? gist : '$gist @ $at';
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // Requests go nowhere in tests; the client only needs its addresses.
    AppEnv.loadFromString(
      'BASE_URL=http://localhost\nBASE_URL_FACE_AUTH=http://localhost',
    );
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sl.registerFactory<AccidentRepository>(_Accidents.new);
    sl.registerFactory<FaceRepository>(_Faces.new);
    sl.registerSingleton<BiometricAuthenticator>(FakeBiometrics());
    sl.registerSingleton<AppearanceController>(AppearanceController());
    sl.registerSingleton<TextLookController>(TextLookController());
    sl.registerFactory<RealTimeTrackingCubit>(
      () => RealTimeTrackingCubit(_Trains()),
    );
  });
  tearDown(sl.reset);

  for (final MapEntry(key: name, value: build) in _screens.entries) {
    testWidgets('sweep $name', (tester) async {
      final problems = <String>{};
      for (final config in _configs) {
        final original = FlutterError.onError;
        FlutterError.onError = (details) =>
            problems.add('[${config.name}] ${_gist(details)}');
        try {
          tester.view.physicalSize = config.size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding =
              config.platform == TargetPlatform.iOS &&
                  config.size.height > config.size.width
              ? notchedPadding
              : FakeViewPadding.zero;
          tester.platformDispatcher.textScaleFactorTestValue = config.text;
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(config.name),
              theme: (config.dark ? AppTheme.darkTheme : AppTheme.lightTheme)
                  .copyWith(platform: config.platform),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: build(),
            ),
          );
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
          // Down the page, so what is built lazily is laid out too.
          final pages = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          for (var i = 0; i < 4 && pages.evaluate().isNotEmpty; i++) {
            await tester.drag(
              pages.first,
              const Offset(0, -600),
              warnIfMissed: false,
            );
            await tester.pump(const Duration(milliseconds: 300));
          }
          final error = tester.takeException();
          if (error != null) {
            problems.add(
              '[${config.name}] ${error.toString().split('\n').first}',
            );
          }
        } catch (error) {
          problems.add(
            '[${config.name}] THROWN ${error.toString().split('\n').first}',
          );
        } finally {
          FlutterError.onError = original;
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      for (final problem in problems) {
        debugPrint('PROBLEM $name $problem');
      }
      debugPrint('SWEPT $name: ${problems.length} problems');
    });
  }
}
