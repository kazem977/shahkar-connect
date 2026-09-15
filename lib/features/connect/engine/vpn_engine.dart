import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/features/connect/engine/channel_vpn_engine.dart';
import 'package:shahkar_connect/features/connect/engine/desktop_vpn_engine.dart';

enum ConnectionStateKind { idle, connecting, connected, optimizing, error }

class ConnectionStateSnap {
  const ConnectionStateSnap({required this.kind, this.message, this.nodeName});

  final ConnectionStateKind kind;
  final String? message;
  final String? nodeName;
}

class TrafficStats {
  const TrafficStats({this.upBytes = 0, this.downBytes = 0});
  final int upBytes;
  final int downBytes;
}

class SingBoxConfig {
  const SingBoxConfig({required this.json});
  final String json;
}

class VpnUnavailableException implements Exception {
  VpnUnavailableException([
    this.message = 'تونل نیتیو روی این دستگاه آماده نیست.',
  ]);
  final String message;
  @override
  String toString() => message;
}

/// Platform VPN control. Android/iOS use a method channel; desktop uses sing-box.
abstract class VpnEngine {
  Future<void> connect(SingBoxConfig config);
  Future<void> disconnect();
  Stream<ConnectionStateSnap> get stateStream;
  Stream<TrafficStats> get trafficStream;

  static VpnEngine forPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return ChannelVpnEngine();
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return DesktopVpnEngine();
      default:
        return StubVpnEngine();
    }
  }
}

class StubVpnEngine implements VpnEngine {
  final _state = StreamController<ConnectionStateSnap>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();

  @override
  Future<void> connect(SingBoxConfig config) async {
    if (config.json.trim().isEmpty || config.json.trim() == '{}') {
      throw VpnUnavailableException(
        'کانفیگ تونل خالی است. پنل باید /client/tunnel-config را برگرداند.',
      );
    }
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.connecting));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _state.add(
      const ConnectionStateSnap(
        kind: ConnectionStateKind.connected,
        message: 'Stub engine (no kernel tun).',
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.idle));
  }

  @override
  Stream<ConnectionStateSnap> get stateStream => _state.stream;

  @override
  Stream<TrafficStats> get trafficStream => _traffic.stream;
}
