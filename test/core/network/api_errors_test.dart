import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/config/app_env.dart';
import 'package:railway_hrms/core/error/api_error_text.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/auth/data/auth_remote_datasource.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => AppEnv.loadFromString('BASE_URL=https://hrms.test/api/'));
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'access_token': 'old-token',
      'refresh_token': 'refresh',
    }),
  );

  FakeHttpAdapter network(List<Object> replies) =>
      DioClient().dio.httpClientAdapter = FakeHttpAdapter(replies);

  AuthRepositoryImpl repository() =>
      AuthRepositoryImpl(AuthRemoteDataSourceImpl(DioClient()));

  Future<AppException?> changePassword() async =>
      (await repository().changePassword(
        oldPassword: 'old',
        newPassword: 'n3w-Pass!',
        confirmNewPassword: 'n3w-Pass!',
      )).fold((error) => error, (_) => null);

  test('a refusal reads as what the server said, field by field', () {
    expect(ApiErrorText.of({'detail': 'Not found.'}), 'Not found.');
    expect(
      ApiErrorText.of({
        'old_password': ['Wrong password.'],
        'new_password': ['This password is too common.', 'Too short.'],
      }),
      'Old password: Wrong password.\nNew password: This password is too common.',
    );
    expect(
      ApiErrorText.of({
        'status': false,
        'non_field_errors': ['Passwords do not match.'],
      }),
      'Passwords do not match.',
    );
    expect(ApiErrorText.of('<html>502</html>'), isNull);
    expect(ApiErrorText.of(null), isNull);
  });

  test('change password shows why the server refused it', () async {
    final sent = network([
      (
        400,
        {
          'old_password': ['Wrong password.'],
        },
      ),
    ]);
    final error = await changePassword();
    expect(error, isA<ServerException>());
    expect(error!.message, 'Old password: Wrong password.');
    expect(
      sent.requests.single.data,
      containsPair('confirm_password', 'n3w-Pass!'),
    );
  });

  test('a server that takes the change as PUT gets it again as PUT', () async {
    final sent = network([
      (405, {'detail': 'Method "POST" not allowed.'}),
      (200, {'message': 'Password changed.'}),
    ]);
    expect(await changePassword(), isNull);
    expect(sent.requests.map((r) => r.method), ['POST', 'PUT']);
  });

  test('a "no" sent with a 200 is a failure', () async {
    network([
      (200, {'status': false, 'message': 'Old password is incorrect'}),
    ]);
    expect((await changePassword())!.message, 'Old password is incorrect');
  });

  test('a request refused again after renewing the session does not sign '
      'the user out', () async {
    final sent = network([
      (401, {'detail': 'Token expired'}),
      (
        400,
        {
          'old_password': ['Wrong password.'],
        },
      ),
    ]);
    DioClient().refreshDio.httpClientAdapter = FakeHttpAdapter([
      (200, {'access': 'new-token', 'refresh': 'r2', 'csrf_token': 'c'}),
    ]);
    final error = await changePassword();
    expect(error!.message, 'Old password: Wrong password.');
    expect(sent.requests.last.headers['Authorization'], 'Bearer new-token');
    expect(await StorageService.getAccessToken(), 'new-token');
  });

  test('no connection reads as a network failure', () async {
    network([
      DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'offline',
      ),
    ]);
    expect(await changePassword(), isA<NetworkException>());
  });
}
