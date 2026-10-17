// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PROMISE';

  @override
  String get appFullName =>
      'Pakistan Railway Operational and Management Integrated Services Ecosystem';

  @override
  String get organisationName => 'Pakistan Railways';

  @override
  String get appEmblemLabel => 'PROMISE emblem';

  @override
  String get splashTagline =>
      'Pakistan Railway Operational and Management Integrated Services Ecosystem';

  @override
  String get poweredBy => 'Designed and developed by One Network';

  @override
  String copyrightNotice(int year) {
    return '© $year All rights reserved';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionBack => 'Back';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableMessage =>
      'A newer version of PROMISE is available. Update now to get the latest security fixes and features.';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get loginTabTrainTracking => 'TRACKING';

  @override
  String get loginTabPromise => 'PROMISE';

  @override
  String get loginWelcomeTitle => 'Welcome back';

  @override
  String loginWelcomeDetail(String app) {
    return 'Your workday starts here with $app';
  }

  @override
  String get loginEyebrow => 'EMPLOYEE ACCESS';

  @override
  String get loginCardTitle => 'Sign in to your workspace';

  @override
  String get loginBiometricNote =>
      'For employees with biometric sign-in turned on.';

  @override
  String loginOrPassword(String id, String password) {
    return 'or use $id & $password';
  }

  @override
  String get loginWithPassword => 'Sign In with Employee ID & Password';

  @override
  String get loginSecure => 'Built for the people who keep Pakistan moving';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginTrackingSubtitle =>
      'Enter your mobile number, then scan your CNIC.';

  @override
  String get loginPromiseSubtitle => 'Enter your employee ID and password.';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginInProgress => 'Signing in';

  @override
  String get loginFailedTitle => 'Couldn\'t sign you in';

  @override
  String get employeeIdLabel => 'Employee ID';

  @override
  String get employeeIdHint => 'Enter your employee ID';

  @override
  String employeeIdTooLong(int max) {
    return 'Employee ID can be at most $max characters';
  }

  @override
  String get employeeIdRequired => 'Employee ID is required';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String passwordTooLong(int max) {
    return 'Password can be at most $max characters';
  }

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get biometricFaceId => 'Sign In with Face ID';

  @override
  String get biometricFace => 'Sign In with Face';

  @override
  String get biometricFingerprint => 'Sign In with Fingerprint';

  @override
  String get biometricReason => 'Authenticate to sign in to PROMISE';

  @override
  String get biometricDisabledTitle => 'Turn on biometric sign-in';

  @override
  String get biometricDisabledMessage =>
      'Sign in once with your employee ID and password, then turn on Biometric login in Profile. After that, your fingerprint or Face ID signs you in.';

  @override
  String get biometricNoCredentialsTitle => 'Sign in once first';

  @override
  String get biometricNoCredentialsMessage =>
      'No saved sign-in was found on this phone. Sign in with your employee ID and password once.';

  @override
  String get networkOperatorLabel => 'Network operator';

  @override
  String get networkOperatorHint => 'Select network operator';

  @override
  String get networkOperatorRequired => 'Please select a network operator';

  @override
  String get mobileNumberLabel => 'Mobile number';

  @override
  String get mobileNumberHint => '03XXXXXXXXX';

  @override
  String get mobileNumberRequired => 'Mobile number is required';

  @override
  String get mobileNumberStart => 'Mobile number must start with 03';

  @override
  String get mobileNumberLength =>
      'Mobile number must be 11 digits, like 03001234567';

  @override
  String get otpTitle => 'Verify code';

  @override
  String otpSubtitle(int length) {
    return 'Enter the $length-digit code we sent to';
  }

  @override
  String get otpFieldLabel => 'One-time code';

  @override
  String get otpNotReceived => 'Didn\'t receive the code?';

  @override
  String get otpResend => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpVerify => 'Verify';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordMessage =>
      'Enter your email address. We will send you a verification code or a link to reset your password.';

  @override
  String get forgotPasswordFieldLabel => 'Email address';

  @override
  String get forgotPasswordFieldHint => 'name@example.com';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get featureInDevelopmentTitle => 'Coming soon';

  @override
  String get featureInDevelopmentMessage =>
      'This feature is being built. Please check back later.';

  @override
  String get networkOfflineTitle => 'You\'re offline';

  @override
  String get networkOfflineMessage => 'Turn on Wi-Fi or mobile data';

  @override
  String get networkNoInternetTitle => 'No internet';

  @override
  String get networkNoInternetMessage => 'Wi-Fi or data is on but not working';

  @override
  String get networkSlowTitle => 'Slow internet';

  @override
  String get networkSlowMessage => 'The app is running slowly';

  @override
  String get networkBackOnlineTitle => 'Back online';

  @override
  String get networkBackOnlineMessage => 'You\'re connected again';

  @override
  String get networkRetry => 'Retry';

  @override
  String networkStatusAnnouncement(String title, String message) {
    return '$title. $message';
  }

  @override
  String get permissionCameraTitle => 'Allow camera access';

  @override
  String get permissionCameraReason =>
      'PROMISE uses the camera to scan your CNIC, to take inspection and accident photos, and to check your face when attendance is marked. It\'s only on while you take a photo.';

  @override
  String get permissionCameraBlocked =>
      'Camera access is turned off for PROMISE. To take photos, allow the camera in Settings.';

  @override
  String get permissionLocationTitle => 'Allow location access';

  @override
  String get permissionLocationReason =>
      'PROMISE uses your location to confirm you\'re at your work area when attendance is marked, and to record where inspections and accidents are reported. It\'s only read while you use these features.';

  @override
  String get permissionLocationBlocked =>
      'Location access is turned off for PROMISE. To mark attendance and file reports, allow location in Settings.';

  @override
  String get permissionNotificationsTitle => 'Turn on notifications';

  @override
  String get permissionNotificationsReason =>
      'Hear straight away about leave requests, approvals and other updates that need your attention.';

  @override
  String get permissionNotificationsBlocked =>
      'Notifications are turned off for PROMISE. To hear about requests and approvals, allow notifications in Settings.';

  @override
  String get permissionBlockedTitle => 'Allow access in Settings';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get permissionNotNow => 'Not now';

  @override
  String get homeModulesTitle => 'Modules';

  @override
  String get homeProfile => 'Your profile';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get moduleHrmsTitle => 'HRMS';

  @override
  String get moduleHrmsSubtitle => 'Human Resource Management System';

  @override
  String get moduleTrackingTitle => 'Tracking';

  @override
  String get moduleTrackingSubtitle => 'Realtime Train Tracking';

  @override
  String get moduleInspectionTitle => 'e Inspection';

  @override
  String get moduleInspectionSubtitle => 'Digital Inspection of Assets';

  @override
  String get modulePramsTitle => 'PRAMS';

  @override
  String get modulePramsSubtitle => 'Accident Management System';

  @override
  String get navHome => 'Home';

  @override
  String get navTrains => 'Trains';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get navCheckIn => 'Check in or out with your face';

  @override
  String get exitTitle => 'Close PROMISE?';

  @override
  String get exitMessage => 'You\'ll sign in again the next time you open it.';

  @override
  String get exitConfirm => 'Close app';

  @override
  String get attendanceMarkedTitle => 'Attendance marked';

  @override
  String get attendanceFailedTitle => 'Couldn\'t mark attendance';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String alertsOverline(int count, String date) {
    return '$count new · $date';
  }

  @override
  String get alertsMarkAllRead => 'Mark all read';

  @override
  String get alertsFilterAll => 'All';

  @override
  String get alertsFilterAccidents => 'Accidents';

  @override
  String get alertsFilterLeave => 'Leave';

  @override
  String get alertsFilterAttendance => 'Attendance';

  @override
  String get alertsToday => 'Today';

  @override
  String get alertsYesterday => 'Yesterday';

  @override
  String get alertsEmptyTitle => 'Nothing here yet';

  @override
  String get alertsEmptyMessage =>
      'Updates about accidents, leave and attendance will show up here.';

  @override
  String get alertsOpenCase => 'Open case';

  @override
  String get alertUnread => 'Unread';

  @override
  String get caseReported => 'Reported';

  @override
  String get caseAcknowledged => 'Acknowledged';

  @override
  String get caseRelief => 'Relief';

  @override
  String get caseCleared => 'Cleared';

  @override
  String caseStepOf(int step, int total, String name) {
    return 'Step $step of $total: $name';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String profileEmployeeId(String id) {
    return 'EMP $id';
  }

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileSecurity => 'Change Password';

  @override
  String get profileBiometric => 'Biometric Sign In';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get logoutButton => 'Log out';

  @override
  String get logoutTitle => 'Log out of PROMISE?';

  @override
  String get logoutMessage =>
      'Next time you\'ll sign in with your employee ID and password.';

  @override
  String get biometricEnableReason =>
      'Confirm it\'s you to turn on biometric sign-in';

  @override
  String get biometricEnableFailedTitle =>
      'Couldn\'t turn on biometric sign-in';

  @override
  String get biometricEnableFailedMessage =>
      'Your fingerprint or face wasn\'t confirmed. Please try again.';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get actionRetry => 'Try again';

  @override
  String get hrmsTitle => 'HRMS';

  @override
  String get hrmsSubtitle => 'My attendance and leave';

  @override
  String get hrmsNavAttendance => 'Attendance';

  @override
  String get hrmsNavLeave => 'Leave';

  @override
  String get hrmsNavTeam => 'Team';

  @override
  String get hrmsBackHome => 'Back to home';

  @override
  String get hrmsHistoryTooltip => 'Attendance history';

  @override
  String get shiftTodayLabel => 'Today\'s shift';

  @override
  String get shiftOnTime => 'Present · on time';

  @override
  String get shiftLate => 'Present · late';

  @override
  String get shiftCheckedOut => 'Checked out';

  @override
  String get shiftNotIn => 'Not checked in';

  @override
  String get shiftOnLeave => 'On leave';

  @override
  String get shiftAbsent => 'Absent';

  @override
  String get shiftHoursAtWork => 'hrs at work';

  @override
  String get shiftCheckIn => 'Check-in';

  @override
  String get shiftCheckOut => 'Check-out';

  @override
  String get shiftNotYet => 'Not yet';

  @override
  String get shiftActionCheckIn => 'Check in';

  @override
  String get shiftActionCheckOut => 'Check out';

  @override
  String shiftProgress(int percent) {
    return '$percent% of the shift done';
  }

  @override
  String get shiftLoadFailed => 'Couldn\'t load today\'s attendance.';

  @override
  String get workAreaInside => 'Inside work area';

  @override
  String get workAreaOutside => 'Outside work area';

  @override
  String get workAreaFinding => 'Finding you…';

  @override
  String get workAreaLoading => 'Loading your work area…';

  @override
  String get workAreaUnavailable => 'Work area unavailable';

  @override
  String get workAreaLocationOff => 'Location is off';

  @override
  String get workAreaLocationDenied => 'Location not allowed';

  @override
  String get workAreaFake => 'Fake location';

  @override
  String workAreaInsideDetail(String office, String distance) {
    return '$office · $distance from the office';
  }

  @override
  String workAreaOutsideDetail(String distance, String office) {
    return '$distance from $office · tap for the way';
  }

  @override
  String workAreaFindingDetail(String office) {
    return 'Checking you against $office';
  }

  @override
  String get workAreaLocationOffDetail => 'Turn it on to mark attendance';

  @override
  String get workAreaDeniedDetail => 'Allow it to mark attendance';

  @override
  String get workAreaFakeDetail => 'Turn off fake GPS apps to mark attendance';

  @override
  String get workAreaRetryDetail => 'Pull down to try again';

  @override
  String get workAreaYours => 'Your work area';

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(String km) {
    return '$km km';
  }

  @override
  String get hrmsApplyLeave => 'Apply leave';

  @override
  String hrmsLeaveDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leave days left',
      one: '1 leave day left',
      zero: 'No leave days left',
    );
    return '$_temp0';
  }

  @override
  String get hrmsAttendanceCard => 'Attendance';

  @override
  String hrmsDaysIn(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in $month',
      one: '1 day in $month',
      zero: 'No days in $month',
    );
    return '$_temp0';
  }

  @override
  String get hrmsLeaveBalance => 'Leave balance';

  @override
  String leaveOfTotal(String total) {
    return 'of $total';
  }

  @override
  String leaveRingLabel(String type, String left, String total) {
    return '$type: $left of $total days left';
  }

  @override
  String get leaveBalanceEmpty => 'No leave balances yet';

  @override
  String get leaveBalanceFailed => 'Couldn\'t load your leave balance.';

  @override
  String get hrmsMyRequests => 'My requests';

  @override
  String get leaveStatusPending => 'With manager';

  @override
  String get leaveStatusApproved => 'Approved';

  @override
  String get leaveStatusRejected => 'Rejected';

  @override
  String leaveRequestTitle(String type, String dates) {
    return '$type · $dates';
  }

  @override
  String leaveAppliedOn(String date) {
    return 'Applied $date';
  }

  @override
  String get leaveWaitingManager => 'Waiting for your manager';

  @override
  String get leaveRequestsEmpty => 'No requests yet';

  @override
  String get leaveRequestsFailed => 'Couldn\'t load your requests.';

  @override
  String get leaveRequestDetails => 'Leave request';

  @override
  String get leaveDetailType => 'Type';

  @override
  String get leaveDetailDates => 'Dates';

  @override
  String get leaveDetailStatus => 'Status';

  @override
  String get leaveDetailReason => 'Reason';

  @override
  String get leaveDetailApplied => 'Applied';

  @override
  String get leaveAllRequests => 'All requests';

  @override
  String get leaveTitle => 'Apply leave';

  @override
  String get leaveHistory => 'History';

  @override
  String get leaveTypeGroup => 'Leave type';

  @override
  String leaveLeftOf(String total) {
    return 'of $total left';
  }

  @override
  String get leavePickDates => 'Pick dates';

  @override
  String leaveDaysAfter(int days, String left) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 · $left left after';
  }

  @override
  String get leaveReason => 'Reason';

  @override
  String get leaveReasonHint => 'Say why, in a few words';

  @override
  String leaveReasonShort(int count) {
    return 'Write at least $count characters';
  }

  @override
  String get leaveGoesTo => 'Goes to your reporting manager for approval';

  @override
  String get leaveSend => 'Send request';

  @override
  String get leaveSending => 'Sending…';

  @override
  String get leaveSentTitle => 'Request sent';

  @override
  String get leaveSendFailedTitle => 'Couldn\'t send the request';

  @override
  String get leavePickTypeError => 'Pick a leave type';

  @override
  String get leavePickDatesError => 'Pick the days of your leave';

  @override
  String get leaveTypesFailed => 'Couldn\'t load the leave types.';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceOnTime => 'On time';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceLeave => 'Leave';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceWeekend => 'Weekend';

  @override
  String get attendancePickMonth => 'Pick a month';

  @override
  String attendanceIn(String time) {
    return 'In $time';
  }

  @override
  String attendanceOut(String time) {
    return 'Out $time';
  }

  @override
  String attendanceWorked(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get attendanceNothingMarked => 'Nothing marked this day';

  @override
  String get attendanceFailed => 'Couldn\'t load attendance.';

  @override
  String attendanceDayLabel(String date, String status) {
    return '$date: $status';
  }

  @override
  String get attendanceNoMark => 'not marked';

  @override
  String get teamTitle => 'My team';

  @override
  String teamPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get teamMarkAttendance => 'Mark a team member\'s attendance';

  @override
  String teamYouAreIn(String time, String duration) {
    return 'You\'re in since $time · $duration';
  }

  @override
  String get teamYouAreOut => 'You\'re not checked in';

  @override
  String get teamToday => 'Team today';

  @override
  String teamUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get teamStatusIn => 'In';

  @override
  String get teamStatusLate => 'Late';

  @override
  String get teamStatusLeave => 'Leave';

  @override
  String get teamStatusAbsent => 'Absent';

  @override
  String get teamStatusTotal => 'Total';

  @override
  String teamBarLabel(int present, int late, int leave, int absent) {
    return '$present in, $late late, $leave on leave, $absent absent';
  }

  @override
  String get teamRightNow => 'Team right now';

  @override
  String teamAll(int count) {
    return 'All $count';
  }

  @override
  String get teamMembers => 'Team members';

  @override
  String get teamSearchHint => 'Search by name or ID';

  @override
  String get teamNobody => 'No one here';

  @override
  String get teamMembersFailed => 'Couldn\'t load the team.';

  @override
  String memberIn(String time) {
    return 'In $time';
  }

  @override
  String memberLate(String time) {
    return 'Late $time';
  }

  @override
  String get memberOnLeave => 'On leave';

  @override
  String get memberAbsent => 'Absent';

  @override
  String get memberNotMarked => 'Not marked';

  @override
  String get memberProfile => 'Team member';

  @override
  String get memberEmployeeId => 'Employee ID';

  @override
  String get memberDesignation => 'Designation';

  @override
  String get memberDepartment => 'Department';

  @override
  String get memberDivision => 'Division';

  @override
  String get memberLocation => 'Location';

  @override
  String get memberShift => 'Shift';

  @override
  String get memberPhone => 'Phone';

  @override
  String get memberEmail => 'Email';

  @override
  String get memberAtWork => 'At work';

  @override
  String get memberMoreDetails => 'More details';

  @override
  String get memberMarkAttendance => 'Mark attendance';

  @override
  String get cnicRetake => 'Retake';

  @override
  String get cnicCameraFailed => 'Couldn\'t open the camera. Try again.';

  @override
  String get cnicStepFace => 'Face';

  @override
  String get cnicStepCnic => 'CNIC';

  @override
  String get cnicStepDone => 'Done';

  @override
  String cnicStepOf(int current, int total, String name) {
    return 'Step $current of $total: $name';
  }

  @override
  String get registerIntroTitle => 'Set up face check-in';

  @override
  String get gateCheckingTitle => 'Checking your location';

  @override
  String get gateCheckingMessage => 'Making sure you are at your office…';

  @override
  String get gateNotAllowedTitle => 'Not allowed';

  @override
  String get gateFakeLocationTitle => 'Fake location';

  @override
  String get othersTitle => 'Mark attendance';

  @override
  String get othersSubtitle => 'For someone on your team';

  @override
  String get othersEmployeeIdHint => 'e.g. 100234';

  @override
  String get othersEmployeeIdRequired => 'Enter an employee ID';

  @override
  String get faceCaptureFailedTitle => 'Face capture failed';

  @override
  String get livenessFailedTitle => 'Liveness check failed';

  @override
  String get faceIncompleteTitle => 'Face capture incomplete';

  @override
  String get faceIncompleteMessage =>
      'Not enough clear photos were taken. Try again in good light.';

  @override
  String get faceRegisteredTitle => 'Face registered';

  @override
  String get faceRegisteredMessage => 'The face is registered.';

  @override
  String get registrationFailedTitle => 'Registration failed';

  @override
  String get verificationFailedTitle => 'Verification failed';

  @override
  String get locationErrorTitle => 'Couldn\'t get the location';

  @override
  String get locationErrorMessage =>
      'Turn on location and allow the app to use it, then try again.';

  @override
  String get markFailedTitle => 'Something went wrong';

  @override
  String get markFailedMessage => 'Couldn\'t mark the attendance. Try again.';

  @override
  String get memberSapId => 'SAP ID';

  @override
  String get memberRank => 'Rank';

  @override
  String get memberSubSection => 'Sub-section';

  @override
  String get memberRole => 'Role';

  @override
  String get memberJoined => 'Joined';

  @override
  String get memberReportsTo => 'Reports to';

  @override
  String get memberEmployment => 'Employment';

  @override
  String teamMonthChanges(int joined, int left) {
    return '$joined joined · $left left this month';
  }

  @override
  String teamRestDay(int count) {
    return '$count on a rest day';
  }

  @override
  String get mapRecenter => 'Centre on me';

  @override
  String get mapUpdatedNow => 'Updated just now';

  @override
  String mapUpdatedMinutes(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String mapYouAreAt(String office) {
    return 'You\'re at $office';
  }

  @override
  String mapOtherOffice(String office) {
    return 'Attendance is marked where you are. To mark it at $office, go there first.';
  }

  @override
  String mapOutsideMessage(String distance, String office) {
    return 'Go $distance to $office to mark attendance. Follow the line.';
  }

  @override
  String get mapLoadingMessage =>
      'Getting the offices you may mark attendance at.';

  @override
  String get mapFailedTitle => 'Couldn\'t load your work area';

  @override
  String get mapLocationOffMessage =>
      'Turn on location to see where you are and mark attendance.';

  @override
  String get mapDeniedTitle => 'Location permission needed';

  @override
  String get mapDeniedMessage =>
      'Allow location so the app can check you are at work.';

  @override
  String get mapFindingMessage =>
      'Stay where the sky is visible for a better fix.';

  @override
  String get mapFromOffice => 'from office';

  @override
  String get mapAccuracy => 'GPS accuracy';

  @override
  String get mapRange => 'allowed range';

  @override
  String mapAccuracyValue(int meters) {
    return '±$meters m';
  }

  @override
  String get mapTurnOnLocation => 'Turn on location';

  @override
  String get mapAllowLocation => 'Allow location';

  @override
  String mapMarkInstead(String office) {
    return 'Mark at $office instead';
  }

  @override
  String mapContinueAt(String office) {
    return 'Continue at $office';
  }

  @override
  String get mapMarkHere => 'Mark attendance here';

  @override
  String get mapMarkInside => 'Mark attendance inside the area';

  @override
  String get mapYouAreHere => 'You are here';

  @override
  String mapAway(String distance) {
    return '$distance away';
  }

  @override
  String mapAreaSize(int meters) {
    return '$meters m area';
  }

  @override
  String get profileSectionAppearance => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSystem => 'System';

  @override
  String get registerSubtitle => 'Two quick steps, then you can check in';

  @override
  String registerOthersSubtitle(String id) {
    return 'Two quick steps for employee $id';
  }

  @override
  String get registerFaceTitle => 'Register the face';

  @override
  String get registerFaceDetail =>
      'The camera takes a few photos of the face. Hold the phone at eye level, in good light.';

  @override
  String get registerFaceAction => 'Start face scan';

  @override
  String get registerFaceDone => 'Face photos taken';

  @override
  String get registerCnicTitle => 'Upload the CNIC';

  @override
  String get registerCnicDetail =>
      'Photograph the front of the CNIC, fitted inside the frame.';

  @override
  String get registerCnicDone => 'CNIC photo taken';

  @override
  String get registerCnicLocked => 'Finish step 1 first';

  @override
  String registerStep(int number) {
    return 'Step $number';
  }

  @override
  String registerAttachmentsFailed(String reason) {
    return 'The CNIC and face photos couldn\'t be sent, so nothing was registered. $reason';
  }

  @override
  String get registerProceed => 'Proceed';

  @override
  String get registerProceeding => 'Registering…';

  @override
  String get registerPrivacy =>
      'The photos are used only to recognise this person at check-in.';

  @override
  String get faceTitleVerify => 'Face check-in';

  @override
  String get faceTitleRegister => 'Register the face';

  @override
  String get faceStepLocation => 'Location';

  @override
  String get faceTipTitle => 'Hold the phone at eye level';

  @override
  String get faceTipDetail =>
      'Straight in front of your face, not from below the chin';

  @override
  String get faceFooter => 'It takes the photo by itself when you hold still.';

  @override
  String get faceCameraFailed => 'Couldn\'t open the camera.';

  @override
  String get faceCheckArea => 'At your work area';

  @override
  String get faceCheckLive => 'Live person';

  @override
  String get faceCheckDevice => 'Device secure';

  @override
  String get faceHintLook => 'Look at the camera';

  @override
  String get faceHintStraight => 'Look straight at the camera';

  @override
  String get faceHintEyeLevel => 'Hold the phone at eye level';

  @override
  String get faceHintNoFace => 'Put your face inside the oval';

  @override
  String get faceHintMultiple => 'Only one person in the frame';

  @override
  String get faceHintEyes => 'Open your eyes and look at the camera';

  @override
  String get faceHintCovered => 'Uncover your face';

  @override
  String get faceHintFar => 'Move closer';

  @override
  String get faceHintClose => 'Move back a little';

  @override
  String get faceHintSteady => 'Hold the phone steady';

  @override
  String get faceHintDark => 'Move to better light';

  @override
  String get faceHintBright => 'Too much light on your face';

  @override
  String get faceHintObject => 'Keep objects away from your face';

  @override
  String get faceHintCapturing => 'Face found · hold still';

  @override
  String get teamGroupIn => 'At work';

  @override
  String get teamGroupLate => 'Came late';

  @override
  String get teamGroupLeave => 'On leave';

  @override
  String get teamGroupAbsent => 'Absent';

  @override
  String get teamGroupOther => 'Not marked';

  @override
  String teamGroupCount(String group, int count) {
    return '$group · $count';
  }

  @override
  String teamSheetSubtitle(String people, String time) {
    return '$people · updated $time';
  }

  @override
  String get actionClear => 'Clear';

  @override
  String get teamMarkTitle => 'Mark your team\'s attendance';

  @override
  String get teamMarkSubtitle =>
      'With their face, or register a new face and CNIC';

  @override
  String teamViewAll(int count) {
    return 'View all $count members';
  }

  @override
  String teamInToday(int percent) {
    return '$percent%';
  }

  @override
  String get teamInTodayLabel => 'in today';

  @override
  String teamInTodaySemantics(int percent) {
    return '$percent% of the team is in today';
  }

  @override
  String get logoutSubtitle =>
      'You\'ll sign in again with your employee ID and password';

  @override
  String get poweredByLead => 'Designed & Developed by';

  @override
  String get poweredByName => 'One Network';

  @override
  String get leaveLeftShort => 'left';

  @override
  String leaveUsed(String days) {
    return '$days used';
  }

  @override
  String get attendanceRecords => 'Records';

  @override
  String attendanceViewAll(int count) {
    return 'View all $count';
  }

  @override
  String get attendanceShowLess => 'Show less';

  @override
  String get attendanceNoRecords => 'No records here';

  @override
  String get othersTeam => 'Your team';

  @override
  String othersTeamCount(int count) {
    return 'Your team · $count';
  }

  @override
  String get othersTeamSearch => 'Search by name, ID or designation';

  @override
  String get othersTeamEmpty => 'No one on your team yet';

  @override
  String get othersTeamNoMatch => 'No one matches';

  @override
  String get othersTeamFailed => 'Couldn\'t load your team.';

  @override
  String get othersFirstTimeNote =>
      'Pick someone below or type their ID. If their face isn\'t registered yet, you\'ll register it with their CNIC first.';

  @override
  String get inspSubtitle => 'Digital Inspection of Assets';

  @override
  String get inspFootplate => 'Footplate';

  @override
  String get inspStation => 'Station';

  @override
  String get inspMotorTrolley => 'Motor Trolley';

  @override
  String get inspLocomotive => 'Locomotive';

  @override
  String get inspElectrical => 'Electrical (RTL)';

  @override
  String get inspFootplateAbout => 'Day and night, from the cab';

  @override
  String get inspStationAbout => 'Premises, signals and facilities';

  @override
  String get inspMotorTrolleyAbout => 'Track patrol by trolley';

  @override
  String get inspLocomotiveAbout => 'Condition of the loco';

  @override
  String get inspElectricalAbout => 'Electrical assets';

  @override
  String inspPlan(String month) {
    return '$month plan';
  }

  @override
  String inspDue(String date) {
    return 'Due $date';
  }

  @override
  String get inspDone => 'done';

  @override
  String inspDoneOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get inspCompleted => 'Completed';

  @override
  String get inspPending => 'Pending';

  @override
  String get inspOverdue => 'Overdue';

  @override
  String get inspExtra => 'Extra';

  @override
  String get inspContinue => 'Continue where you left off';

  @override
  String get inspStart => 'Start an inspection';

  @override
  String get inspDrafts => 'Drafts';

  @override
  String get inspDraft => 'Draft';

  @override
  String inspSaved(String when) {
    return 'Saved $when';
  }

  @override
  String get inspResume => 'Resume';

  @override
  String get inspDeleteDraft => 'Delete draft';

  @override
  String get inspDeleteDraftTitle => 'Delete this draft?';

  @override
  String get inspDeleteDraftMessage =>
      'What was filled in so far will be lost.';

  @override
  String get pramsSubtitle => 'Accident Management System';

  @override
  String get pramsSearch => 'Search train, location or status';

  @override
  String get pramsAll => 'All';

  @override
  String get pramsCritical => 'Critical';

  @override
  String get pramsModerate => 'Moderate';

  @override
  String get pramsMinor => 'Minor';

  @override
  String get pramsLoadFailed => 'Couldn\'t load the cases';

  @override
  String get pramsNoCases => 'No accidents reported';

  @override
  String get pramsNoCasesMessage =>
      'Cases you report show here with their progress.';

  @override
  String get pramsNoMatch => 'Nothing matches';

  @override
  String get pramsNoMatchMessage => 'Try another train, place or severity.';

  @override
  String get pramsReportTitle => 'Report an accident';

  @override
  String get pramsReportSubtitle =>
      'Location and details go straight to control';

  @override
  String get pramsReportAction => 'Report accident';

  @override
  String get pramsThisMonth => 'This month';

  @override
  String get pramsOpen => 'Open';

  @override
  String get pramsInvestigating => 'Investigating';

  @override
  String get pramsClosed => 'Closed';

  @override
  String pramsWeeks(String counts) {
    return 'Cases per week: $counts';
  }

  @override
  String pramsUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String pramsKm(String km) {
    return 'KM $km';
  }

  @override
  String get pramsStageReported => 'Reported';

  @override
  String get pramsStageAcknowledged => 'Acknowledged';

  @override
  String get pramsStageRelief => 'Relief';

  @override
  String get pramsStageCleared => 'Cleared';

  @override
  String pramsStageOf(int step, int total, String name) {
    return 'Step $step of $total: $name';
  }

  @override
  String get reportTitle => 'Report accident';

  @override
  String get reportSubtitle => 'Goes to control the moment you submit';

  @override
  String get reportStepTrain => 'Train';

  @override
  String get reportStepWhat => 'What happened';

  @override
  String get reportStepPhotos => 'Photos';

  @override
  String get reportLocating => 'Finding your location';

  @override
  String get reportLocatingDetail => 'It goes with the report';

  @override
  String get reportLocated => 'Location captured';

  @override
  String reportLocatedDetail(String lat, String lon, int metres) {
    return '$lat, $lon · accurate to $metres m';
  }

  @override
  String get reportNotLocated => 'Couldn\'t find your location';

  @override
  String get reportNotLocatedDetail => 'Turn on location and try again';

  @override
  String get reportAuto => 'Auto';

  @override
  String get reportTrainAndPlace => 'Train and place';

  @override
  String get reportTrain => 'Train';

  @override
  String get reportPickTrainHint => 'Select the train';

  @override
  String get reportPickTrain => 'Select the train';

  @override
  String get reportPickTrainSubtitle => 'Trains running near your location';

  @override
  String get reportSearchTrains => 'Train name or number';

  @override
  String reportAway(String km) {
    return '$km km away';
  }

  @override
  String reportUseTrain(String train) {
    return 'Use $train';
  }

  @override
  String get reportNoTrains => 'No train matches';

  @override
  String get reportLocomotive => 'Locomotive';

  @override
  String get reportKilometre => 'Kilometre';

  @override
  String get reportLastStation => 'Last station';

  @override
  String get reportFromTrain => 'From train';

  @override
  String get reportDivision => 'Division';

  @override
  String get reportSection => 'Section';

  @override
  String get reportBlockSection => 'Block section';

  @override
  String get reportWhen => 'Date and time';

  @override
  String get reportPick => 'Select';

  @override
  String get reportWhatHappened => 'What happened';

  @override
  String get reportSeverityFromType => 'set from the type';

  @override
  String get reportConditions => 'Conditions';

  @override
  String get reportDerailed => 'Train derailed';

  @override
  String get reportDerailedAbout => 'One or more vehicles off the track';

  @override
  String get reportFire => 'Fire involved';

  @override
  String get reportFireAbout => 'Fire or explosion at the site';

  @override
  String get reportInjured => 'People injured';

  @override
  String get reportInjuredAbout => 'Passengers or staff hurt';

  @override
  String get reportDangerousGoods => 'Dangerous goods';

  @override
  String get reportDangerousGoodsAbout => 'Hazardous cargo on board';

  @override
  String get reportFewer => 'Fewer';

  @override
  String get reportMore => 'More';

  @override
  String get reportRemarks => 'Remarks';

  @override
  String get reportPhotos => 'Photos';

  @override
  String reportPhotoN(int n) {
    return 'Photo $n';
  }

  @override
  String get reportAddPhoto => 'Add photo';

  @override
  String get reportTakePhoto => 'Take a photo';

  @override
  String get reportChoosePhotos => 'Choose from gallery';

  @override
  String get reportRemovePhoto => 'Remove this photo?';

  @override
  String get reportRemove => 'Remove';

  @override
  String get reportReset => 'Reset';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportMissingTitle => 'A little more first';

  @override
  String get reportMissingMessage =>
      'Select the train, what happened, and the date and time.';

  @override
  String get reportFailedTitle => 'Couldn\'t send the report';

  @override
  String get reportFailedMessage => 'Please try again.';

  @override
  String get verificationInProgressTitle => 'Verification In Progress';

  @override
  String get verificationInProgressMessage =>
      'Your data has been submitted. Please wait for admin approval.';

  @override
  String get shiftRegisterFace => 'Register face';

  @override
  String get loading => 'Loading';

  @override
  String get locRefresh => 'Refresh location';

  @override
  String get locFindingShort => 'Finding you…';

  @override
  String get locFinding => 'Finding your exact location…';

  @override
  String get locFindingDetail => 'Stay where you are for a moment.';

  @override
  String get locFailed => 'Couldn\'t find your location';

  @override
  String get locFailedDetail =>
      'Move near a window or outside, then try again.';

  @override
  String get locUpdated => 'Location updated just now';

  @override
  String get locUpdatedDetail => 'This is where you are now.';

  @override
  String get locOutside => 'Not where you are?';

  @override
  String get locOutsideDetail =>
      'If you\'re inside your office, tap Refresh location to update where you are.';

  @override
  String locStale(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Location from $minutes min ago',
      one: 'Location from 1 min ago',
    );
    return '$_temp0';
  }

  @override
  String get locStaleDetail =>
      'Tap Refresh location so it shows where you are now.';

  @override
  String locRough(int metres) {
    return 'Location is rough (±$metres m)';
  }

  @override
  String get locRoughDetail =>
      'Tap Refresh location, or move near a window or outside.';

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get profilePhotoSubtitle => 'Kept on this phone only';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoCamera => 'Take a photo';

  @override
  String get profilePhotoGallery => 'Choose from gallery';

  @override
  String get profilePhotoAvatar => 'Choose an avatar';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoFailed => 'Couldn\'t use that photo. Try another.';

  @override
  String get emojiPickerTitle => 'Choose an avatar';

  @override
  String get emojiGroupSmileys => 'Smileys & people';

  @override
  String get emojiGroupAnimals => 'Animals & nature';

  @override
  String get emojiGroupFood => 'Food & drink';

  @override
  String get emojiGroupActivities => 'Activity';

  @override
  String get emojiGroupTravel => 'Travel & places';

  @override
  String get emojiGroupObjects => 'Objects';

  @override
  String get emojiGroupSymbols => 'Symbols';

  @override
  String get emojiGroupFlags => 'Flags';

  @override
  String get profileSectionText => 'Text';

  @override
  String get textSizeTitle => 'Text size';

  @override
  String get textSizeSmall => 'Small';

  @override
  String get textSizeDefault => 'Default';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeLargest => 'Largest';

  @override
  String get textPreviewMessage =>
      'Assalam-o-Alaikum! This is how text will look across PROMISE.';

  @override
  String get textPreviewTime => '9:41';

  @override
  String get textBold => 'Bold text';

  @override
  String get textBoldDetail => 'Heavier letters that are easier to read';

  @override
  String get textSizeLarger => 'Larger';

  @override
  String get textPreviewReply => 'Walaikum Assalam! It\'s easy to read now.';

  @override
  String get emojiUse => 'Use this avatar';

  @override
  String get emojiBackground => 'Background';

  @override
  String get emojiPickPrompt => 'Pick an emoji below';

  @override
  String get avatarTintJade => 'Jade';

  @override
  String get avatarTintGold => 'Gold';

  @override
  String get avatarTintSky => 'Sky';

  @override
  String get avatarTintRose => 'Rose';

  @override
  String get avatarTintSand => 'Sand';

  @override
  String get profileAppVersion => 'App Version';

  @override
  String get messageSuccessTitle => 'Done';

  @override
  String get messageErrorTitle => 'Something went wrong';

  @override
  String get messageWarningTitle => 'Please check';

  @override
  String get messageInfoTitle => 'Good to know';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get teamLoadFailedTitle => 'Couldn\'t load your team';

  @override
  String get teamLoadFailedMessage =>
      'Check your connection, then refresh to try again.';

  @override
  String get profileTextDisplay => 'Font & Display Size';

  @override
  String profileTextDisplayDetail(String display, String text) {
    return '$display display · $text text';
  }

  @override
  String get displaySizeTitle => 'Display size';

  @override
  String get displaySizeStandard => 'Default';

  @override
  String get displaySizeLarge => 'Large';

  @override
  String get displaySizeStandardDetail => 'More on screen';

  @override
  String get displaySizeLargeDetail => 'Everything larger';

  @override
  String get displaySizeFooter =>
      'Display size makes everything larger, buttons and icons too. Text size changes only the words.';

  @override
  String get leaveFrom => 'From';

  @override
  String get leaveTo => 'To';

  @override
  String get leaveNoDay => 'Pick a day';

  @override
  String get leavePickFirstDay => 'Tap the first day of your leave';

  @override
  String get leavePickLastDay => 'Now tap the last day (same day for one day)';

  @override
  String get dateTimeDone => 'Done';

  @override
  String get dateTimeTime => 'Time';

  @override
  String get attReportTitle => 'Attendance report';

  @override
  String get attReportTeamTitle => 'Team attendance';

  @override
  String attReportGenerated(String when) {
    return 'Generated $when';
  }

  @override
  String attReportGeneratedBy(String name) {
    return 'Generated by $name';
  }

  @override
  String attReportPage(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get attReportEmployeeId => 'Employee ID';

  @override
  String get attReportDesignation => 'Designation';

  @override
  String get attReportDepartment => 'Department';

  @override
  String get attReportDivision => 'Division';

  @override
  String get attReportLocation => 'Location';

  @override
  String get attReportShift => 'Shift';

  @override
  String get attReportPresent => 'Present';

  @override
  String get attReportDaysOff => 'Days off';

  @override
  String get attReportRate => 'Attendance rate';

  @override
  String get attReportHours => 'Hours worked';

  @override
  String get attReportWorkingDays => 'Working days';

  @override
  String get attReportGlance => 'At a glance';

  @override
  String get attReportDaily => 'Daily record';

  @override
  String get attReportDate => 'Date';

  @override
  String get attReportDay => 'Day';

  @override
  String get attReportStatus => 'Status';

  @override
  String get attReportCheckIn => 'Check-in';

  @override
  String get attReportCheckOut => 'Check-out';

  @override
  String get attReportWorked => 'Worked';

  @override
  String get attReportLeaves => 'Leaves';

  @override
  String get attReportLeaveType => 'Leave type';

  @override
  String get attReportDays => 'Days';

  @override
  String get attReportAppliedOn => 'Applied on';

  @override
  String get attReportRemarks => 'Remarks';

  @override
  String get attReportNoLeaves => 'No leaves in this period.';

  @override
  String get attReportLoadFailed =>
      'This person\'s attendance couldn\'t be loaded.';

  @override
  String attReportMembers(int count) {
    return '$count people';
  }

  @override
  String get attReportName => 'Name';

  @override
  String get attReportFooter => 'PROMISE · Pakistan Railways';

  @override
  String get downloadTitle => 'Download attendance';

  @override
  String get downloadMonthly => 'Monthly';

  @override
  String get downloadRange => 'Date range';

  @override
  String get downloadOnlyMe => 'Only me';

  @override
  String get downloadMyTeam => 'My team';

  @override
  String get downloadSelectAll => 'Select all';

  @override
  String downloadSelected(int count, int total) {
    return '$count of $total selected';
  }

  @override
  String get downloadPickPeople => 'Pick at least one person';

  @override
  String get downloadPickRange => 'Pick the first and last day';

  @override
  String get downloadButton => 'Download PDF';

  @override
  String downloadPreparing(int done, int total) {
    return 'Preparing $done of $total…';
  }

  @override
  String get downloadSavedTitle => 'Saved to Downloads';

  @override
  String downloadSavedMessage(String name) {
    return '$name is in Downloads › PROMISE.';
  }

  @override
  String get downloadOpen => 'Open';

  @override
  String get downloadShare => 'Share';

  @override
  String get downloadFailed => 'Couldn\'t save the PDF. Try again.';

  @override
  String get downloadNeedsStorage => 'Allow storage so the PDF can be saved.';

  @override
  String get downloadNoViewer => 'No app on this phone opens PDFs.';

  @override
  String get downloadSearch => 'Search team';

  @override
  String get attReportPeople => 'People';

  @override
  String get downloadCardTitle => 'Download attendance';

  @override
  String get downloadCardMessage =>
      'Save your attendance on your phone as a PDF file, with your leaves.';

  @override
  String get downloadTeamCardTitle => 'Download team attendance';

  @override
  String get downloadTeamCardMessage =>
      'Save a PDF of your whole team, or pick only the people you need.';

  @override
  String get downloadTagAnyDates => 'Any dates';

  @override
  String get downloadTagLeaves => 'With leaves';

  @override
  String get downloadIntro =>
      'Choose the dates, then tap Download PDF. The file is saved in your phone\'s Downloads.';

  @override
  String get downloadStepDates => '1 · Which dates?';

  @override
  String get downloadStepWhose => '2 · Whose attendance?';

  @override
  String get identityTitle => 'Verify your identity';

  @override
  String get identitySubtitle => 'Scan the front of your CNIC to continue.';

  @override
  String get identityStepMobile => 'Mobile';

  @override
  String get identityStepCnic => 'CNIC';

  @override
  String get identityChangeNumber => 'Change';

  @override
  String get cnicCardTitle => 'Pakistani CNIC';

  @override
  String get cnicCardTap => 'Tap to scan your CNIC';

  @override
  String get cnicCardAi => 'Checked on this phone by on-device AI';

  @override
  String get cnicScanAgain => 'Scan again';

  @override
  String get cnicVerified => 'Verified';

  @override
  String get cnicLiveBadge => 'AI scan';

  @override
  String get cnicHintStarting => 'Starting the camera…';

  @override
  String get cnicHintPlace => 'Fit the front of your CNIC inside the frame';

  @override
  String get cnicHintLooking => 'Looking for a CNIC…';

  @override
  String get cnicHintCloser => 'Bring your CNIC closer to fill the frame';

  @override
  String get cnicHintHold => 'CNIC found. Hold steady and tap capture';

  @override
  String get cnicCapture => 'Capture CNIC';

  @override
  String get cnicHintBank => 'That\'s a bank card, not a CNIC';

  @override
  String get cnicHintOther => 'That card isn\'t a CNIC';

  @override
  String get cnicHintReading => 'Checking your CNIC…';

  @override
  String get cnicHintVerified => 'CNIC verified';

  @override
  String get cnicTorchOn => 'Turn the light on';

  @override
  String get cnicTorchOff => 'Turn the light off';

  @override
  String get cnicWrongBankTitle => 'That\'s a bank card';

  @override
  String get cnicWrongBankMessage =>
      'Bank, debit and credit cards can\'t be used. Scan your Pakistani CNIC or NICOP instead.';

  @override
  String get cnicWrongCardTitle => 'That isn\'t a CNIC';

  @override
  String get cnicWrongCardMessage =>
      'This looks like another card, such as a licence, passport or office card. Only a Pakistani CNIC or NICOP can be scanned.';

  @override
  String get cnicNotCnicMessage =>
      'Only a Pakistani CNIC or NICOP can be scanned. Hold the front of the card, the side with your photo, inside the frame.';

  @override
  String get cnicNothingTitle => 'No CNIC found';

  @override
  String get cnicNothingMessage =>
      'We couldn\'t see a Pakistani CNIC clearly in the photo. Fit the front of your CNIC or NICOP, the side with your photo, inside the frame, hold steady in good light and capture again.';

  @override
  String get cnicFlash => 'Flash';

  @override
  String get cnicHintDark => 'Too dark. Switch the flash on';

  @override
  String get cnicHintDarkFlashOn => 'Still too dark. Move to more light';

  @override
  String get cnicHintBlurry => 'Hold steady. The picture is blurred';

  @override
  String get inspGateTitle => 'Verify your face to start';

  @override
  String get inspGateMessage =>
      'Your face is checked now and again before you submit, so every report is signed by the person who made it.';

  @override
  String get inspGateCheckLive => 'A live face, not a photo';

  @override
  String get inspGateCheckMatch => 'Matched to your registered face';

  @override
  String get inspGateCheckStamp => 'Time and place noted on the report';

  @override
  String get inspGateStart => 'Verify and start';

  @override
  String get inspStepVerify => 'Verify';

  @override
  String get inspStepStart => 'Start';

  @override
  String get inspStepReview => 'Review';

  @override
  String get inspStepSubmit => 'Submit';

  @override
  String get inspVerifying => 'Verifying your face…';

  @override
  String get inspVerifiedTitle => 'Face verified';

  @override
  String get inspVerifyFailedTitle => 'Face not verified';

  @override
  String get inspNotRegistered =>
      'Your face isn\'t registered yet. Register it from Attendance in HRMS, then try again.';

  @override
  String get inspRegistrationPending =>
      'Your face registration is waiting for approval. You can inspect once it is approved.';

  @override
  String get inspVerifyFailed =>
      'Your face couldn\'t be verified. Try again in good light.';

  @override
  String get inspReviewTitle => 'Review and submit';

  @override
  String get inspReviewLead =>
      'This is the report as it will be submitted. Read it through before you confirm.';

  @override
  String get inspReviewPreparing => 'Preparing the report…';

  @override
  String inspReviewPage(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get inspReviewConfirm => 'The report is correct';

  @override
  String get inspReviewConfirmed => 'You confirmed the report';

  @override
  String get inspReviewEdit => 'Back to the form';

  @override
  String get inspReviewVerify => 'Verify face to submit';

  @override
  String inspReviewVerified(String time) {
    return 'Verified at $time';
  }

  @override
  String get inspSubmit => 'Submit inspection';

  @override
  String get inspSubmitting => 'Submitting…';

  @override
  String get inspSubmittedTitle => 'Inspection submitted';

  @override
  String get inspSubmittedMessage => 'Your report has been submitted.';

  @override
  String get inspSubmitFailedTitle => 'Couldn\'t submit';

  @override
  String get inspSavePdf => 'Save PDF';

  @override
  String get inspPdfSaved => 'Saved to Downloads';

  @override
  String get inspPdfSaveFailed => 'The PDF couldn\'t be saved.';

  @override
  String get inspPdfInspector => 'Inspector';

  @override
  String get inspPdfDate => 'Date';

  @override
  String get inspPdfStartVerified => 'Face verified at start';

  @override
  String get inspPdfSubmitVerified => 'Face verified at submission';

  @override
  String get inspPdfNotVerified => 'Not yet verified';

  @override
  String get inspPdfLocation => 'Location';

  @override
  String get inspPdfPhotos => 'Photos';

  @override
  String get inspPdfFooter => 'e-Inspection report';

  @override
  String get inspPdfUnanswered => 'Not answered';

  @override
  String get inspPdfAnswered => 'Answered';

  @override
  String get inspPdfFindings => 'Findings';

  @override
  String get inspFormNext => 'Next';

  @override
  String get inspFormReview => 'Review and submit';

  @override
  String get inspFormSelect => 'Select';

  @override
  String get inspFormSelectDate => 'Select date';

  @override
  String get inspFormPickDate => 'Pick a date';

  @override
  String get inspFormDone => 'Done';

  @override
  String get inspFormRemarkLabel => 'Remarks';

  @override
  String get inspFormRemarkHint => 'Describe what is wrong';

  @override
  String inspFormOutOfRange(String hint) {
    return 'Outside the expected range: $hint';
  }

  @override
  String inspFormLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions left',
      one: '1 question left',
      zero: 'All answered',
    );
    return '$_temp0';
  }

  @override
  String inspFormProgress(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String inspFormStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get inspFormLeaveTitle => 'Leave this inspection?';

  @override
  String get inspFormLeaveDraft =>
      'Your answers are kept as a draft on this phone, to finish later.';

  @override
  String get inspFormLeaveLost => 'What you\'ve filled in will be lost.';

  @override
  String get inspFormLeave => 'Leave';

  @override
  String get inspFormStay => 'Keep going';

  @override
  String get inspFormBlankTitle => 'Some questions are blank';

  @override
  String inspFormBlankMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions are still blank.',
      one: '1 question is still blank.',
    );
    return '$_temp0 Answer them first, or review the report with them left blank.';
  }

  @override
  String get inspFormShowBlank => 'Show me';

  @override
  String get inspFormReviewAnyway => 'Review anyway';

  @override
  String get inspFormRequiredTitle => 'Fill these in first';

  @override
  String get inspFormDecrease => 'Fewer';

  @override
  String get inspFormIncrease => 'More';

  @override
  String inspFormAddRow(String item) {
    return 'Add $item';
  }

  @override
  String get inspFormRemoveRow => 'Remove';

  @override
  String get inspFormRemoveRowTitle => 'Remove this entry?';

  @override
  String get inspFormTotal => 'Total';

  @override
  String get inspFormDetails => 'Details';

  @override
  String get inspFormStation => 'Station';

  @override
  String get inspFormStationHint => 'Choose the station';

  @override
  String get inspFormDate => 'Date of inspection';

  @override
  String get inspFormStationsFailed => 'Your stations couldn\'t be loaded.';

  @override
  String get inspFormNoStations => 'No stations are assigned to you yet.';

  @override
  String get inspFormSaved => 'Saved on this phone';

  @override
  String get inspFormPhotos => 'Photos';

  @override
  String get inspFormAddPhoto => 'Add photo';

  @override
  String get inspFormNote => 'Note';

  @override
  String get inspFormNoteHint => 'Anything else to record';

  @override
  String get inspFormAllGood => 'All satisfactory';

  @override
  String get inspFormNoExtinguishers =>
      'Set how many extinguishers there are to add a filling date for each.';

  @override
  String get inspFormRowEmpty => 'Nothing filled in yet';

  @override
  String get inspStationTitle => 'Station inspection';

  @override
  String get inspStationSubtitle => 'Signal and telecom';
}
