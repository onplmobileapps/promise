import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/config/app_env.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/modules/hrms/utils/cnic_capture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory folder;
  late XFile cnic;
  late XFile face;

  setUpAll(() => AppEnv.loadFromString('BASE_URL=https://hrms.test/api/'));

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'token'});
    folder = Directory.systemTemp.createTempSync('attachments');
    cnic = XFile(
      (File('${folder.path}/cnic.jpg')..writeAsBytesSync([1, 2, 3])).path,
    );
    face = XFile(
      (File('${folder.path}/face.jpg')..writeAsBytesSync([4, 5, 6])).path,
    );
  });

  tearDown(() => folder.deleteSync(recursive: true));

  /// The app's client, its network [replies] given.
  FakeHttpAdapter network(List<Object> replies) =>
      DioClient().dio.httpClientAdapter = FakeHttpAdapter(replies);

  test('the CNIC and the face go in one multipart request', () async {
    final sent = network([
      (
        201,
        [
          {'id': 185},
        ],
      ),
    ]);

    final problem = await uploadCnicAttachment(
      cnic,
      employeeId: '135387',
      facePhoto: face,
      client: DioClient(),
    );

    expect(problem, isNull);
    final request = sent.requests.single;
    expect(
      request.uri.toString(),
      'https://hrms.test/api/employees/uploadAttachment',
    );
    expect(request.method, 'POST');
    expect(request.headers['Authorization'], 'Bearer token');
    final form = request.data as FormData;
    expect(form.fields.map((field) => '${field.key}=${field.value}'), [
      'emp=135387',
      'attachment_type=2',
      'attachment_type=3',
    ]);
    expect(form.files.map((file) => '${file.key}=${file.value.filename}'), [
      'attachment=cnic.jpg',
      'attachment=face.jpg',
    ]);
  });

  test("the server's refusal is told", () async {
    network([
      (406, {'Error': 'Attachment type not allowed'}),
    ]);

    final problem = await uploadCnicAttachment(
      cnic,
      employeeId: '135387',
      facePhoto: face,
      client: DioClient(),
    );

    expect(problem, 'Attachment type not allowed');
  });

  test('a server error is told', () async {
    network([(500, null)]);

    final problem = await uploadCnicAttachment(
      cnic,
      employeeId: '135387',
      client: DioClient(),
    );

    expect(problem, 'Internal server error');
  });

  test('no connection is told', () async {
    network([const SocketException('Network is unreachable')]);

    final problem = await uploadCnicAttachment(
      cnic,
      employeeId: '135387',
      client: DioClient(),
    );

    expect(problem, contains("Can't reach the server"));
  });
}
