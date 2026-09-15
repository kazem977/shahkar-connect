import 'package:flutter_test/flutter_test.dart';
import 'package:shahkar_connect/core/api/models.dart';

void main() {
  test('parses balancer candidate json', () {
    final node = NodeCandidate.fromJson({
      'id': 3,
      'name': 'de-1',
      'host': 'vpn.example.net',
      'port': 443,
      'load_pct': 12.5,
    });
    expect(node.id, 3);
    expect(node.port, 443);
    expect(node.loadPct, 12.5);
  });

  test('entitlement can_connect defaults false', () {
    final e = Entitlement.fromJson({'username': 'a', 'status': 'expired'});
    expect(e.canConnect, isFalse);
  });

  test('parses remaining traffic from numeric strings', () {
    final e = Entitlement.fromJson({
      'username': 'a',
      'status': 'active',
      'can_connect': true,
      'traffic_remaining_bytes': '2048',
    });
    expect(e.trafficRemainingBytes, 2048);
  });

  test('parses plans wrapped in an object or a list', () {
    expect(
        parsePlanOffers({
          'plans': [
            {'id': 1, 'name': 'A'}
          ]
        }).single.name,
        'A');
    expect(
        parsePlanOffers([
          {'id': 2, 'name': 'B'}
        ]).single.id,
        2);
  });

  test('accepts tunnel config as a nested object', () {
    final tun = TunnelConfig.fromJson({
      'node_id': '9',
      'node_name': 'nl',
      'host': 'nl.example',
      'port': '8443',
      'singbox': {'outbounds': []},
    });
    expect(tun.port, 8443);
    expect(tun.singboxJson, contains('outbounds'));
  });
}
