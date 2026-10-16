import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/update/app_info.dart';

void main() {
  AppInfo app(String version) =>
      AppInfo(version: version, build: '1', id: 'com.example');

  test('a later version is newer, part by part', () {
    expect(app('1.0.9').isOlderThan('1.0.10'), isTrue);
    expect(app('1.0.9').isOlderThan('1.1'), isTrue);
    expect(app('1.2.0').isOlderThan('1.1.9'), isFalse);
    expect(app('1.0.9').isOlderThan('1.0.9'), isFalse);
    expect(app('1.0').isOlderThan('1.0.0'), isFalse);
  });
}
