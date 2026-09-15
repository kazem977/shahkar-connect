import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

const vpnMethodChannel = MethodChannel('com.shahkar.connect/vpn');
const vpnStateChannel = EventChannel('com.shahkar.connect/vpn_state');
const vpnStatsChannel = EventChannel('com.shahkar.connect/vpn_stats');

class ChannelVpnEngine implements VpnEngine {
  ChannelVpnEngine({
    MethodChannel? methods,
    EventChannel? state,
    EventChannel? stats,
  }) : _methods = methods ?? vpnMethodChannel,
       _stateEvents = state ?? vpnStateChannel,
       _statsEvents = stats ?? vpnStatsChannel;

  final MethodChannel _methods;
  final EventChannel _stateEvents;
  final EventChannel _statsEvents;

  @override
  Future<void> connect(SingBoxConfig config) async {
    try {
      await _methods.invokeMethod<void>('start', {'json': config.json});
    } on MissingPluginException {
      throw VpnUnavailableException();
    } on PlatformException catch (e) {
      throw VpnUnavailableException(e.message ?? e.code);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Already unbound.
    }
  }

  @override
  Stream<ConnectionStateSnap> get stateStream =>
      _stateEvents.receiveBroadcastStream().map(_decodeState);

  @override
  Stream<TrafficStats> get trafficStream =>
      _statsEvents.receiveBroadcastStream().map(_decodeStats);

  static ConnectionStateSnap _decodeState(dynamic raw) {
    if (raw is Map) {
      final kind = raw['kind'] as String? ?? 'idle';
      return ConnectionStateSnap(
        kind: ConnectionStateKind.values.firstWhere(
          (k) => k.name == kind,
          orElse: () => ConnectionStateKind.idle,
        ),
        message: raw['message'] as String?,
        nodeName: raw['nodeName'] as String?,
      );
    }
    return const ConnectionStateSnap(kind: ConnectionStateKind.idle);
  }

  static TrafficStats _decodeStats(dynamic raw) {
    if (raw is Map) {
      return TrafficStats(
        upBytes: (raw['upBytes'] as num?)?.toInt() ?? 0,
        downBytes: (raw['downBytes'] as num?)?.toInt() ?? 0,
      );
    }
    return const TrafficStats();
  }
}
