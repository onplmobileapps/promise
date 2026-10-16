import 'package:railway_hrms/core/config/app_env.dart';

class ApiEndpoints {
  static String baseUrl = AppEnv.get('BASE_URL_FACE_AUTH');
  static String faceRegister = "$baseUrl/register";
  static String faceVerify = "$baseUrl/verify";
  static String base = AppEnv.get('BASE_URL');
  //yumna local server
  // static String base = "http://10.0.121.56:8001/api/";
  static const String employeeDetails = "/attendance/getEmpAtt";
  static const String login = "/account/login";
  static const String forgotPassword = "/account/forgot-password";
  static const String changePassword = "/account/users/change-password/";
  static const String markAttendance = "/attendance/markAttendance";
  static const String getAttendance = "/attendance/getAttendance";
  static const String getEmpLeaveLedger = "/attendance/getEmpLeaveLedger";
  static const String getEmpLeaveList = "/attendance/getEmpLeaveList";
  static const String applyLeave = "/attendance/applyEmpLeave";
  static const String getRecentEmployees = "/organization/getAttendanceEmpList";
  static const String adminDashCounts = "/attendance/adminDashCounts";
  static const String getActiveList = "/attendance/getActiveList";
  static const String getAllRequests = '/attendance/getAllRequests';
  static const String approveLeave = '/attendance/approveLeave';
  static const String applyChangeRequest = '/attendance/applyChangeRequest';
  static const String approveChangeRequest = '/attendance/approveChangeRequest';
  static const String getTrainsUrl =
      'https://pakistanrailway.org/api/tracking/mobile/';
  static const String getStationsUrl =
      'https://pakistanrailway.org/api/tracking/station/';
  static const String submitInspection = 'footplate/inspection/submit/';
  static const String userStations = 'inspection/signal-telecom/user_stations/';
  static const String submitStationInspectionComplete =
      'inspection/signal-telecom/submit_complete/';
  static const String submitMotorTrolleyComplete =
      'inspection/motor-trolley/submit_complete/';
  static const String getactivetrains = '/accidents/active-trains';
  static const String reportaccident = '/accidents/';
  static const String getAccidentById = '/accidents/';
  static const String uploadCNIC = '/employees/uploadAttachment';
  static const String getCheckImage = '/attendance/getCheckImage';
}
