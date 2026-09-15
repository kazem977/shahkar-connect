import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const Size kVpnaiWindow = Size(400, 680);

bool get isDesktopShell {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

Future<void> configureDesktopWindow() async {
  if (!isDesktopShell) return;
  try {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: kVpnaiWindow,
      minimumSize: kVpnaiWindow,
      maximumSize: kVpnaiWindow,
      center: true,
      backgroundColor: Color(0xFF0B0E13),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'vpnai',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (_) {
    // Widget tests and missing plugins skip native window chrome.
  }
}

Future<void> closeVpnaiWindow() async {
  try {
    await windowManager.close();
  } catch (_) {}
}

Future<void> minimizeVpnaiWindow() async {
  try {
    await windowManager.minimize();
  } catch (_) {}
}
