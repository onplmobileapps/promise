import 'dart:convert';

import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/navigation/navigator_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _csrfTokenKey = 'csrf_token';
  static const String _inspectionDraftKey = 'inspection_draft';
  static const String _inspectionRecordsKey = 'inspection_records';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _keyEmpID = 'saved_emp_id';
  static const String _keyPassword = 'saved_password';
  static const String _fcmTokenKey = 'fcm_token';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? csrfToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _signingOut = false;
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
      prefs.setString(_csrfTokenKey, csrfToken ?? ''),
    ]);
  }

  static Future<void> saveUserCredentials({
    String? empID,
    String? password,
  }) async {
    if (empID == null || password == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmpID, empID);
    await prefs.setString(_keyPassword, password);
  }

  static Future<Map<String, String>?> getUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final empID = prefs.getString(_keyEmpID);
    final password = prefs.getString(_keyPassword);

    if (empID != null &&
        password != null &&
        empID.isNotEmpty &&
        password.isNotEmpty) {
      return {'empID': empID, 'password': password};
    }
    return null;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<void> saveFcmToken(String fcm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, fcm);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Get Token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Save User Data (Complex Object)
  static Future<void> saveUser(LoginResponse user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await saveTokens(
      accessToken: user.tokens?.access ?? '',
      refreshToken: user.tokens?.refresh ?? '',
      csrfToken: user.tokens?.csrf ?? "",
    );
    await prefs.setString(_userKey, userJson);
  }

  // Get User Data
  static Future<LoginResponse?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return LoginResponse.fromJson(jsonDecode(userJson));
  }

  static Future<void> saveInspectionDraft(String id, String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_inspectionDraftKey}_$id', payload);
  }

  static Future<String?> getInspectionDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_inspectionDraftKey}_$id');
  }

  static Future<void> clearInspectionDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_inspectionDraftKey}_$id');
  }

  static Future<void> deleteInspectionRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getInspectionRecords();
    records.removeWhere((item) => item['id']?.toString() == id);
    await prefs.setString(_inspectionRecordsKey, jsonEncode(records));
    await clearInspectionDraft(id);
  }

  static Future<void> saveInspectionRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getInspectionRecords();
    records.removeWhere((item) => item['id'] == record['id']);
    records.insert(0, record);
    await prefs.setString(_inspectionRecordsKey, jsonEncode(records));
  }

  static Future<List<Map<String, dynamic>>> getInspectionRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_inspectionRecordsKey);
    if (value == null || value.isEmpty) return [];
    final decoded = jsonDecode(value);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Delete All Data (Logout)
  /// The splash clears a stale session without [navigate], so it stays on
  /// screen; everywhere else this sends the user to the login screen.
  static Future<void> clearAuthData({bool navigate = true}) async {
    final prefs = await SharedPreferences.getInstance();
    // The session's tokens go with it, so nothing signed in is sent from
    // the sign-in screen.
    await Future.wait([
      for (final key in [
        _tokenKey,
        _userKey,
        _accessTokenKey,
        _refreshTokenKey,
        _csrfTokenKey,
      ])
        prefs.remove(key),
    ]);
    // Several requests refused at once sign out once: one sign-in screen,
    // with nothing left under it to go back to.
    if (navigate && !_signingOut) {
      _signingOut = true;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  /// A sign-out is on its way to the sign-in screen; cleared on signing in.
  static bool _signingOut = false;
}
