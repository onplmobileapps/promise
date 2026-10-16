import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/app/settings/settings_view.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:railway_hrms/modules/auth/screens/forgot_password_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class MockSuccessAuthRepository implements AuthRepository {
  String? lastForgotEmail;
  String? lastOldPassword;
  String? lastNewPassword;
  String? lastConfirmPassword;

  @override
  Future<Either<AppException, Response>> forgotPassword(String email) async {
    lastForgotEmail = email;
    return Right(
      Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'message': 'Password reset link sent to your email.'},
      ),
    );
  }

  @override
  Future<Either<AppException, Response>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    lastOldPassword = oldPassword;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmNewPassword;
    return Right(
      Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {'message': 'Password changed successfully.'},
      ),
    );
  }

  @override
  Future<Either<AppException, Response>> login(
    String employeeId,
    String password,
    String fcmToken,
  ) async => Left(AppException(''));

  @override
  Future<Either<AppException, Response>> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  ) async => Left(AppException(''));
}

void main() {
  setUpAll(loadAppFonts);

  group('Forgot Password & Change Password Tests', () {
    late MockSuccessAuthRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = MockSuccessAuthRepository();
      sl.allowReassignment = true;
      sl.registerSingleton<AuthRepository>(repository);
      sl.registerSingleton<BiometricAuthenticator>(FakeBiometrics());
      sl.registerSingleton<AppearanceController>(AppearanceController());
      sl.registerSingleton<TextLookController>(TextLookController());
    });

    tearDown(sl.reset);

    testWidgets('ForgotPasswordView validates email and submits successfully', (
      tester,
    ) async {
      await pumpScreen(tester, const ForgotPasswordView());

      // Try empty submission
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Enter invalid email
      final emailField = find.byType(AppTextField);
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Enter valid email and submit
      await tester.enterText(emailField, 'testuser@example.com');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(repository.lastForgotEmail, 'testuser@example.com');
      expect(find.byType(AppDialog), findsOneWidget);
      expect(
        find.text('Password reset link sent to your email.'),
        findsOneWidget,
      );
    });

    testWidgets('SettingsView opens Change Password bottom sheet and submits', (
      tester,
    ) async {
      const user = SignedInUser(
        name: 'Test Employee',
        role: 'Engineer',
        employeeId: '12345',
      );

      await pumpScreen(tester, const SettingsView(user: user));

      // Open Change Password Sheet
      final securityRow = find.text('Change Password').first;
      await tester.ensureVisible(securityRow);
      await tester.tap(securityRow);
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsWidgets);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Fill in fields
      final fields = find.descendant(
        of: find.byType(Form),
        matching: find.byType(TextField),
      );

      await tester.enterText(fields.at(0), 'CurrentPass123');
      await tester.enterText(fields.at(1), 'NewPass123!');
      await tester.enterText(fields.at(2), 'NewPass123!');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(repository.lastOldPassword, 'CurrentPass123');
      expect(repository.lastNewPassword, 'NewPass123!');
      expect(repository.lastConfirmPassword, 'NewPass123!');

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('Password changed successfully.'), findsOneWidget);
    });
  });
}
