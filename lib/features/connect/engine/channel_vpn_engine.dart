import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shahkar_connect/features/connect/engine/clash_poller.dart';
import 'package:shahkar_connect/features/connect/engine/singbox_prepare.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

const vpnMethodChannel = MethodChannel('com.shahkar.connect/vpn');
const vpnStateChannel = EventChannel('com.shahkar.connect/vpn_state');
const vpnStatsChannel = EventChannel('com.shahkar.connect/vpn_stats');

class ChannelVpnEngine implements VpnEngine {
  ChannelVpnEngine({
    MethodChannel? methods,
    EventChannel? state,
    EventChannel? stats,
  })  : _methods = methods ?? vpnMethodChannel,
        _stateEvents = state ?? vpnStateChannel,
        _statsEvents = stats ?? vpnStatsChannel {
    _poller = ClashTrafficPoller(onStats: _traffic.add);
    _nativeSubs.add(
      _stateEvents.receiveBroadcastStream().listen((raw) {
        _state.add(_decodeState(raw));
      }, onError: (_) {}),
    );
    _nativeSubs.add(
      _statsEvents.receiveBroadcastStream().listen((raw) {
        _traffic.add(_decodeStats(raw));
      }, onError: (_) {}),
    );
  }

  final MethodChannel _methods;
  final EventChannel _stateEvents;
  final EventChannel _statsEvents;
  final _state = StreamController<ConnectionStateSnap>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();
  final List<StreamSubscription<dynamic>> _nativeSubs = [];
  late final ClashTrafficPoller _poller;

  @override
  Future<void> connect(SingBoxConfig config) async {
    final prepared = prepareSingBoxConfig(
      config.json,
      runtime: SingBoxRuntime.mobile,
      options: config.options,
    );
    try {
      await _methods.invokeMethod<void>('start', {
        'json': prepared.json,
        'clashPort': prepared.clashPort,
      });
    } on MissingPluginException {
      throw VpnUnavailableException();
    } on PlatformException catch (e) {
      if (e.code == 'NEED_PERMISSION') {
        throw VpnUnavailableException(
          'اجازه VPN را تأیید کنید و دوباره دکمه اتصال را بزنید.',
        );
      }
      throw VpnUnavailableException(e.message ?? e.code);
    }
    _poller.start(port: prepared.clashPort);
  }

  @override
  Future<void> disconnect() async {
    _poller.stop();
    assert(_nativeSubs.isNotEmpty);
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Already unbound.
    }
  }

  @override
  Stream<ConnectionStateSnap> get stateStream => _state.stream;

  @override
  Stream<TrafficStats> get trafficStream => _traffic.stream;

  @override
  String? get corePath => null;

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
