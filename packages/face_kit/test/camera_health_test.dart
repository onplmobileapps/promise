import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _width = 64;
const _height = 48;

/// An NV21 frame whose brightness plane is [pixel] at each point.
CameraImage _frame(int Function(int i) pixel) {
  final bytes = Uint8List(_width * _height * 3 ~/ 2);
  for (var i = 0; i < _width * _height; i++) {
    bytes[i] = pixel(i);
  }
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData({
    'format': 17, // NV21, as Android sends it.
    'width': _width,
    'height': _height,
    'planes': [
      {
        'bytes': bytes,
        'bytesPerRow': _width,
        'bytesPerPixel': 1,
        'width': _width,
        'height': _height,
      },
    ],
  });
}

void main() {
  group('CameraHealth.faultOf', () {
    test('tells a refused camera', () {
      expect(
        CameraHealth.faultOf(CameraException('CameraAccessDenied', 'no')),
        CameraFault.denied,
      );
      expect(
        CameraHealth.faultOf(
          CameraException('CameraAccessRestricted', 'parental controls'),
        ),
        CameraFault.denied,
      );
    });

    test('tells a camera another app holds', () {
      expect(
        CameraHealth.faultOfText(
          'The camera was already in use, possibly by a higher-priority '
          'camera client.',
        ),
        CameraFault.busy,
      );
      expect(
        CameraHealth.faultOf(
          CameraException('CameraAccess', 'CAMERA_IN_USE (4): in use'),
        ),
        CameraFault.busy,
      );
    });

    test('tells a camera shut by a policy or Do Not Disturb', () {
      expect(
        CameraHealth.faultOfText(
          'The camera device could not be opened due to a device policy.',
        ),
        CameraFault.disabled,
      );
      expect(
        CameraHealth.faultOfText(
          'The camera could not be opened because "Do Not Disturb" mode is '
          'enabled.',
        ),
        CameraFault.doNotDisturb,
      );
    });

    test('takes a fatal error or a hang as a broken camera', () {
      expect(
        CameraHealth.faultOfText(
          'The camera was closed due to a fatal error. This may indicate a '
          'persistent camera hardware problem.',
        ),
        CameraFault.broken,
      );
      expect(
        CameraHealth.faultOf(TimeoutException('initialize')),
        CameraFault.broken,
      );
      expect(
        CameraHealth.faultOf(PlatformException(code: 'no_available_camera')),
        CameraFault.missing,
      );
    });

    test('lets a camera recover by itself', () {
      expect(
        CameraHealth.faultOfText(
          'The camera device has encountered a recoverable error. CameraX '
          'will attempt to recover from the error.',
        ),
        isNull,
      );
    });
  });

  group('CameraWatchdog', () {
    late DateTime now;
    late List<CameraFault> faults;
    late CameraWatchdog watchdog;

    setUp(() {
      now = DateTime(2026, 10, 17, 9);
      faults = [];
      watchdog = CameraWatchdog(onFault: faults.add, now: () => now);
    });

    /// Shows [frame] once every 33 ms (30 a second) for [seconds].
    void feed(CameraImage Function(int n) frame, double seconds) {
      final count = (seconds * 30).round();
      for (var n = 0; n < count; n++) {
        watchdog.look(frame(n));
        now = now.add(const Duration(milliseconds: 33));
      }
    }

    test('reports a camera that sends no picture', () async {
      final slow = CameraWatchdog(
        onFault: faults.add,
        firstFrameWithin: const Duration(milliseconds: 20),
      )..start();
      expect(faults, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      slow.stop();
      expect(faults, [CameraFault.noPicture]);
    });

    test('a first picture stops the wait for one', () async {
      final quick = CameraWatchdog(
        onFault: faults.add,
        firstFrameWithin: const Duration(milliseconds: 20),
        now: () => now,
      )..start();
      final noise = Random(4);
      quick.look(_frame((_) => 90 + noise.nextInt(60)));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      quick.stop();
      expect(faults, isEmpty);
    });

    test('reports a sensor that gives only flat black', () {
      watchdog.start();
      feed((_) => _frame((_) => 0), 5);
      watchdog.stop();
      expect(faults, [CameraFault.black]);
    });

    test('reports a picture that never changes', () {
      watchdog.start();
      final scene = Random(1);
      final still = List.generate(_width * _height, (_) => scene.nextInt(256));
      feed((_) => _frame((i) => still[i]), 5);
      watchdog.stop();
      expect(faults, [CameraFault.frozen]);
    });

    test('trusts a camera whose picture has noise, even a dark one', () {
      watchdog.start();
      final noise = Random(2);
      // A dark room: a low, grainy picture.
      feed((_) => _frame((_) => 4 + noise.nextInt(12)), 6);
      expect(faults, isEmpty);
    });

    test('does not report a brief black, as a hand passing the lens', () {
      watchdog.start();
      final noise = Random(3);
      feed((_) => _frame((_) => 0), 1);
      feed((_) => _frame((_) => 90 + noise.nextInt(60)), 4);
      feed((_) => _frame((_) => 0), 6);
      expect(faults, isEmpty);
    });
  });
}
