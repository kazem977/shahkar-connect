import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/features/connect/balancer/failover.dart';
import 'package:shahkar_connect/features/connect/balancer/node_probe.dart';
import 'package:shahkar_connect/features/connect/engine/traffic_rate.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

class SessionController extends ChangeNotifier {
  SessionController({required ApiClient api, required VpnEngine engine})
    : _api = api,
      _engine = engine {
    _engineSub = _engine.stateStream.listen((s) {
      engineState = s;
      if (s.kind == ConnectionStateKind.error && selected != null && !busy) {
        unawaited(_failover(reason: s.message));
      }
      notifyListeners();
    });
    _trafficSub = _engine.trafficStream.listen((t) {
      stats = t;
      rate = _rate.update(
        TrafficStatsSample(
          upBytes: t.upBytes,
          downBytes: t.downBytes,
          at: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }

  final ApiClient _api;
  final VpnEngine _engine;
  final TrafficRate _rate = TrafficRate();
  StreamSubscription<ConnectionStateSnap>? _engineSub;
  StreamSubscription<TrafficStats>? _trafficSub;
  Timer? _heartbeat;
  List<NodeCandidate> _ranked = [];

  Entitlement? entitlement;
  NodeCandidate? selected;
  String? error;
  ConnectionStateSnap engineState = const ConnectionStateSnap(
    kind: ConnectionStateKind.idle,
  );
  TrafficStats stats = const TrafficStats();
  TrafficSnapshot rate = const TrafficSnapshot();
  bool busy = false;

  Future<void> refreshEntitlement() async {
    final res = await _api.dio.get('/api/v1/entitlement/me');
    entitlement = Entitlement.fromJson(res.data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> connect() async {
    error = null;
    busy = true;
    notifyListeners();
    try {
      await refreshEntitlement();
      if (entitlement?.canConnect != true) {
        error =
            'حساب کاربری شما پلن فعال ندارد. برای فعال‌سازی به پشتیبانی مراجعه کنید.';
        return;
      }
      final res = await _api.dio.get('/api/v1/balancer/candidates');
      final raw =
          (res.data['candidates'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      final candidates = raw.map(NodeCandidate.fromJson).toList();
      _ranked = await rankHealthyNodes(candidates);
      selected = _ranked.first;
      await _bindSelected(successProbe: true);
    } on NoHealthyNodeException {
      error = 'سرور مناسبی پیدا نشد. کمی بعد دوباره تلاش کنید.';
    } on VpnUnavailableException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _heartbeat?.cancel();
    await _engine.disconnect();
    try {
      await _api.dio.post(
        '/api/v1/telemetry/disconnect',
        data: {
          'node_id': selected?.id,
          'bytes_up': stats.upBytes,
          'bytes_down': stats.downBytes,
        },
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _bindSelected({required bool successProbe}) async {
    final node = selected;
    if (node == null) return;
    await _api.dio.post(
      '/api/v1/balancer/report-selection',
      data: {'node_id': node.id, 'success': successProbe},
    );
    final tun = await _api.dio.get(
      '/api/v1/client/tunnel-config',
      queryParameters: {'node_id': node.id},
    );
    final cfg = TunnelConfig.fromJson(tun.data as Map<String, dynamic>);
    await _engine.connect(SingBoxConfig(json: cfg.singboxJson));
    _startHeartbeat();
  }

  Future<void> _failover({String? reason}) async {
    final current = selected;
    if (current == null || _ranked.isEmpty) return;
    final nxt = nextCandidate(_ranked, current);
    if (nxt == null) {
      error = reason ?? 'همه نامزدها از دسترس خارج شدند.';
      await disconnect();
      return;
    }
    engineState = ConnectionStateSnap(
      kind: ConnectionStateKind.optimizing,
      message: 'جابه‌جایی سرور',
      nodeName: nxt.name,
    );
    notifyListeners();
    try {
      await _engine.disconnect();
      selected = nxt;
      await _bindSelected(successProbe: false);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await _api.dio.post(
          '/api/v1/telemetry/heartbeat',
          data: {
            'node_id': selected?.id,
            'bytes_up': stats.upBytes,
            'bytes_down': stats.downBytes,
            'platform': defaultTargetPlatform.name,
          },
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _engineSub?.cancel();
    _trafficSub?.cancel();
    super.dispose();
  }
}
