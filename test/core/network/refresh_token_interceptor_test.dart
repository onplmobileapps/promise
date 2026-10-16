import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'refresh-1',
      'csrf_token': 'csrf-1',
    }),
  );

  test(
    'an expired session is renewed and a form with files goes again',
    () async {
      final api = FakeHttpAdapter([
        (401, {'detail': 'Token expired'}),
        (201, {'id': 185}),
      ]);
      final renew = FakeHttpAdapter([
        (
          200,
          {'access': 'new', 'refresh': 'refresh-2', 'csrf_token': 'csrf-2'},
        ),
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://hrms.test/api/'))
        ..httpClientAdapter = api;
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://hrms.test/api/'))
        ..httpClientAdapter = renew;
      dio.interceptors.add(
        RefreshTokenInterceptor(dio: dio, refreshDio: refreshDio),
      );

      final response = await dio.post<dynamic>(
        '/employees/uploadAttachment',
        data: FormData()
          ..fields.add(const MapEntry('emp', '135387'))
          ..files.add(
            MapEntry(
              'attachment',
              MultipartFile.fromBytes([1, 2, 3], filename: 'cnic.jpg'),
            ),
          ),
        options: Options(headers: {'Authorization': 'Bearer old'}),
      );

      expect(response.statusCode, 201);
      expect(api.requests, hasLength(2));
      expect(api.requests.last.headers['Authorization'], 'Bearer new');
      // The form went again, files and all.
      final sentAgain = api.requests.last.data as FormData;
      expect(sentAgain.fields.single.value, '135387');
      expect(sentAgain.files.single.value.filename, 'cnic.jpg');
      // The new tokens are kept: the session goes on.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), 'new');
      expect(prefs.getString('refresh_token'), 'refresh-2');
      expect(prefs.getString('csrf_token'), 'csrf-2');
    },
  );
}
