import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shahkar_connect/features/connect/engine/singbox_prepare.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

/// Polls sing-box Clash API `/connections` for cumulative byte counters.
class ClashTrafficPoller {
  ClashTrafficPoller({this.onStats});

  void Function(TrafficStats stats)? onStats;
  int _port = clashApiPort;

  Timer? _timer;
  HttpClient? _client;

  void start({int port = clashApiPort}) {
    stop();
    _port = port;
    _client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 600);
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    final client = _client;
    final emit = onStats;
    if (client == null || emit == null) return;
    try {
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$_port/connections'),
      );
      final res = await req.close().timeout(const Duration(milliseconds: 800));
      if (res.statusCode != 200) return;
      final body = await utf8.decodeStream(res);
      final json = jsonDecode(body);
      if (json is! Map) return;
      emit(
        TrafficStats(
          upBytes: (json['uploadTotal'] as num?)?.toInt() ?? 0,
          downBytes: (json['downloadTotal'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (_) {
      // Clash API is optional until libbox/sing-box is actually running.
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _client?.close(force: true);
    _client = null;
  }
}
