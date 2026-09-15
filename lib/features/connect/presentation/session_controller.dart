import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/features/connect/balancer/node_probe.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

class SessionController extends ChangeNotifier {
  SessionController({required ApiClient api, required VpnEngine engine})
    : _api = api,
      _engine = engine {
    _engineSub = _engine.stateStream.listen((s) {
      engineState = s;
      notifyListeners();
    });
  }

  final ApiClient _api;
  final VpnEngine _engine;
  StreamSubscription<ConnectionStateSnap>? _engineSub;
  Timer? _heartbeat;

  Entitlement? entitlement;
  NodeCandidate? selected;
  String? error;
  ConnectionStateSnap engineState = const ConnectionStateSnap(
    kind: ConnectionStateKind.idle,
  );
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
      selected = await selectBestNode(candidates);
      await _api.dio.post(
        '/api/v1/balancer/report-selection',
        data: {'node_id': selected!.id, 'success': true},
      );
      // Tunnel JSON arrives from the existing client config API in phase 4.
      await _engine.connect(const SingBoxConfig(json: '{}'));
      _startHeartbeat();
    } on NoHealthyNodeException {
      error = 'سرور مناسبی پیدا نشد. کمی بعد دوباره تلاش کنید.';
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
        data: {'node_id': selected?.id},
      );
    } catch (_) {}
    notifyListeners();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await _api.dio.post(
          '/api/v1/telemetry/heartbeat',
          data: {
            'node_id': selected?.id,
            'bytes_up': 0,
            'bytes_down': 0,
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
    super.dispose();
  }
}
