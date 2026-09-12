import 'dart:async';

enum ConnectionStateKind { idle, connecting, connected, optimizing, error }

class ConnectionStateSnap {
  const ConnectionStateSnap({
    required this.kind,
    this.message,
    this.nodeName,
  });

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

/// Platform VPN control. Phase 4 fills Android/iOS/desktop bindings.
abstract class VpnEngine {
  Future<void> connect(SingBoxConfig config);
  Future<void> disconnect();
  Stream<ConnectionStateSnap> get stateStream;
  Stream<TrafficStats> get trafficStream;

  static VpnEngine forPlatform() => StubVpnEngine();
}

class StubVpnEngine implements VpnEngine {
  final _state = StreamController<ConnectionStateSnap>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();

  @override
  Future<void> connect(SingBoxConfig config) async {
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.connecting));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _state.add(
      const ConnectionStateSnap(
        kind: ConnectionStateKind.connected,
        message: 'Native tunnel is not bound yet (phase 4).',
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
