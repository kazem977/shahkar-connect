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
}
