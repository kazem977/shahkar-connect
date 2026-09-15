import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// The network the machine is currently attached to.
class NetworkIdentity {
  const NetworkIdentity({required this.ssid, required this.secured});

  static const none = NetworkIdentity(ssid: '', secured: true);

  /// Empty for wired links or when the SSID cannot be read.
  final String ssid;

  /// False for open Wi-Fi, which is the classic place to get intercepted.
  final bool secured;

  bool get isWifi => ssid.isNotEmpty;
}

/// Watches which network is in use so protection can follow the user around.
///
/// Joining an open café hotspot is exactly when a tunnel matters most and
/// exactly when people forget to switch it on; joining the home network is when
/// they want full speed. This turns both into automatic behaviour.
class NetworkWatcher extends ChangeNotifier {
  NetworkWatcher();

  static const _interval = Duration(seconds: 8);

  Timer? _timer;
  NetworkIdentity current = NetworkIdentity.none;

  /// Fired when the machine moves to a different network.
  void Function(NetworkIdentity network)? onChanged;

  void start() {
    _timer ??= Timer.periodic(_interval, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final next = await _read();
    if (next.ssid == current.ssid && next.secured == current.secured) return;
    current = next;
    notifyListeners();
    onChanged?.call(next);
  }

  Future<NetworkIdentity> _read() async {
    if (!Platform.isWindows) return NetworkIdentity.none;
    try {
      final res = await Process.run(
        'netsh',
        ['wlan', 'show', 'interfaces'],
        runInShell: true,
      );
      final text = '${res.stdout}';
      final ssid = _field(text, r'^\s*SSID\s*:\s*(.+)$');
      final auth = _field(text, r'^\s*Authentication\s*:\s*(.+)$');
      if (ssid == null || ssid.isEmpty) return NetworkIdentity.none;
      final open = auth != null && auth.toLowerCase().contains('open');
      return NetworkIdentity(ssid: ssid, secured: !open);
    } catch (_) {
      return NetworkIdentity.none;
    }
  }

  String? _field(String text, String pattern) {
    for (final line in text.split('\n')) {
      final match = RegExp(pattern).firstMatch(line.trimRight());
      if (match != null) {
        final value = match.group(1)?.trim();
        // "BSSID" also matches a loose SSID pattern; skip empty captures.
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }
}
