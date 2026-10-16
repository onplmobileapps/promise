import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    File('/private/tmp/claude-501/-Users-muhammadhaseebjavaid-StudioProjects-railway-hrms/8aedd321-ad71-4a7e-9b06-1a969cdef7ce/scratchpad/shots/$name.png').writeAsBytesSync(bytes);
    return true;
  },
);
