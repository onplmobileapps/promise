import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Product name, shown as the app title and in the wordmark's alt text.
  ///
  /// In en, this message translates to:
  /// **'PROMISE'**
  String get appName;

  /// What PROMISE stands for.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Railway Operational and Management Integrated Services Ecosystem'**
  String get appFullName;

  /// The organisation that runs the app.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Railways'**
  String get organisationName;

  /// Screen reader label for the PROMISE emblem image.
  ///
  /// In en, this message translates to:
  /// **'PROMISE emblem'**
  String get appEmblemLabel;

  /// Line under the wordmark on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Railway Operational and Management Integrated Services Ecosystem'**
  String get splashTagline;

  /// Credit line at the bottom of the sign-in screens.
  ///
  /// In en, this message translates to:
  /// **'Designed and developed by One Network'**
  String get poweredBy;

  /// Under the credit line; year is this year.
  ///
  /// In en, this message translates to:
  /// **'© {year} All rights reserved'**
  String copyrightNotice(int year);

  /// Button that closes a message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// Button that dismisses a choice without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Button or tooltip that closes a sheet or dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Button that acknowledges an explanation.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// Button that moves to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Button that sends a form.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// Tooltip of the back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Title of the sheet shown when a newer app version is in the store.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// Body of the update sheet.
  ///
  /// In en, this message translates to:
  /// **'A newer version of PROMISE is available. Update now to get the latest security fixes and features.'**
  String get updateAvailableMessage;

  /// The store version on the update sheet.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String updateAvailableVersion(String version);

  /// Button that opens the store page.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Sign-in tab for train tracking, by mobile number.
  ///
  /// In en, this message translates to:
  /// **'TRACKING'**
  String get loginTabTrainTracking;

  /// Sign-in tab for employees, by employee ID and password.
  ///
  /// In en, this message translates to:
  /// **'PROMISE'**
  String get loginTabPromise;

  /// Heading over the sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeTitle;

  /// Line under the sign-in heading; app is the app's name, shown bold.
  ///
  /// In en, this message translates to:
  /// **'Your workday starts here with {app}'**
  String loginWelcomeDetail(String app);

  /// Small capitals over the sign-in card's title.
  ///
  /// In en, this message translates to:
  /// **'EMPLOYEE ACCESS'**
  String get loginEyebrow;

  /// Title of the sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your workspace'**
  String get loginCardTitle;

  /// Under the face or fingerprint sign-in key.
  ///
  /// In en, this message translates to:
  /// **'For employees with biometric sign-in turned on.'**
  String get loginBiometricNote;

  /// Divider between biometric sign-in and the password form; id and password are the fields' names, shown bold.
  ///
  /// In en, this message translates to:
  /// **'or use {id} & {password}'**
  String loginOrPassword(String id, String password);

  /// The password form's key when biometric sign-in is offered above it.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Employee ID & Password'**
  String get loginWithPassword;

  /// Line under the sign-in card, beside a train.
  ///
  /// In en, this message translates to:
  /// **'Built for the people who keep Pakistan moving'**
  String get loginSecure;

  /// Link under the sign-in keys to reset a forgotten password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// Heading of both sign-in forms.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Line under the heading of the train tracking sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number, then scan your CNIC.'**
  String get loginTrackingSubtitle;

  /// Line under the heading of the employee sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Enter your employee ID and password.'**
  String get loginPromiseSubtitle;

  /// Button that signs an employee in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// Screen reader label of the sign-in button while it waits.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get loginInProgress;

  /// Title of the dialog shown when sign-in fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign you in'**
  String get loginFailedTitle;

  /// Label of the employee ID field.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeIdLabel;

  /// Hint inside the empty employee ID field.
  ///
  /// In en, this message translates to:
  /// **'Enter your employee ID'**
  String get employeeIdHint;

  /// Under the field when it is longer than allowed.
  ///
  /// In en, this message translates to:
  /// **'Employee ID can be at most {max} characters'**
  String employeeIdTooLong(int max);

  /// Error when the employee ID field is empty.
  ///
  /// In en, this message translates to:
  /// **'Employee ID is required'**
  String get employeeIdRequired;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Hint inside the empty password field.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Under the field when it is longer than allowed.
  ///
  /// In en, this message translates to:
  /// **'Password can be at most {max} characters'**
  String passwordTooLong(int max);

  /// Error when the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Tooltip of the button that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// Tooltip of the button that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// Tooltip of the Face ID button on iPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Face ID'**
  String get biometricFaceId;

  /// Sign-in key on an Android phone with face unlock set up.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Face'**
  String get biometricFace;

  /// Tooltip of the fingerprint button on Android.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Fingerprint'**
  String get biometricFingerprint;

  /// Reason the system shows in the biometric prompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to sign in to PROMISE'**
  String get biometricReason;

  /// Title of the dialog shown when biometric sign-in is off.
  ///
  /// In en, this message translates to:
  /// **'Turn on biometric sign-in'**
  String get biometricDisabledTitle;

  /// How to turn on biometric sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in once with your employee ID and password, then turn on Biometric login in Profile. After that, your fingerprint or Face ID signs you in.'**
  String get biometricDisabledMessage;

  /// Title when there are no saved credentials for biometric sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in once first'**
  String get biometricNoCredentialsTitle;

  /// Body when there are no saved credentials for biometric sign-in.
  ///
  /// In en, this message translates to:
  /// **'No saved sign-in was found on this phone. Sign in with your employee ID and password once.'**
  String get biometricNoCredentialsMessage;

  /// Label of the mobile network field.
  ///
  /// In en, this message translates to:
  /// **'Network operator'**
  String get networkOperatorLabel;

  /// Shown in the mobile network field before one is chosen; also the picker's title.
  ///
  /// In en, this message translates to:
  /// **'Select network operator'**
  String get networkOperatorHint;

  /// Error when no mobile network is chosen.
  ///
  /// In en, this message translates to:
  /// **'Please select a network operator'**
  String get networkOperatorRequired;

  /// Label of the mobile number field.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumberLabel;

  /// Pattern shown in the empty mobile number field.
  ///
  /// In en, this message translates to:
  /// **'03XXXXXXXXX'**
  String get mobileNumberHint;

  /// Error when the mobile number field is empty.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// Error when the mobile number doesn't start with 03.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must start with 03'**
  String get mobileNumberStart;

  /// Error when the mobile number isn't 11 digits long.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be 11 digits, like 03001234567'**
  String get mobileNumberLength;

  /// Heading of the one-time code screen.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get otpTitle;

  /// Line before the phone number on the code screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the {length}-digit code we sent to'**
  String otpSubtitle(int length);

  /// Screen reader label of the code boxes.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get otpFieldLabel;

  /// Text before the resend action.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get otpNotReceived;

  /// Action that sends the code again.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// Countdown until the code can be sent again.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(int seconds);

  /// Button that checks the code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// Title of the forgot password screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// Explanation on the forgot password screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address. We will send you a verification code or a link to reset your password.'**
  String get forgotPasswordMessage;

  /// Label of the email field on the forgot password screen.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get forgotPasswordFieldLabel;

  /// Hint inside the empty email field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get forgotPasswordFieldHint;

  /// Error when the email address is not valid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// Title of the dialog for a feature that is not ready.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get featureInDevelopmentTitle;

  /// Body of the dialog for a feature that is not ready.
  ///
  /// In en, this message translates to:
  /// **'This feature is being built. Please check back later.'**
  String get featureInDevelopmentMessage;

  /// Connection banner title when Wi-Fi and mobile data are both off.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get networkOfflineTitle;

  /// Connection banner hint when Wi-Fi and mobile data are both off.
  ///
  /// In en, this message translates to:
  /// **'Turn on Wi-Fi or mobile data'**
  String get networkOfflineMessage;

  /// Connection banner title when Wi-Fi or data is on but the internet doesn't answer.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get networkNoInternetTitle;

  /// Connection banner hint when Wi-Fi or data is on but the internet doesn't answer.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi or data is on but not working'**
  String get networkNoInternetMessage;

  /// Connection banner title when the connection is slow.
  ///
  /// In en, this message translates to:
  /// **'Slow internet'**
  String get networkSlowTitle;

  /// Connection banner hint when the connection is slow.
  ///
  /// In en, this message translates to:
  /// **'The app is running slowly'**
  String get networkSlowMessage;

  /// Connection banner title, shown briefly when the connection returns.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get networkBackOnlineTitle;

  /// Connection banner hint, shown briefly when the connection returns.
  ///
  /// In en, this message translates to:
  /// **'You\'re connected again'**
  String get networkBackOnlineMessage;

  /// Banner button that checks the connection again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get networkRetry;

  /// What a screen reader says when the connection banner changes.
  ///
  /// In en, this message translates to:
  /// **'{title}. {message}'**
  String networkStatusAnnouncement(String title, String message);

  /// Heading of the dialog that explains, before the system asks, why the app needs the camera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access'**
  String get permissionCameraTitle;

  /// Why the app needs the camera, shown before the system's prompt.
  ///
  /// In en, this message translates to:
  /// **'PROMISE uses the camera to scan your CNIC, to take inspection and accident photos, and to check your face when attendance is marked. It\'s only on while you take a photo.'**
  String get permissionCameraReason;

  /// Shown when the camera was refused and the system won't ask again.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off for PROMISE. To take photos, allow the camera in Settings.'**
  String get permissionCameraBlocked;

  /// Heading of the dialog that explains, before the system asks, why the app needs the location.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get permissionLocationTitle;

  /// Why the app needs the location, shown before the system's prompt.
  ///
  /// In en, this message translates to:
  /// **'PROMISE uses your location to confirm you\'re at your work area when attendance is marked, and to record where inspections and accidents are reported. It\'s only read while you use these features.'**
  String get permissionLocationReason;

  /// Shown when location was refused and the system won't ask again.
  ///
  /// In en, this message translates to:
  /// **'Location access is turned off for PROMISE. To mark attendance and file reports, allow location in Settings.'**
  String get permissionLocationBlocked;

  /// Heading of the dialog that explains, before the system asks, why the app sends notifications.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get permissionNotificationsTitle;

  /// Why the app sends notifications, shown before the system's prompt.
  ///
  /// In en, this message translates to:
  /// **'Hear straight away about leave requests, approvals and other updates that need your attention.'**
  String get permissionNotificationsReason;

  /// Shown when notifications were refused and the system won't ask again.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for PROMISE. To hear about requests and approvals, allow notifications in Settings.'**
  String get permissionNotificationsBlocked;

  /// Heading of the dialog shown when a permission was refused and the system won't ask again.
  ///
  /// In en, this message translates to:
  /// **'Allow access in Settings'**
  String get permissionBlockedTitle;

  /// Button that opens the app's page in the system settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// Button that leaves a permission for later.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionNotNow;

  /// Heading over the module cards on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get homeModulesTitle;

  /// Screen reader label of the avatar on the home screen, which opens the profile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get homeProfile;

  /// Greeting on the home screen before noon.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// Greeting on the home screen from noon to 5 pm.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// Greeting on the home screen from 5 pm.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// The greeting followed by the user's first name.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// Name of the human resources module.
  ///
  /// In en, this message translates to:
  /// **'HRMS'**
  String get moduleHrmsTitle;

  /// Line under the HRMS module's name.
  ///
  /// In en, this message translates to:
  /// **'Human Resource Management System'**
  String get moduleHrmsSubtitle;

  /// Name of the train tracking module.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get moduleTrackingTitle;

  /// Line under the tracking module's name.
  ///
  /// In en, this message translates to:
  /// **'Realtime Train Tracking'**
  String get moduleTrackingSubtitle;

  /// Name of the inspection module.
  ///
  /// In en, this message translates to:
  /// **'e Inspection'**
  String get moduleInspectionTitle;

  /// Line under the inspection module's name.
  ///
  /// In en, this message translates to:
  /// **'Digital Inspection of Assets'**
  String get moduleInspectionSubtitle;

  /// Name of the accident management module.
  ///
  /// In en, this message translates to:
  /// **'PRAMS'**
  String get modulePramsTitle;

  /// Line under the PRAMS module's name.
  ///
  /// In en, this message translates to:
  /// **'Accident Management System'**
  String get modulePramsSubtitle;

  /// Bottom navigation item for the home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation item that opens live train tracking.
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get navTrains;

  /// Bottom navigation item, and header button, for notifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// Bottom navigation item for the profile and settings.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Screen reader label of the raised check-in button in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Check in or out with your face'**
  String get navCheckIn;

  /// Title of the dialog shown when back is pressed on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Close PROMISE?'**
  String get exitTitle;

  /// Body of the close-the-app dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ll sign in again the next time you open it.'**
  String get exitMessage;

  /// Button that closes the app.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get exitConfirm;

  /// Title of the dialog shown once attendance is marked by face.
  ///
  /// In en, this message translates to:
  /// **'Attendance marked'**
  String get attendanceMarkedTitle;

  /// Title of the dialog shown when marking attendance fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark attendance'**
  String get attendanceFailedTitle;

  /// Title of the alerts screen.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// Small line over the alerts title: how many are unread, and today's date.
  ///
  /// In en, this message translates to:
  /// **'{count} new · {date}'**
  String alertsOverline(int count, String date);

  /// Button that marks every alert read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// Filter chip showing every alert.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsFilterAll;

  /// Filter chip showing accident alerts.
  ///
  /// In en, this message translates to:
  /// **'Accidents'**
  String get alertsFilterAccidents;

  /// Filter chip showing leave alerts.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get alertsFilterLeave;

  /// Filter chip showing attendance alerts.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get alertsFilterAttendance;

  /// Heading over today's alerts.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get alertsToday;

  /// Heading over yesterday's alerts.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get alertsYesterday;

  /// Title when a filter has no alerts.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get alertsEmptyTitle;

  /// Line when a filter has no alerts.
  ///
  /// In en, this message translates to:
  /// **'Updates about accidents, leave and attendance will show up here.'**
  String get alertsEmptyMessage;

  /// Button on an accident alert that opens its case.
  ///
  /// In en, this message translates to:
  /// **'Open case'**
  String get alertsOpenCase;

  /// Screen reader label of the dot on an unread alert.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get alertUnread;

  /// First step of an accident case.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get caseReported;

  /// Second step of an accident case.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get caseAcknowledged;

  /// Third step of an accident case: relief on its way or on site.
  ///
  /// In en, this message translates to:
  /// **'Relief'**
  String get caseRelief;

  /// Last step of an accident case: the track is clear.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get caseCleared;

  /// What a screen reader says about an accident case's progress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: {name}'**
  String caseStepOf(int step, int total, String name);

  /// Title of the profile and settings screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Tag with the employee's number on the profile.
  ///
  /// In en, this message translates to:
  /// **'EMP {id}'**
  String profileEmployeeId(String id);

  /// Heading over the account settings.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// Row that opens the employee's personal information.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profilePersonalInfo;

  /// Row that opens password reset.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileSecurity;

  /// Row with the switch for fingerprint or Face ID sign-in.
  ///
  /// In en, this message translates to:
  /// **'Biometric Sign In'**
  String get profileBiometric;

  /// Heading over the app preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// Row that opens notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// Button that signs the employee out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// Title of the log out confirmation.
  ///
  /// In en, this message translates to:
  /// **'Log out of PROMISE?'**
  String get logoutTitle;

  /// Body of the log out confirmation.
  ///
  /// In en, this message translates to:
  /// **'Next time you\'ll sign in with your employee ID and password.'**
  String get logoutMessage;

  /// Reason the system shows when turning on biometric sign-in.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to turn on biometric sign-in'**
  String get biometricEnableReason;

  /// Title when turning on biometric sign-in fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn on biometric sign-in'**
  String get biometricEnableFailedTitle;

  /// Body when turning on biometric sign-in fails.
  ///
  /// In en, this message translates to:
  /// **'Your fingerprint or face wasn\'t confirmed. Please try again.'**
  String get biometricEnableFailedMessage;

  /// Shown when the app is asked for a screen that doesn't exist.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFound;

  /// A button that repeats something that failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// The HRMS module, in its header.
  ///
  /// In en, this message translates to:
  /// **'HRMS'**
  String get hrmsTitle;

  /// What the HRMS home holds, under its title.
  ///
  /// In en, this message translates to:
  /// **'My attendance and leave'**
  String get hrmsSubtitle;

  /// The attendance tab of the HRMS bar.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get hrmsNavAttendance;

  /// The leave tab of the HRMS bar.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get hrmsNavLeave;

  /// The team tab of the HRMS bar, for those with a team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get hrmsNavTeam;

  /// The back tile on the HRMS home, which leaves HRMS.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get hrmsBackHome;

  /// The tile on the HRMS home that opens the attendance calendar.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get hrmsHistoryTooltip;

  /// Read by screen readers for the card of today's attendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s shift'**
  String get shiftTodayLabel;

  /// Status: checked in on time.
  ///
  /// In en, this message translates to:
  /// **'Present · on time'**
  String get shiftOnTime;

  /// Status: checked in after the shift began.
  ///
  /// In en, this message translates to:
  /// **'Present · late'**
  String get shiftLate;

  /// Status: checked in and out today.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get shiftCheckedOut;

  /// Status: not checked in yet today.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get shiftNotIn;

  /// Status: on leave today.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get shiftOnLeave;

  /// Status: marked absent today.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get shiftAbsent;

  /// After the hours and minutes spent at work today, as in "05:42 hrs at work".
  ///
  /// In en, this message translates to:
  /// **'hrs at work'**
  String get shiftHoursAtWork;

  /// The time someone checked in.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get shiftCheckIn;

  /// The time someone checked out.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get shiftCheckOut;

  /// In place of a check-out time not reached yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get shiftNotYet;

  /// The button that checks in with the face.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get shiftActionCheckIn;

  /// The button that checks out with the face.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get shiftActionCheckOut;

  /// Read by screen readers for the shift bar.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the shift done'**
  String shiftProgress(int percent);

  /// Shown when today's attendance fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load today\'s attendance.'**
  String get shiftLoadFailed;

  /// You are inside your work area.
  ///
  /// In en, this message translates to:
  /// **'Inside work area'**
  String get workAreaInside;

  /// You are outside your work area.
  ///
  /// In en, this message translates to:
  /// **'Outside work area'**
  String get workAreaOutside;

  /// Waiting for the location.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get workAreaFinding;

  /// Waiting for the work areas.
  ///
  /// In en, this message translates to:
  /// **'Loading your work area…'**
  String get workAreaLoading;

  /// The work areas could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Work area unavailable'**
  String get workAreaUnavailable;

  /// The phone's location is turned off.
  ///
  /// In en, this message translates to:
  /// **'Location is off'**
  String get workAreaLocationOff;

  /// The app may not use the location.
  ///
  /// In en, this message translates to:
  /// **'Location not allowed'**
  String get workAreaLocationDenied;

  /// A fake GPS app was detected.
  ///
  /// In en, this message translates to:
  /// **'Fake location'**
  String get workAreaFake;

  /// Under "Inside work area".
  ///
  /// In en, this message translates to:
  /// **'{office} · {distance} from the office'**
  String workAreaInsideDetail(String office, String distance);

  /// Under "Outside work area".
  ///
  /// In en, this message translates to:
  /// **'{distance} from {office} · tap for the way'**
  String workAreaOutsideDetail(String distance, String office);

  /// While the location is found.
  ///
  /// In en, this message translates to:
  /// **'Checking you against {office}'**
  String workAreaFindingDetail(String office);

  /// Under "Location is off".
  ///
  /// In en, this message translates to:
  /// **'Turn it on to mark attendance'**
  String get workAreaLocationOffDetail;

  /// Under "Location not allowed".
  ///
  /// In en, this message translates to:
  /// **'Allow it to mark attendance'**
  String get workAreaDeniedDetail;

  /// Under "Fake location".
  ///
  /// In en, this message translates to:
  /// **'Turn off fake GPS apps to mark attendance'**
  String get workAreaFakeDetail;

  /// Under "Work area unavailable".
  ///
  /// In en, this message translates to:
  /// **'Pull down to try again'**
  String get workAreaRetryDetail;

  /// The work area when none is named yet.
  ///
  /// In en, this message translates to:
  /// **'Your work area'**
  String get workAreaYours;

  /// A distance in metres.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(int meters);

  /// A distance in kilometres, with one decimal.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKilometers(String km);

  /// The card that opens the leave form.
  ///
  /// In en, this message translates to:
  /// **'Apply leave'**
  String get hrmsApplyLeave;

  /// Under "Apply leave": the leave left across every type.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No leave days left} =1{1 leave day left} other{{count} leave days left}}'**
  String hrmsLeaveDaysLeft(int count);

  /// The card that opens the attendance calendar.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get hrmsAttendanceCard;

  /// Under "Attendance": days marked this month.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days in {month}} =1{1 day in {month}} other{{count} days in {month}}}'**
  String hrmsDaysIn(int count, String month);

  /// The section of leave balances.
  ///
  /// In en, this message translates to:
  /// **'Leave balance'**
  String get hrmsLeaveBalance;

  /// Under a leave ring: out of how many.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String leaveOfTotal(String total);

  /// Read by screen readers for a leave ring.
  ///
  /// In en, this message translates to:
  /// **'{type}: {left} of {total} days left'**
  String leaveRingLabel(String type, String left, String total);

  /// When there are no leave types.
  ///
  /// In en, this message translates to:
  /// **'No leave balances yet'**
  String get leaveBalanceEmpty;

  /// When the balances fail to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your leave balance.'**
  String get leaveBalanceFailed;

  /// The section of the employee's leave requests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get hrmsMyRequests;

  /// A request waiting for the manager.
  ///
  /// In en, this message translates to:
  /// **'With manager'**
  String get leaveStatusPending;

  /// An approved request.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get leaveStatusApproved;

  /// A rejected request.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get leaveStatusRejected;

  /// A request's heading: its type and dates.
  ///
  /// In en, this message translates to:
  /// **'{type} · {dates}'**
  String leaveRequestTitle(String type, String dates);

  /// When a request was made.
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String leaveAppliedOn(String date);

  /// Under a pending request.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your manager'**
  String get leaveWaitingManager;

  /// When there are no requests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get leaveRequestsEmpty;

  /// When the requests fail to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your requests.'**
  String get leaveRequestsFailed;

  /// The sheet with one request's details.
  ///
  /// In en, this message translates to:
  /// **'Leave request'**
  String get leaveRequestDetails;

  /// A request's leave type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get leaveDetailType;

  /// A request's days.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get leaveDetailDates;

  /// A request's status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get leaveDetailStatus;

  /// Why the leave was asked for.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get leaveDetailReason;

  /// When the request was made.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get leaveDetailApplied;

  /// The sheet listing every request.
  ///
  /// In en, this message translates to:
  /// **'All requests'**
  String get leaveAllRequests;

  /// The leave form's heading.
  ///
  /// In en, this message translates to:
  /// **'Apply leave'**
  String get leaveTitle;

  /// Opens the list of past requests.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get leaveHistory;

  /// The group of leave types, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Leave type'**
  String get leaveTypeGroup;

  /// Under a leave type's days left.
  ///
  /// In en, this message translates to:
  /// **'of {total} left'**
  String leaveLeftOf(String total);

  /// The calendar's label, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get leavePickDates;

  /// Under the calendar: the days picked and the balance after.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} · {left} left after'**
  String leaveDaysAfter(int days, String left);

  /// The reason field's label.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get leaveReason;

  /// The reason field's hint.
  ///
  /// In en, this message translates to:
  /// **'Say why, in a few words'**
  String get leaveReasonHint;

  /// When the reason is too short.
  ///
  /// In en, this message translates to:
  /// **'Write at least {count} characters'**
  String leaveReasonShort(int count);

  /// Under the form: who decides.
  ///
  /// In en, this message translates to:
  /// **'Goes to your reporting manager for approval'**
  String get leaveGoesTo;

  /// The button that sends the request.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get leaveSend;

  /// While the request is sent.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get leaveSending;

  /// The dialog after a request is sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get leaveSentTitle;

  /// The dialog when sending fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the request'**
  String get leaveSendFailedTitle;

  /// When no type is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick a leave type'**
  String get leavePickTypeError;

  /// When no days are picked.
  ///
  /// In en, this message translates to:
  /// **'Pick the days of your leave'**
  String get leavePickDatesError;

  /// When the types fail to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the leave types.'**
  String get leaveTypesFailed;

  /// The attendance calendar's heading.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// Days started on time.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get attendanceOnTime;

  /// Days started late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// Days on leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get attendanceLeave;

  /// Days absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// Days off.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get attendanceWeekend;

  /// The month picker's title.
  ///
  /// In en, this message translates to:
  /// **'Pick a month'**
  String get attendancePickMonth;

  /// A check-in time.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String attendanceIn(String time);

  /// A check-out time.
  ///
  /// In en, this message translates to:
  /// **'Out {time}'**
  String attendanceOut(String time);

  /// Time worked.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String attendanceWorked(int hours, int minutes);

  /// A day without a record.
  ///
  /// In en, this message translates to:
  /// **'Nothing marked this day'**
  String get attendanceNothingMarked;

  /// When attendance fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load attendance.'**
  String get attendanceFailed;

  /// Read by screen readers for a calendar day.
  ///
  /// In en, this message translates to:
  /// **'{date}: {status}'**
  String attendanceDayLabel(String date, String status);

  /// A day's status when nothing was marked.
  ///
  /// In en, this message translates to:
  /// **'not marked'**
  String get attendanceNoMark;

  /// The team page's heading.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get teamTitle;

  /// How many are on the team.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String teamPeople(int count);

  /// The tile that marks someone else's attendance.
  ///
  /// In en, this message translates to:
  /// **'Mark a team member\'s attendance'**
  String get teamMarkAttendance;

  /// The strip with the admin's own check-in.
  ///
  /// In en, this message translates to:
  /// **'You\'re in since {time} · {duration}'**
  String teamYouAreIn(String time, String duration);

  /// The strip when the admin hasn't checked in.
  ///
  /// In en, this message translates to:
  /// **'You\'re not checked in'**
  String get teamYouAreOut;

  /// The board of the team's day.
  ///
  /// In en, this message translates to:
  /// **'Team today'**
  String get teamToday;

  /// When the board was loaded.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String teamUpdated(String time);

  /// People at work.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get teamStatusIn;

  /// People who came late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get teamStatusLate;

  /// People on leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get teamStatusLeave;

  /// People absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get teamStatusAbsent;

  /// The whole team.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get teamStatusTotal;

  /// Read by screen readers for the team bar.
  ///
  /// In en, this message translates to:
  /// **'{present} in, {late} late, {leave} on leave, {absent} absent'**
  String teamBarLabel(int present, int late, int leave, int absent);

  /// The list of the team.
  ///
  /// In en, this message translates to:
  /// **'Team right now'**
  String get teamRightNow;

  /// Opens the whole team.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String teamAll(int count);

  /// The sheet with the whole team.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get teamMembers;

  /// The search field in the team sheet.
  ///
  /// In en, this message translates to:
  /// **'Search by name or ID'**
  String get teamSearchHint;

  /// When a list of people is empty.
  ///
  /// In en, this message translates to:
  /// **'No one here'**
  String get teamNobody;

  /// When the team fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the team.'**
  String get teamMembersFailed;

  /// Someone at work since a time.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String memberIn(String time);

  /// Someone in late since a time.
  ///
  /// In en, this message translates to:
  /// **'Late {time}'**
  String memberLate(String time);

  /// Someone on leave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get memberOnLeave;

  /// Someone absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get memberAbsent;

  /// Someone with nothing marked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get memberNotMarked;

  /// The sheet with someone's profile.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get memberProfile;

  /// Someone's employee number.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get memberEmployeeId;

  /// Someone's job.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get memberDesignation;

  /// Someone's department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get memberDepartment;

  /// Someone's division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get memberDivision;

  /// Where someone works.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get memberLocation;

  /// Someone's shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get memberShift;

  /// Someone's phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get memberPhone;

  /// Someone's email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get memberEmail;

  /// How long someone has been at work today.
  ///
  /// In en, this message translates to:
  /// **'At work'**
  String get memberAtWork;

  /// The rest of someone's details.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get memberMoreDetails;

  /// Marks this person's attendance.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance'**
  String get memberMarkAttendance;

  /// Takes the CNIC photo again.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cnicRetake;

  /// When the camera fails to start.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Try again.'**
  String get cnicCameraFailed;

  /// The first step of registering: the face.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get cnicStepFace;

  /// The second step of registering: the CNIC.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get cnicStepCnic;

  /// The last step of registering.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cnicStepDone;

  /// Read by screen readers for the steps.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {name}'**
  String cnicStepOf(int current, int total, String name);

  /// The dialog before the first face registration.
  ///
  /// In en, this message translates to:
  /// **'Set up face check-in'**
  String get registerIntroTitle;

  /// The dialog while the location is checked before check-in.
  ///
  /// In en, this message translates to:
  /// **'Checking your location'**
  String get gateCheckingTitle;

  /// Under it.
  ///
  /// In en, this message translates to:
  /// **'Making sure you are at your office…'**
  String get gateCheckingMessage;

  /// When the phone may not mark attendance.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get gateNotAllowedTitle;

  /// When a fake GPS app is found.
  ///
  /// In en, this message translates to:
  /// **'Fake location'**
  String get gateFakeLocationTitle;

  /// The screen that marks someone else's attendance.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance'**
  String get othersTitle;

  /// Under its title.
  ///
  /// In en, this message translates to:
  /// **'For someone on your team'**
  String get othersSubtitle;

  /// The employee ID field's hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100234'**
  String get othersEmployeeIdHint;

  /// When the employee ID is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter an employee ID'**
  String get othersEmployeeIdRequired;

  /// When the face camera fails.
  ///
  /// In en, this message translates to:
  /// **'Face capture failed'**
  String get faceCaptureFailedTitle;

  /// When the face isn't a live person.
  ///
  /// In en, this message translates to:
  /// **'Liveness check failed'**
  String get livenessFailedTitle;

  /// When too few photos were taken.
  ///
  /// In en, this message translates to:
  /// **'Face capture incomplete'**
  String get faceIncompleteTitle;

  /// Its message.
  ///
  /// In en, this message translates to:
  /// **'Not enough clear photos were taken. Try again in good light.'**
  String get faceIncompleteMessage;

  /// When a face is registered.
  ///
  /// In en, this message translates to:
  /// **'Face registered'**
  String get faceRegisteredTitle;

  /// Its message when the server says nothing.
  ///
  /// In en, this message translates to:
  /// **'The face is registered.'**
  String get faceRegisteredMessage;

  /// When registering a face fails.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailedTitle;

  /// When the face doesn't match.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailedTitle;

  /// When the location fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the location'**
  String get locationErrorTitle;

  /// Its message.
  ///
  /// In en, this message translates to:
  /// **'Turn on location and allow the app to use it, then try again.'**
  String get locationErrorMessage;

  /// When marking fails unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get markFailedTitle;

  /// Its message.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark the attendance. Try again.'**
  String get markFailedMessage;

  /// Someone's SAP number.
  ///
  /// In en, this message translates to:
  /// **'SAP ID'**
  String get memberSapId;

  /// Someone's pay scale.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get memberRank;

  /// Someone's sub-section.
  ///
  /// In en, this message translates to:
  /// **'Sub-section'**
  String get memberSubSection;

  /// Someone's role in the app.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get memberRole;

  /// When someone joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get memberJoined;

  /// Who someone reports to.
  ///
  /// In en, this message translates to:
  /// **'Reports to'**
  String get memberReportsTo;

  /// Whether someone is still employed.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get memberEmployment;

  /// Under the team board.
  ///
  /// In en, this message translates to:
  /// **'{joined} joined · {left} left this month'**
  String teamMonthChanges(int joined, int left);

  /// Under the team board, when some have the day off.
  ///
  /// In en, this message translates to:
  /// **'{count} on a rest day'**
  String teamRestDay(int count);

  /// The map tile that centres on the user.
  ///
  /// In en, this message translates to:
  /// **'Centre on me'**
  String get mapRecenter;

  /// When the location was found moments ago.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get mapUpdatedNow;

  /// When the location was found minutes ago.
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes} min ago'**
  String mapUpdatedMinutes(int minutes);

  /// The panel title inside an office's area.
  ///
  /// In en, this message translates to:
  /// **'You\'re at {office}'**
  String mapYouAreAt(String office);

  /// When another office is picked on the map.
  ///
  /// In en, this message translates to:
  /// **'Attendance is marked where you are. To mark it at {office}, go there first.'**
  String mapOtherOffice(String office);

  /// When outside every area.
  ///
  /// In en, this message translates to:
  /// **'Go {distance} to {office} to mark attendance. Follow the line.'**
  String mapOutsideMessage(String distance, String office);

  /// While the offices load.
  ///
  /// In en, this message translates to:
  /// **'Getting the offices you may mark attendance at.'**
  String get mapLoadingMessage;

  /// When the offices fail to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your work area'**
  String get mapFailedTitle;

  /// When location is off.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see where you are and mark attendance.'**
  String get mapLocationOffMessage;

  /// When location isn't allowed.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get mapDeniedTitle;

  /// Its message.
  ///
  /// In en, this message translates to:
  /// **'Allow location so the app can check you are at work.'**
  String get mapDeniedMessage;

  /// While the location is found.
  ///
  /// In en, this message translates to:
  /// **'Stay where the sky is visible for a better fix.'**
  String get mapFindingMessage;

  /// Under the distance to the office.
  ///
  /// In en, this message translates to:
  /// **'from office'**
  String get mapFromOffice;

  /// Under the location's accuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy'**
  String get mapAccuracy;

  /// Under the area's radius.
  ///
  /// In en, this message translates to:
  /// **'allowed range'**
  String get mapRange;

  /// How far off the location may be.
  ///
  /// In en, this message translates to:
  /// **'±{meters} m'**
  String mapAccuracyValue(int meters);

  /// Turns location on.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get mapTurnOnLocation;

  /// Asks for location.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get mapAllowLocation;

  /// Goes back to the office the user is in.
  ///
  /// In en, this message translates to:
  /// **'Mark at {office} instead'**
  String mapMarkInstead(String office);

  /// Goes on to check in at the office.
  ///
  /// In en, this message translates to:
  /// **'Continue at {office}'**
  String mapContinueAt(String office);

  /// Marks attendance at the office the user is in.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance here'**
  String get mapMarkHere;

  /// The disabled button outside every area.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance inside the area'**
  String get mapMarkInside;

  /// On the chip of the office the user is in.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get mapYouAreHere;

  /// On an office chip.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String mapAway(String distance);

  /// On an office chip before the location is known.
  ///
  /// In en, this message translates to:
  /// **'{meters} m area'**
  String mapAreaSize(int meters);

  /// The profile section for light and dark.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileSectionAppearance;

  /// The light look.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// The dark look.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// The look the phone is set to.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// Under the setup screen's title.
  ///
  /// In en, this message translates to:
  /// **'Two quick steps, then you can check in'**
  String get registerSubtitle;

  /// Under the title when registering someone else.
  ///
  /// In en, this message translates to:
  /// **'Two quick steps for employee {id}'**
  String registerOthersSubtitle(String id);

  /// Step 1's title.
  ///
  /// In en, this message translates to:
  /// **'Register the face'**
  String get registerFaceTitle;

  /// Step 1's explanation.
  ///
  /// In en, this message translates to:
  /// **'The camera takes a few photos of the face. Hold the phone at eye level, in good light.'**
  String get registerFaceDetail;

  /// Opens the face camera.
  ///
  /// In en, this message translates to:
  /// **'Start face scan'**
  String get registerFaceAction;

  /// Step 1 once done.
  ///
  /// In en, this message translates to:
  /// **'Face photos taken'**
  String get registerFaceDone;

  /// Step 2's title.
  ///
  /// In en, this message translates to:
  /// **'Upload the CNIC'**
  String get registerCnicTitle;

  /// Step 2's explanation.
  ///
  /// In en, this message translates to:
  /// **'Photograph the front of the CNIC, fitted inside the frame.'**
  String get registerCnicDetail;

  /// Step 2 once done.
  ///
  /// In en, this message translates to:
  /// **'CNIC photo taken'**
  String get registerCnicDone;

  /// Under step 2 before step 1 is done.
  ///
  /// In en, this message translates to:
  /// **'Finish step 1 first'**
  String get registerCnicLocked;

  /// A step's number, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String registerStep(int number);

  /// Under face check-in setup when the CNIC and face photos fail to upload; reason is the server's or network's message.
  ///
  /// In en, this message translates to:
  /// **'The CNIC and face photos couldn\'t be sent, so nothing was registered. {reason}'**
  String registerAttachmentsFailed(String reason);

  /// Registers once both steps are done.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get registerProceed;

  /// While registering.
  ///
  /// In en, this message translates to:
  /// **'Registering…'**
  String get registerProceeding;

  /// A note under the steps.
  ///
  /// In en, this message translates to:
  /// **'The photos are used only to recognise this person at check-in.'**
  String get registerPrivacy;

  /// The face camera's title when checking in or out.
  ///
  /// In en, this message translates to:
  /// **'Face check-in'**
  String get faceTitleVerify;

  /// The face camera's title when registering.
  ///
  /// In en, this message translates to:
  /// **'Register the face'**
  String get faceTitleRegister;

  /// The first step of a check-in.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get faceStepLocation;

  /// The tip under the face camera.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone at eye level'**
  String get faceTipTitle;

  /// Its detail.
  ///
  /// In en, this message translates to:
  /// **'Straight in front of your face, not from below the chin'**
  String get faceTipDetail;

  /// Under the face camera.
  ///
  /// In en, this message translates to:
  /// **'It takes the photo by itself when you hold still.'**
  String get faceFooter;

  /// When the face camera fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera.'**
  String get faceCameraFailed;

  /// A check passed before the camera opened.
  ///
  /// In en, this message translates to:
  /// **'At your work area'**
  String get faceCheckArea;

  /// The liveness check, while the photos are taken.
  ///
  /// In en, this message translates to:
  /// **'Live person'**
  String get faceCheckLive;

  /// A check passed before the camera opened.
  ///
  /// In en, this message translates to:
  /// **'Device secure'**
  String get faceCheckDevice;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Look at the camera'**
  String get faceHintLook;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Look straight at the camera'**
  String get faceHintStraight;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone at eye level'**
  String get faceHintEyeLevel;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Put your face inside the oval'**
  String get faceHintNoFace;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Only one person in the frame'**
  String get faceHintMultiple;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Open your eyes and look at the camera'**
  String get faceHintEyes;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Uncover your face'**
  String get faceHintCovered;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Move closer'**
  String get faceHintFar;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Move back a little'**
  String get faceHintClose;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone steady'**
  String get faceHintSteady;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Move to better light'**
  String get faceHintDark;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Too much light on your face'**
  String get faceHintBright;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Keep objects away from your face'**
  String get faceHintObject;

  /// What the face camera asks for.
  ///
  /// In en, this message translates to:
  /// **'Face found · hold still'**
  String get faceHintCapturing;

  /// The group of people at work, in the team sheet.
  ///
  /// In en, this message translates to:
  /// **'At work'**
  String get teamGroupIn;

  /// The group of people who came late.
  ///
  /// In en, this message translates to:
  /// **'Came late'**
  String get teamGroupLate;

  /// The group of people on leave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get teamGroupLeave;

  /// The group of people absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get teamGroupAbsent;

  /// The group of people with nothing marked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get teamGroupOther;

  /// A group's heading with how many are in it.
  ///
  /// In en, this message translates to:
  /// **'{group} · {count}'**
  String teamGroupCount(String group, int count);

  /// Under the team sheet's title.
  ///
  /// In en, this message translates to:
  /// **'{people} · updated {time}'**
  String teamSheetSubtitle(String people, String time);

  /// Clears a search.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// The card on the team page that opens marking.
  ///
  /// In en, this message translates to:
  /// **'Mark your team\'s attendance'**
  String get teamMarkTitle;

  /// Under it.
  ///
  /// In en, this message translates to:
  /// **'With their face, or register a new face and CNIC'**
  String get teamMarkSubtitle;

  /// The button under the team list.
  ///
  /// In en, this message translates to:
  /// **'View all {count} members'**
  String teamViewAll(int count);

  /// How much of the team is in, inside the ring.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String teamInToday(int percent);

  /// Under the share of the team in.
  ///
  /// In en, this message translates to:
  /// **'in today'**
  String get teamInTodayLabel;

  /// Read by screen readers for the ring.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the team is in today'**
  String teamInTodaySemantics(int percent);

  /// Under the log out button.
  ///
  /// In en, this message translates to:
  /// **'You\'ll sign in again with your employee ID and password'**
  String get logoutSubtitle;

  /// Before the company's name in the credit.
  ///
  /// In en, this message translates to:
  /// **'Designed & Developed by'**
  String get poweredByLead;

  /// The company that built the app.
  ///
  /// In en, this message translates to:
  /// **'One Network'**
  String get poweredByName;

  /// Under the days left in a leave ring.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get leaveLeftShort;

  /// The days of a leave type taken.
  ///
  /// In en, this message translates to:
  /// **'{days} used'**
  String leaveUsed(String days);

  /// The list of days under the calendar.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get attendanceRecords;

  /// Shows every record.
  ///
  /// In en, this message translates to:
  /// **'View all {count}'**
  String attendanceViewAll(int count);

  /// Shows only the latest records.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get attendanceShowLess;

  /// When no day matches.
  ///
  /// In en, this message translates to:
  /// **'No records here'**
  String get attendanceNoRecords;

  /// Heading over the team to pick from.
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get othersTeam;

  /// Heading over the team, with its size.
  ///
  /// In en, this message translates to:
  /// **'Your team · {count}'**
  String othersTeamCount(int count);

  /// Search box over the team.
  ///
  /// In en, this message translates to:
  /// **'Search by name, ID or designation'**
  String get othersTeamSearch;

  /// When the team is empty.
  ///
  /// In en, this message translates to:
  /// **'No one on your team yet'**
  String get othersTeamEmpty;

  /// When the search finds no one.
  ///
  /// In en, this message translates to:
  /// **'No one matches'**
  String get othersTeamNoMatch;

  /// When the team could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your team.'**
  String get othersTeamFailed;

  /// Under the mark key.
  ///
  /// In en, this message translates to:
  /// **'Pick someone below or type their ID. If their face isn\'t registered yet, you\'ll register it with their CNIC first.'**
  String get othersFirstTimeNote;

  /// Under the e Inspection title.
  ///
  /// In en, this message translates to:
  /// **'Digital Inspection of Assets'**
  String get inspSubtitle;

  /// A kind of inspection.
  ///
  /// In en, this message translates to:
  /// **'Footplate'**
  String get inspFootplate;

  /// A kind of inspection.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get inspStation;

  /// A kind of inspection.
  ///
  /// In en, this message translates to:
  /// **'Motor Trolley'**
  String get inspMotorTrolley;

  /// A kind of inspection.
  ///
  /// In en, this message translates to:
  /// **'Locomotive'**
  String get inspLocomotive;

  /// A kind of inspection.
  ///
  /// In en, this message translates to:
  /// **'Electrical (RTL)'**
  String get inspElectrical;

  /// What a footplate inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Day and night, from the cab'**
  String get inspFootplateAbout;

  /// What a station inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Premises, signals and facilities'**
  String get inspStationAbout;

  /// What a motor trolley inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Track patrol by trolley'**
  String get inspMotorTrolleyAbout;

  /// What a locomotive inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Condition of the loco'**
  String get inspLocomotiveAbout;

  /// What an electrical inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Electrical assets'**
  String get inspElectricalAbout;

  /// The month plan card title, like "October plan".
  ///
  /// In en, this message translates to:
  /// **'{month} plan'**
  String inspPlan(String month);

  /// When the month plan is due.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String inspDue(String date);

  /// Under the done count on the plan ring.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get inspDone;

  /// How many inspections of a kind are done.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String inspDoneOf(int done, int total);

  /// Inspections done.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get inspCompleted;

  /// Inspections left this month.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get inspPending;

  /// Inspections left from earlier months.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get inspOverdue;

  /// Inspections beyond the plan.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get inspExtra;

  /// Heading over the drafts.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get inspContinue;

  /// Heading over the kinds of inspection.
  ///
  /// In en, this message translates to:
  /// **'Start an inspection'**
  String get inspStart;

  /// The key that scrolls to the drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get inspDrafts;

  /// A draft without a name.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get inspDraft;

  /// When a draft was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {when}'**
  String inspSaved(String when);

  /// Opens a draft.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get inspResume;

  /// Deletes a draft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get inspDeleteDraft;

  /// Confirms deleting a draft.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get inspDeleteDraftTitle;

  /// Says what deleting a draft does.
  ///
  /// In en, this message translates to:
  /// **'What was filled in so far will be lost.'**
  String get inspDeleteDraftMessage;

  /// Under the PRAMS title.
  ///
  /// In en, this message translates to:
  /// **'Accident Management System'**
  String get pramsSubtitle;

  /// Search box over the cases.
  ///
  /// In en, this message translates to:
  /// **'Search train, location or status'**
  String get pramsSearch;

  /// Shows cases of every severity.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pramsAll;

  /// A severity.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get pramsCritical;

  /// A severity.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get pramsModerate;

  /// A severity.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get pramsMinor;

  /// When the cases did not load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the cases'**
  String get pramsLoadFailed;

  /// When there are no cases.
  ///
  /// In en, this message translates to:
  /// **'No accidents reported'**
  String get pramsNoCases;

  /// Under no cases.
  ///
  /// In en, this message translates to:
  /// **'Cases you report show here with their progress.'**
  String get pramsNoCasesMessage;

  /// When the search finds nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get pramsNoMatch;

  /// Under nothing matches.
  ///
  /// In en, this message translates to:
  /// **'Try another train, place or severity.'**
  String get pramsNoMatchMessage;

  /// The report card title.
  ///
  /// In en, this message translates to:
  /// **'Report an accident'**
  String get pramsReportTitle;

  /// The report card line.
  ///
  /// In en, this message translates to:
  /// **'Location and details go straight to control'**
  String get pramsReportSubtitle;

  /// Opens the report form.
  ///
  /// In en, this message translates to:
  /// **'Report accident'**
  String get pramsReportAction;

  /// Over the month counts.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get pramsThisMonth;

  /// Cases not yet acted on.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pramsOpen;

  /// Cases being looked into.
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get pramsInvestigating;

  /// Cases closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get pramsClosed;

  /// Screen reader text for the week bars.
  ///
  /// In en, this message translates to:
  /// **'Cases per week: {counts}'**
  String pramsWeeks(String counts);

  /// When a case was updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String pramsUpdated(String when);

  /// The kilometre of a case.
  ///
  /// In en, this message translates to:
  /// **'KM {km}'**
  String pramsKm(String km);

  /// A case stage.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get pramsStageReported;

  /// A case stage.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get pramsStageAcknowledged;

  /// A case stage.
  ///
  /// In en, this message translates to:
  /// **'Relief'**
  String get pramsStageRelief;

  /// A case stage.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get pramsStageCleared;

  /// Screen reader text for a case stage.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: {name}'**
  String pramsStageOf(int step, int total, String name);

  /// The report form title.
  ///
  /// In en, this message translates to:
  /// **'Report accident'**
  String get reportTitle;

  /// Under the report form title.
  ///
  /// In en, this message translates to:
  /// **'Goes to control the moment you submit'**
  String get reportSubtitle;

  /// The first step of a report.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get reportStepTrain;

  /// The second step of a report.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get reportStepWhat;

  /// The third step of a report.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get reportStepPhotos;

  /// While the location is found.
  ///
  /// In en, this message translates to:
  /// **'Finding your location'**
  String get reportLocating;

  /// Under finding your location.
  ///
  /// In en, this message translates to:
  /// **'It goes with the report'**
  String get reportLocatingDetail;

  /// Once the location is found.
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get reportLocated;

  /// Where the reporter is.
  ///
  /// In en, this message translates to:
  /// **'{lat}, {lon} · accurate to {metres} m'**
  String reportLocatedDetail(String lat, String lon, int metres);

  /// When the location is not found.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location'**
  String get reportNotLocated;

  /// Under the location not found.
  ///
  /// In en, this message translates to:
  /// **'Turn on location and try again'**
  String get reportNotLocatedDetail;

  /// Says the location was taken on its own.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get reportAuto;

  /// A section of the report.
  ///
  /// In en, this message translates to:
  /// **'Train and place'**
  String get reportTrainAndPlace;

  /// The train field.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get reportTrain;

  /// The train field before one is picked.
  ///
  /// In en, this message translates to:
  /// **'Select the train'**
  String get reportPickTrainHint;

  /// The train sheet title.
  ///
  /// In en, this message translates to:
  /// **'Select the train'**
  String get reportPickTrain;

  /// Under the train sheet title.
  ///
  /// In en, this message translates to:
  /// **'Trains running near your location'**
  String get reportPickTrainSubtitle;

  /// Search box in the train sheet.
  ///
  /// In en, this message translates to:
  /// **'Train name or number'**
  String get reportSearchTrains;

  /// How far a train is.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String reportAway(String km);

  /// Picks the train.
  ///
  /// In en, this message translates to:
  /// **'Use {train}'**
  String reportUseTrain(String train);

  /// When no train is found.
  ///
  /// In en, this message translates to:
  /// **'No train matches'**
  String get reportNoTrains;

  /// The locomotive field.
  ///
  /// In en, this message translates to:
  /// **'Locomotive'**
  String get reportLocomotive;

  /// The kilometre field.
  ///
  /// In en, this message translates to:
  /// **'Kilometre'**
  String get reportKilometre;

  /// The last station field.
  ///
  /// In en, this message translates to:
  /// **'Last station'**
  String get reportLastStation;

  /// Says a value comes from the train.
  ///
  /// In en, this message translates to:
  /// **'From train'**
  String get reportFromTrain;

  /// The division field.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get reportDivision;

  /// The section field.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get reportSection;

  /// The block section field.
  ///
  /// In en, this message translates to:
  /// **'Block section'**
  String get reportBlockSection;

  /// The date and time field.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get reportWhen;

  /// A field before a value is picked.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get reportPick;

  /// A section of the report.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get reportWhatHappened;

  /// Says the severity comes from the kind of accident.
  ///
  /// In en, this message translates to:
  /// **'set from the type'**
  String get reportSeverityFromType;

  /// Heading over the conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get reportConditions;

  /// A condition.
  ///
  /// In en, this message translates to:
  /// **'Train derailed'**
  String get reportDerailed;

  /// What the condition means.
  ///
  /// In en, this message translates to:
  /// **'One or more vehicles off the track'**
  String get reportDerailedAbout;

  /// A condition.
  ///
  /// In en, this message translates to:
  /// **'Fire involved'**
  String get reportFire;

  /// What the condition means.
  ///
  /// In en, this message translates to:
  /// **'Fire or explosion at the site'**
  String get reportFireAbout;

  /// A condition.
  ///
  /// In en, this message translates to:
  /// **'People injured'**
  String get reportInjured;

  /// What the condition means.
  ///
  /// In en, this message translates to:
  /// **'Passengers or staff hurt'**
  String get reportInjuredAbout;

  /// A condition.
  ///
  /// In en, this message translates to:
  /// **'Dangerous goods'**
  String get reportDangerousGoods;

  /// What the condition means.
  ///
  /// In en, this message translates to:
  /// **'Hazardous cargo on board'**
  String get reportDangerousGoodsAbout;

  /// Lowers the count.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get reportFewer;

  /// Raises the count.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get reportMore;

  /// The remarks field.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get reportRemarks;

  /// Heading over the photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get reportPhotos;

  /// A photo, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String reportPhotoN(int n);

  /// Adds a photo.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get reportAddPhoto;

  /// Opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get reportTakePhoto;

  /// Opens the gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get reportChoosePhotos;

  /// Confirms removing a photo.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get reportRemovePhoto;

  /// Removes a photo.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get reportRemove;

  /// Clears the form.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reportReset;

  /// Sends the report.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// When the report is not complete.
  ///
  /// In en, this message translates to:
  /// **'A little more first'**
  String get reportMissingTitle;

  /// What the report still needs.
  ///
  /// In en, this message translates to:
  /// **'Select the train, what happened, and the date and time.'**
  String get reportMissingMessage;

  /// When the report did not send.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report'**
  String get reportFailedTitle;

  /// When the report did not send.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get reportFailedMessage;

  /// Title when face/CNIC verification is pending admin approval.
  ///
  /// In en, this message translates to:
  /// **'Verification In Progress'**
  String get verificationInProgressTitle;

  /// Message when face/CNIC verification is pending admin approval.
  ///
  /// In en, this message translates to:
  /// **'Your data has been submitted. Please wait for admin approval.'**
  String get verificationInProgressMessage;

  /// The shift key before the face is registered.
  ///
  /// In en, this message translates to:
  /// **'Register face'**
  String get shiftRegisterFace;

  /// What a screen reader says for the loader.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Finds the location afresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get locRefresh;

  /// The refresh key while it works.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get locFindingShort;

  /// While the location is found again.
  ///
  /// In en, this message translates to:
  /// **'Finding your exact location…'**
  String get locFinding;

  /// While the location is found again.
  ///
  /// In en, this message translates to:
  /// **'Stay where you are for a moment.'**
  String get locFindingDetail;

  /// When finding the location failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location'**
  String get locFailed;

  /// What to do when finding the location failed.
  ///
  /// In en, this message translates to:
  /// **'Move near a window or outside, then try again.'**
  String get locFailedDetail;

  /// When the location was found again.
  ///
  /// In en, this message translates to:
  /// **'Location updated just now'**
  String get locUpdated;

  /// When the location was found again.
  ///
  /// In en, this message translates to:
  /// **'This is where you are now.'**
  String get locUpdatedDetail;

  /// When the employee appears outside the office.
  ///
  /// In en, this message translates to:
  /// **'Not where you are?'**
  String get locOutside;

  /// What to do when shown outside.
  ///
  /// In en, this message translates to:
  /// **'If you\'re inside your office, tap Refresh location to update where you are.'**
  String get locOutsideDetail;

  /// When the location is old.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Location from 1 min ago} other{Location from {minutes} min ago}}'**
  String locStale(int minutes);

  /// What to do when the location is old.
  ///
  /// In en, this message translates to:
  /// **'Tap Refresh location so it shows where you are now.'**
  String get locStaleDetail;

  /// When the location is not exact.
  ///
  /// In en, this message translates to:
  /// **'Location is rough (±{metres} m)'**
  String locRough(int metres);

  /// What to do when the location is rough.
  ///
  /// In en, this message translates to:
  /// **'Tap Refresh location, or move near a window or outside.'**
  String get locRoughDetail;

  /// Title of the sheet that changes the user's profile photo.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoTitle;

  /// Under the profile photo sheet's title: the photo isn't sent anywhere.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone only'**
  String get profilePhotoSubtitle;

  /// Opens the sheet that changes the profile photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profilePhotoChange;

  /// Takes a new profile photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// Picks a profile photo from the phone's photos.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoGallery;

  /// Picks an emoji to show in place of a photo.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get profilePhotoAvatar;

  /// Goes back to the user's initials.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// When a picked photo couldn't be saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use that photo. Try another.'**
  String get profilePhotoFailed;

  /// Title of the emoji picker.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get emojiPickerTitle;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Smileys & people'**
  String get emojiGroupSmileys;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Animals & nature'**
  String get emojiGroupAnimals;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get emojiGroupFood;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get emojiGroupActivities;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Travel & places'**
  String get emojiGroupTravel;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get emojiGroupObjects;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get emojiGroupSymbols;

  /// An emoji group's tab, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get emojiGroupFlags;

  /// Profile section heading for text size and weight.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get profileSectionText;

  /// Names the text size slider.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeTitle;

  /// A text size.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSizeSmall;

  /// A text size: the phone's own.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textSizeDefault;

  /// A text size.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// A text size.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get textSizeLargest;

  /// Sample message in the text size preview.
  ///
  /// In en, this message translates to:
  /// **'Assalam-o-Alaikum! This is how text will look across PROMISE.'**
  String get textPreviewMessage;

  /// The time on the sample message in the text size preview.
  ///
  /// In en, this message translates to:
  /// **'9:41'**
  String get textPreviewTime;

  /// Switch that makes all text bold.
  ///
  /// In en, this message translates to:
  /// **'Bold text'**
  String get textBold;

  /// Under the bold text switch.
  ///
  /// In en, this message translates to:
  /// **'Heavier letters that are easier to read'**
  String get textBoldDetail;

  /// A text size.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textSizeLarger;

  /// The reply in the text size preview.
  ///
  /// In en, this message translates to:
  /// **'Walaikum Assalam! It\'s easy to read now.'**
  String get textPreviewReply;

  /// Keeps the emoji picked as the avatar.
  ///
  /// In en, this message translates to:
  /// **'Use this avatar'**
  String get emojiUse;

  /// Over the colours an emoji avatar can sit on.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get emojiBackground;

  /// Under the avatar preview before an emoji is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick an emoji below'**
  String get emojiPickPrompt;

  /// A background colour for an emoji avatar, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Jade'**
  String get avatarTintJade;

  /// A background colour for an emoji avatar, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get avatarTintGold;

  /// A background colour for an emoji avatar, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get avatarTintSky;

  /// A background colour for an emoji avatar, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get avatarTintRose;

  /// A background colour for an emoji avatar, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get avatarTintSand;

  /// Profile row showing the installed version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get profileAppVersion;

  /// Title of a message saying something worked.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get messageSuccessTitle;

  /// Title of a message saying something failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get messageErrorTitle;

  /// Title of a message asking the user to check something.
  ///
  /// In en, this message translates to:
  /// **'Please check'**
  String get messageWarningTitle;

  /// Title of a plain informational message.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get messageInfoTitle;

  /// Loads something again after it failed.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// Dialog title when the team's data failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your team'**
  String get teamLoadFailedTitle;

  /// Dialog message when the team's data failed to load.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then refresh to try again.'**
  String get teamLoadFailedMessage;

  /// Profile row that opens the font and display size page.
  ///
  /// In en, this message translates to:
  /// **'Font & Display Size'**
  String get profileTextDisplay;

  /// Under the font and display size row: the display size and text size picked.
  ///
  /// In en, this message translates to:
  /// **'{display} display · {text} text'**
  String profileTextDisplayDetail(String display, String text);

  /// Section title for how large the whole app is drawn.
  ///
  /// In en, this message translates to:
  /// **'Display size'**
  String get displaySizeTitle;

  /// Display size that fits the most on screen.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get displaySizeStandard;

  /// Display size that draws everything larger.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get displaySizeLarge;

  /// Under the default display size.
  ///
  /// In en, this message translates to:
  /// **'More on screen'**
  String get displaySizeStandardDetail;

  /// Under the large display size.
  ///
  /// In en, this message translates to:
  /// **'Everything larger'**
  String get displaySizeLargeDetail;

  /// Note under the display size choices.
  ///
  /// In en, this message translates to:
  /// **'Display size makes everything larger, buttons and icons too. Text size changes only the words.'**
  String get displaySizeFooter;

  /// Tile over the leave calendar for the first day of leave.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get leaveFrom;

  /// Tile over the leave calendar for the last day of leave.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get leaveTo;

  /// On a leave date tile before a day is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get leaveNoDay;

  /// Hint over the leave calendar while the first day is being picked.
  ///
  /// In en, this message translates to:
  /// **'Tap the first day of your leave'**
  String get leavePickFirstDay;

  /// Hint over the leave calendar while the last day is being picked.
  ///
  /// In en, this message translates to:
  /// **'Now tap the last day (same day for one day)'**
  String get leavePickLastDay;

  /// Button that confirms a picked date and time.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dateTimeDone;

  /// Label over the time wheel in the date and time sheet.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get dateTimeTime;

  /// PDF title for one person's attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance report'**
  String get attReportTitle;

  /// PDF title of the team summary.
  ///
  /// In en, this message translates to:
  /// **'Team attendance'**
  String get attReportTeamTitle;

  /// PDF: when the report was made.
  ///
  /// In en, this message translates to:
  /// **'Generated {when}'**
  String attReportGenerated(String when);

  /// PDF footer: who downloaded it.
  ///
  /// In en, this message translates to:
  /// **'Generated by {name}'**
  String attReportGeneratedBy(String name);

  /// PDF footer page number.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String attReportPage(int page, int total);

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get attReportEmployeeId;

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get attReportDesignation;

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get attReportDepartment;

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get attReportDivision;

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get attReportLocation;

  /// PDF field.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get attReportShift;

  /// PDF stat: days present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attReportPresent;

  /// PDF stat: weekends and holidays.
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get attReportDaysOff;

  /// PDF stat: share of working days present.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get attReportRate;

  /// PDF stat: total time worked.
  ///
  /// In en, this message translates to:
  /// **'Hours worked'**
  String get attReportHours;

  /// PDF stat: days meant to be worked.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get attReportWorkingDays;

  /// PDF section: the period as a calendar.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get attReportGlance;

  /// PDF section: one row per day.
  ///
  /// In en, this message translates to:
  /// **'Daily record'**
  String get attReportDaily;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attReportDate;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get attReportDay;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get attReportStatus;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get attReportCheckIn;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get attReportCheckOut;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Worked'**
  String get attReportWorked;

  /// PDF section: leave requests in the period.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get attReportLeaves;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Leave type'**
  String get attReportLeaveType;

  /// PDF column: number of days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get attReportDays;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Applied on'**
  String get attReportAppliedOn;

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get attReportRemarks;

  /// PDF: no leave requests touch the period.
  ///
  /// In en, this message translates to:
  /// **'No leaves in this period.'**
  String get attReportNoLeaves;

  /// PDF: a person's data failed to load.
  ///
  /// In en, this message translates to:
  /// **'This person\'s attendance couldn\'t be loaded.'**
  String get attReportLoadFailed;

  /// PDF team summary: how many people.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String attReportMembers(int count);

  /// PDF column.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get attReportName;

  /// PDF footer brand line.
  ///
  /// In en, this message translates to:
  /// **'PROMISE · Pakistan Railways'**
  String get attReportFooter;

  /// Sheet title for downloading an attendance PDF.
  ///
  /// In en, this message translates to:
  /// **'Download attendance'**
  String get downloadTitle;

  /// Choice: a calendar month.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get downloadMonthly;

  /// Choice: days picked on a calendar.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get downloadRange;

  /// Choice: the signed-in employee.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get downloadOnlyMe;

  /// Choice: members of the team.
  ///
  /// In en, this message translates to:
  /// **'My team'**
  String get downloadMyTeam;

  /// Selects every team member.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get downloadSelectAll;

  /// How many team members are picked.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} selected'**
  String downloadSelected(int count, int total);

  /// Error when no team member is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one person'**
  String get downloadPickPeople;

  /// Error when no range is picked.
  ///
  /// In en, this message translates to:
  /// **'Pick the first and last day'**
  String get downloadPickRange;

  /// Button that makes and saves the PDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadButton;

  /// Progress while loading people.
  ///
  /// In en, this message translates to:
  /// **'Preparing {done} of {total}…'**
  String downloadPreparing(int done, int total);

  /// Dialog after the PDF is saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get downloadSavedTitle;

  /// Where the PDF was saved.
  ///
  /// In en, this message translates to:
  /// **'{name} is in Downloads › PROMISE.'**
  String downloadSavedMessage(String name);

  /// Opens the saved PDF.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get downloadOpen;

  /// Shares the saved PDF.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get downloadShare;

  /// Error when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the PDF. Try again.'**
  String get downloadFailed;

  /// Error when storage is refused on old Android.
  ///
  /// In en, this message translates to:
  /// **'Allow storage so the PDF can be saved.'**
  String get downloadNeedsStorage;

  /// Error when no PDF viewer exists.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone opens PDFs.'**
  String get downloadNoViewer;

  /// Hint in the team search field.
  ///
  /// In en, this message translates to:
  /// **'Search team'**
  String get downloadSearch;

  /// PDF team summary: the people in it.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get attReportPeople;

  /// Card title: download your attendance.
  ///
  /// In en, this message translates to:
  /// **'Download attendance'**
  String get downloadCardTitle;

  /// Card text: what the download does.
  ///
  /// In en, this message translates to:
  /// **'Save your attendance on your phone as a PDF file, with your leaves.'**
  String get downloadCardMessage;

  /// Card title: download the team's attendance.
  ///
  /// In en, this message translates to:
  /// **'Download team attendance'**
  String get downloadTeamCardTitle;

  /// Card text: what the team download does.
  ///
  /// In en, this message translates to:
  /// **'Save a PDF of your whole team, or pick only the people you need.'**
  String get downloadTeamCardMessage;

  /// Tag: any range of days.
  ///
  /// In en, this message translates to:
  /// **'Any dates'**
  String get downloadTagAnyDates;

  /// Tag: leaves are included.
  ///
  /// In en, this message translates to:
  /// **'With leaves'**
  String get downloadTagLeaves;

  /// Sheet intro explaining the steps.
  ///
  /// In en, this message translates to:
  /// **'Choose the dates, then tap Download PDF. The file is saved in your phone\'s Downloads.'**
  String get downloadIntro;

  /// Sheet step label: pick the period.
  ///
  /// In en, this message translates to:
  /// **'1 · Which dates?'**
  String get downloadStepDates;

  /// Sheet step label: pick the people.
  ///
  /// In en, this message translates to:
  /// **'2 · Whose attendance?'**
  String get downloadStepWhose;

  /// Heading of the CNIC step of train tracking sign-in.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get identityTitle;

  /// Line under the heading of the CNIC step.
  ///
  /// In en, this message translates to:
  /// **'Scan the front of your CNIC to continue.'**
  String get identitySubtitle;

  /// Train tracking sign-in step: the mobile number.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get identityStepMobile;

  /// Train tracking sign-in step: the CNIC.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get identityStepCnic;

  /// Goes back to change the mobile number.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get identityChangeNumber;

  /// Title over the CNIC on the identity step.
  ///
  /// In en, this message translates to:
  /// **'Pakistani CNIC'**
  String get cnicCardTitle;

  /// In the empty CNIC space; opens the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan your CNIC'**
  String get cnicCardTap;

  /// Note that the CNIC is checked on the phone.
  ///
  /// In en, this message translates to:
  /// **'Checked on this phone by on-device AI'**
  String get cnicCardAi;

  /// Opens the CNIC camera again once a CNIC is scanned.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get cnicScanAgain;

  /// On the CNIC's photo once the AI has checked it.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get cnicVerified;

  /// Badge on the CNIC camera while the AI reads it.
  ///
  /// In en, this message translates to:
  /// **'AI scan'**
  String get cnicLiveBadge;

  /// While the CNIC camera starts.
  ///
  /// In en, this message translates to:
  /// **'Starting the camera…'**
  String get cnicHintStarting;

  /// While nothing is in the CNIC camera's frame.
  ///
  /// In en, this message translates to:
  /// **'Fit the front of your CNIC inside the frame'**
  String get cnicHintPlace;

  /// While there is text in the frame but no CNIC yet.
  ///
  /// In en, this message translates to:
  /// **'Looking for a CNIC…'**
  String get cnicHintLooking;

  /// When the CNIC is held too far from the camera.
  ///
  /// In en, this message translates to:
  /// **'Bring your CNIC closer to fill the frame'**
  String get cnicHintCloser;

  /// When the CNIC is seen in the frame, ready to be captured.
  ///
  /// In en, this message translates to:
  /// **'CNIC found. Hold steady and tap capture'**
  String get cnicHintHold;

  /// The CNIC camera's shutter, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Capture CNIC'**
  String get cnicCapture;

  /// When a bank card is held up to the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'That\'s a bank card, not a CNIC'**
  String get cnicHintBank;

  /// When another card is held up to the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'That card isn\'t a CNIC'**
  String get cnicHintOther;

  /// While the AI checks the photo of the CNIC.
  ///
  /// In en, this message translates to:
  /// **'Checking your CNIC…'**
  String get cnicHintReading;

  /// Once the AI has read the CNIC.
  ///
  /// In en, this message translates to:
  /// **'CNIC verified'**
  String get cnicHintVerified;

  /// Turns the phone's light on, on the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'Turn the light on'**
  String get cnicTorchOn;

  /// Turns the phone's light off, on the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'Turn the light off'**
  String get cnicTorchOff;

  /// Dialog title when a bank card is scanned instead of a CNIC.
  ///
  /// In en, this message translates to:
  /// **'That\'s a bank card'**
  String get cnicWrongBankTitle;

  /// Dialog message when a bank card is scanned instead of a CNIC.
  ///
  /// In en, this message translates to:
  /// **'Bank, debit and credit cards can\'t be used. Scan your Pakistani CNIC or NICOP instead.'**
  String get cnicWrongBankMessage;

  /// Dialog title when another card is scanned instead of a CNIC.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a CNIC'**
  String get cnicWrongCardTitle;

  /// Dialog message when another card is scanned instead of a CNIC.
  ///
  /// In en, this message translates to:
  /// **'This looks like another card, such as a licence, passport or office card. Only a Pakistani CNIC or NICOP can be scanned.'**
  String get cnicWrongCardMessage;

  /// Dialog message when something with text that isn't a CNIC is scanned.
  ///
  /// In en, this message translates to:
  /// **'Only a Pakistani CNIC or NICOP can be scanned. Hold the front of the card, the side with your photo, inside the frame.'**
  String get cnicNotCnicMessage;

  /// Dialog title when the photo taken shows no CNIC.
  ///
  /// In en, this message translates to:
  /// **'No CNIC found'**
  String get cnicNothingTitle;

  /// Dialog message when the photo taken shows no CNIC, or too unclearly to tell.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t see a Pakistani CNIC clearly in the photo. Fit the front of your CNIC or NICOP, the side with your photo, inside the frame, hold steady in good light and capture again.'**
  String get cnicNothingMessage;

  /// Beside the switch for the phone's light, on the CNIC camera.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get cnicFlash;

  /// When the camera is too dark to read a CNIC.
  ///
  /// In en, this message translates to:
  /// **'Too dark. Switch the flash on'**
  String get cnicHintDark;

  /// When the camera is too dark to read a CNIC with the flash on.
  ///
  /// In en, this message translates to:
  /// **'Still too dark. Move to more light'**
  String get cnicHintDarkFlashOn;

  /// When the camera's picture is too blurred to take a CNIC.
  ///
  /// In en, this message translates to:
  /// **'Hold steady. The picture is blurred'**
  String get cnicHintBlurry;

  /// Heading of the screen that asks for a face check before an inspection starts.
  ///
  /// In en, this message translates to:
  /// **'Verify your face to start'**
  String get inspGateTitle;

  /// Why a face check is needed before an inspection.
  ///
  /// In en, this message translates to:
  /// **'Your face is checked now and again before you submit, so every report is signed by the person who made it.'**
  String get inspGateMessage;

  /// One of the things the start face check confirms.
  ///
  /// In en, this message translates to:
  /// **'A live face, not a photo'**
  String get inspGateCheckLive;

  /// One of the things the start face check confirms.
  ///
  /// In en, this message translates to:
  /// **'Matched to your registered face'**
  String get inspGateCheckMatch;

  /// One of the things the start face check confirms.
  ///
  /// In en, this message translates to:
  /// **'Time and place noted on the report'**
  String get inspGateCheckStamp;

  /// Button that opens the face check and then the inspection.
  ///
  /// In en, this message translates to:
  /// **'Verify and start'**
  String get inspGateStart;

  /// Step of an inspection's face check: the face is checked.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get inspStepVerify;

  /// Step of an inspection's face check: the inspection begins.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get inspStepStart;

  /// Step of submitting an inspection: the report is read.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get inspStepReview;

  /// Step of submitting an inspection: it is sent.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get inspStepSubmit;

  /// Shown while the server checks the face.
  ///
  /// In en, this message translates to:
  /// **'Verifying your face…'**
  String get inspVerifying;

  /// Title when the face check passed.
  ///
  /// In en, this message translates to:
  /// **'Face verified'**
  String get inspVerifiedTitle;

  /// Title when the face check failed.
  ///
  /// In en, this message translates to:
  /// **'Face not verified'**
  String get inspVerifyFailedTitle;

  /// When the employee has no registered face.
  ///
  /// In en, this message translates to:
  /// **'Your face isn\'t registered yet. Register it from Attendance in HRMS, then try again.'**
  String get inspNotRegistered;

  /// When the employee's face registration is not yet approved.
  ///
  /// In en, this message translates to:
  /// **'Your face registration is waiting for approval. You can inspect once it is approved.'**
  String get inspRegistrationPending;

  /// When the face check failed for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'Your face couldn\'t be verified. Try again in good light.'**
  String get inspVerifyFailed;

  /// Title of the screen where an inspection is checked and sent.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get inspReviewTitle;

  /// Lead text on the review screen.
  ///
  /// In en, this message translates to:
  /// **'This is the report as it will be submitted. Read it through before you confirm.'**
  String get inspReviewLead;

  /// Shown while the PDF of an inspection is made.
  ///
  /// In en, this message translates to:
  /// **'Preparing the report…'**
  String get inspReviewPreparing;

  /// Under a page of the report preview.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String inspReviewPage(int page, int count);

  /// Button confirming the previewed report is right.
  ///
  /// In en, this message translates to:
  /// **'The report is correct'**
  String get inspReviewConfirm;

  /// Shown once the report was confirmed.
  ///
  /// In en, this message translates to:
  /// **'You confirmed the report'**
  String get inspReviewConfirmed;

  /// Button going back to edit an inspection.
  ///
  /// In en, this message translates to:
  /// **'Back to the form'**
  String get inspReviewEdit;

  /// Button opening the face check before submitting.
  ///
  /// In en, this message translates to:
  /// **'Verify face to submit'**
  String get inspReviewVerify;

  /// Shown once the face was verified for submitting.
  ///
  /// In en, this message translates to:
  /// **'Verified at {time}'**
  String inspReviewVerified(String time);

  /// Button that sends an inspection.
  ///
  /// In en, this message translates to:
  /// **'Submit inspection'**
  String get inspSubmit;

  /// Shown while an inspection is being sent.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get inspSubmitting;

  /// Title when an inspection was sent.
  ///
  /// In en, this message translates to:
  /// **'Inspection submitted'**
  String get inspSubmittedTitle;

  /// Message when an inspection was sent.
  ///
  /// In en, this message translates to:
  /// **'Your report has been submitted.'**
  String get inspSubmittedMessage;

  /// Title when sending an inspection failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit'**
  String get inspSubmitFailedTitle;

  /// Button saving the inspection report as a PDF.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get inspSavePdf;

  /// When the PDF was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get inspPdfSaved;

  /// When saving the PDF failed.
  ///
  /// In en, this message translates to:
  /// **'The PDF couldn\'t be saved.'**
  String get inspPdfSaveFailed;

  /// Label on the report: who inspected.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspPdfInspector;

  /// Label on the report: when.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get inspPdfDate;

  /// Label on the report for the start face check.
  ///
  /// In en, this message translates to:
  /// **'Face verified at start'**
  String get inspPdfStartVerified;

  /// Label on the report for the submission face check.
  ///
  /// In en, this message translates to:
  /// **'Face verified at submission'**
  String get inspPdfSubmitVerified;

  /// On the report: a face check still to come.
  ///
  /// In en, this message translates to:
  /// **'Not yet verified'**
  String get inspPdfNotVerified;

  /// Label on the report: where the face was checked.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get inspPdfLocation;

  /// Heading of a section's photos on the report.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get inspPdfPhotos;

  /// Footer of every page of an inspection report.
  ///
  /// In en, this message translates to:
  /// **'e-Inspection report'**
  String get inspPdfFooter;

  /// On the report: a question left blank.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get inspPdfUnanswered;

  /// Count on the report of questions answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get inspPdfAnswered;

  /// Count on the report of answers that read as something wrong.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get inspPdfFindings;

  /// Moves an inspection form on to its next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get inspFormNext;

  /// On an inspection form's last step: opens the report to check and submit.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get inspFormReview;

  /// What an inspection form's choice field says before anything is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get inspFormSelect;

  /// What an inspection form's date field says before a day is picked.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get inspFormSelectDate;

  /// Title of the sheet that picks a date on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get inspFormPickDate;

  /// Takes the date picked on an inspection form's date sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inspFormDone;

  /// Label of the note asked for when an inspection answer reports a fault.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get inspFormRemarkLabel;

  /// Hint in the note asked for when an inspection answer reports a fault.
  ///
  /// In en, this message translates to:
  /// **'Describe what is wrong'**
  String get inspFormRemarkHint;

  /// Warns that a reading on an inspection form is out of its normal range.
  ///
  /// In en, this message translates to:
  /// **'Outside the expected range: {hint}'**
  String inspFormOutOfRange(String hint);

  /// How many questions on a step of an inspection are still blank.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All answered} =1{1 question left} other{{count} questions left}}'**
  String inspFormLeft(int count);

  /// How much of an inspection form is filled in.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} answered'**
  String inspFormProgress(int answered, int total);

  /// Which step of an inspection form is open.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String inspFormStepOf(int current, int total);

  /// Title of the dialog shown when leaving an inspection form part-way.
  ///
  /// In en, this message translates to:
  /// **'Leave this inspection?'**
  String get inspFormLeaveTitle;

  /// Says leaving an inspection form keeps its answers as a draft.
  ///
  /// In en, this message translates to:
  /// **'Your answers are kept as a draft on this phone, to finish later.'**
  String get inspFormLeaveDraft;

  /// Says leaving an inspection form loses its answers.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve filled in will be lost.'**
  String get inspFormLeaveLost;

  /// Leaves an inspection form part-way.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get inspFormLeave;

  /// Stays on an inspection form instead of leaving it.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get inspFormStay;

  /// Title of the dialog shown when reviewing an inspection with questions unanswered.
  ///
  /// In en, this message translates to:
  /// **'Some questions are blank'**
  String get inspFormBlankTitle;

  /// Explains that an inspection is being reviewed with blank questions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question is still blank.} other{{count} questions are still blank.}} Answer them first, or review the report with them left blank.'**
  String inspFormBlankMessage(int count);

  /// Takes the inspector to the first blank question of a form.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get inspFormShowBlank;

  /// Opens an inspection's report although questions are blank.
  ///
  /// In en, this message translates to:
  /// **'Review anyway'**
  String get inspFormReviewAnyway;

  /// Title of the dialog listing what an inspection needs before its report can be reviewed.
  ///
  /// In en, this message translates to:
  /// **'Fill these in first'**
  String get inspFormRequiredTitle;

  /// Screen reader name of the key that lowers a count on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get inspFormDecrease;

  /// Screen reader name of the key that raises a count on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get inspFormIncrease;

  /// Adds one more entry, as a point or a level crossing, to an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Add {item}'**
  String inspFormAddRow(String item);

  /// Removes an entry from a list on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get inspFormRemoveRow;

  /// Title of the dialog confirming an entry is removed from an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Remove this entry?'**
  String get inspFormRemoveRowTitle;

  /// Label of the sum of a list's figures on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get inspFormTotal;

  /// First step of an inspection form: what is inspected and when.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get inspFormDetails;

  /// Label of the station field on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get inspFormStation;

  /// Hint of the station field on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Choose the station'**
  String get inspFormStationHint;

  /// Label of the date an inspection is made on.
  ///
  /// In en, this message translates to:
  /// **'Date of inspection'**
  String get inspFormDate;

  /// Shown when the stations an inspector covers couldn't be fetched.
  ///
  /// In en, this message translates to:
  /// **'Your stations couldn\'t be loaded.'**
  String get inspFormStationsFailed;

  /// Shown when an inspector has no stations to inspect.
  ///
  /// In en, this message translates to:
  /// **'No stations are assigned to you yet.'**
  String get inspFormNoStations;

  /// Says an inspection that has no server yet was saved on the device.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get inspFormSaved;

  /// Label of the photos taken for part of an inspection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get inspFormPhotos;

  /// Takes a photo for part of an inspection.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get inspFormAddPhoto;

  /// Label of a free note on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get inspFormNote;

  /// Hint of a free note on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Anything else to record'**
  String get inspFormNoteHint;

  /// Marks every check of one item, as a signal, satisfactory at once.
  ///
  /// In en, this message translates to:
  /// **'All satisfactory'**
  String get inspFormAllGood;

  /// Shown under the fire extinguisher count while it is zero.
  ///
  /// In en, this message translates to:
  /// **'Set how many extinguishers there are to add a filling date for each.'**
  String get inspFormNoExtinguishers;

  /// Says an entry in a list on an inspection form is still blank.
  ///
  /// In en, this message translates to:
  /// **'Nothing filled in yet'**
  String get inspFormRowEmpty;

  /// Title of the station inspection form.
  ///
  /// In en, this message translates to:
  /// **'Station inspection'**
  String get inspStationTitle;

  /// What a station inspection covers, under its title.
  ///
  /// In en, this message translates to:
  /// **'Signal and telecom'**
  String get inspStationSubtitle;

  /// Title of the motor trolley inspection form.
  ///
  /// In en, this message translates to:
  /// **'Motor trolley inspection'**
  String get inspTrolleyTitle;

  /// What a motor trolley inspection covers, under its title.
  ///
  /// In en, this message translates to:
  /// **'Track, bridges and works'**
  String get inspTrolleySubtitle;

  /// Label of the remedy picked for a fault on an inspection form.
  ///
  /// In en, this message translates to:
  /// **'Remedy'**
  String get inspFormRemedy;

  /// The standard remedy for a fault, under its question.
  ///
  /// In en, this message translates to:
  /// **'Remedy: {remedy}'**
  String inspFormRemedyNote(String remedy);

  /// Label of the railway section an inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get inspFormSection;

  /// Shown when an inspection with no server yet is finished and kept on the device.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone, with its PDF. This inspection isn\'t sent online yet.'**
  String get inspFormSavedLocally;

  /// Heading of the facts about the asset being inspected.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get inspFormAsset;

  /// Tab of an inspection catalogue that starts a new inspection.
  ///
  /// In en, this message translates to:
  /// **'New inspection'**
  String get inspCatalogNew;

  /// Tab of an inspection catalogue listing inspections finished on this phone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get inspCatalogDone;

  /// Heading of the department chips in an inspection catalogue.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get inspCatalogDepartment;

  /// Heading of the sub-department chips in an inspection catalogue.
  ///
  /// In en, this message translates to:
  /// **'Sub-department'**
  String get inspCatalogSubDepartment;

  /// Heading of the list of assets that can be inspected.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get inspCatalogAssets;

  /// Shown when no inspection of a catalogue has been finished on this phone.
  ///
  /// In en, this message translates to:
  /// **'No finished inspections yet'**
  String get inspCatalogEmpty;

  /// Explains where finished catalogue inspections are kept.
  ///
  /// In en, this message translates to:
  /// **'Inspections you finish here are kept on this phone with their report.'**
  String get inspCatalogEmptyMessage;

  /// How long a finished inspection took.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String inspCatalogTook(String minutes);

  /// Title of the civil inspection catalogue.
  ///
  /// In en, this message translates to:
  /// **'Civil inspection'**
  String get inspCivilTitle;

  /// What civil inspections cover.
  ///
  /// In en, this message translates to:
  /// **'Works, track and bridges'**
  String get inspCivilSubtitle;

  /// What electrical inspections cover.
  ///
  /// In en, this message translates to:
  /// **'Power and rolling stock'**
  String get inspElectricalSubtitle;

  /// Label of the role an RTL electrical inspector inspects as.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get inspRtlRole;

  /// Heading of the places an RTL electrical inspection covers.
  ///
  /// In en, this message translates to:
  /// **'Places to inspect'**
  String get inspRtlPlaces;

  /// Shown when an RTL inspection is started with no place picked.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one place to inspect.'**
  String get inspRtlPickPlace;

  /// Opens an inspection's form once what it covers is chosen.
  ///
  /// In en, this message translates to:
  /// **'Start inspection'**
  String get inspFormStart;

  /// Title of the locomotive inspection form.
  ///
  /// In en, this message translates to:
  /// **'Locomotive inspection'**
  String get inspLocomotiveTitle;

  /// What a locomotive inspection covers, under its title.
  ///
  /// In en, this message translates to:
  /// **'GEU-40 · Mechanical'**
  String get inspLocomotiveSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
