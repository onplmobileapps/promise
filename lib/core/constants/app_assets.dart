/// Paths of the images and data files bundled under `assets/`.
abstract final class AppAssets {
  // Brand.
  static const emblem = 'assets/logo.webp';
  static const wordmark = 'assets/logolong.png';

  /// The emblem as a PNG, for reports: PDFs can't hold WebP.
  static const emblemPng = 'assets/logo_emblem.png';

  /// The company that builds the app, for "Powered by".
  static const poweredByLogo = 'assets/logolight.png';

  // The design's 3D icons, all in the jade of the palette: the modules on
  // the home screen, and HRMS's actions.
  static const moduleHrms = 'assets/icons/3d/module_hrms.webp';
  static const moduleTracking = 'assets/icons/3d/module_tracking.webp';
  static const moduleInspection = 'assets/icons/3d/module_inspection.webp';
  static const modulePrams = 'assets/icons/3d/module_prams.webp';
  static const hrmsCheckIn = 'assets/icons/3d/hrms_check_in.webp';
  static const hrmsLeave = 'assets/icons/3d/hrms_leave.webp';
  static const hrmsAttendance = 'assets/icons/3d/hrms_attendance.webp';

  // Mobile network operators, for train tracking sign-in.
  static const operatorJazz = 'assets/jazz-logo-1.webp';
  static const operatorTelenor = 'assets/telenor.webp';
  static const operatorZong = 'assets/zong.webp';
  static const operatorUfone = 'assets/ufone.png';
  static const operatorWarid = 'assets/warid.png';
  static const operatorSco = 'assets/sco.webp';

  // Font licences, registered with the app's licence page.
  static const interLicence = 'assets/fonts/inter/OFL.txt';
  static const outfitLicence = 'assets/fonts/outfit/OFL.txt';
}
