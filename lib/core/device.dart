import 'dart:math';

import 'package:flutter/foundation.dart';

String newDeviceId() {
  final r = Random.secure();
  String hex(int bytes) => List<String>.generate(
        bytes,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
}

String hostPlatformName() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.fuchsia:
      return 'fuchsia';
  }
}
