import 'package:flutter_test/flutter_test.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/features/connect/balancer/failover.dart';
import 'package:shahkar_connect/features/connect/engine/traffic_rate.dart';

void main() {
  NodeCandidate n(int id) =>
      NodeCandidate(id: id, name: 'n$id', host: 'n$id.example', port: 443);

  test('nextCandidate walks the ranked list then stops', () {
    final ranked = [n(1), n(2), n(3)];
    expect(nextCandidate(ranked, n(1))!.id, 2);
    expect(nextCandidate(ranked, n(2))!.id, 3);
    expect(nextCandidate(ranked, n(3)), isNull);
    expect(nextCandidate(ranked, n(9)), isNull);
  });

  test('traffic rate uses byte deltas over wall time', () {
    final rate = TrafficRate();
    final t0 = DateTime.utc(2026, 1, 1, 0, 0, 0);
    rate.update(TrafficStatsSample(upBytes: 0, downBytes: 0, at: t0));
    final snap = rate.update(
      TrafficStatsSample(
        upBytes: 1024,
        downBytes: 2048,
        at: t0.add(const Duration(seconds: 1)),
      ),
    );
    expect(snap.upBps, 1024);
    expect(snap.downBps, 2048);
    expect(formatBps(1024), '1.0 KB/s');
  });

  test('parses tunnel config json without exposing extra fields', () {
    final tun = TunnelConfig.fromJson({
      'node_id': 4,
      'node_name': 'de-1',
      'host': 'vpn.example.net',
      'port': 443,
      'sni': 'www.example.com',
      'singbox_json': '{"outbounds":[]}',
    });
    expect(tun.host, 'vpn.example.net');
    expect(tun.singboxJson, contains('outbounds'));
  });
}
