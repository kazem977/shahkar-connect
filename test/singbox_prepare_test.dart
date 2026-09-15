import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shahkar_connect/features/connect/engine/singbox_prepare.dart';

const _panelConfig = '''
{
  "outbounds": [
    {"type": "vless", "tag": "entry", "server": "a.example", "server_port": 443},
    {"type": "trojan", "tag": "exit", "server": "b.example", "server_port": 443}
  ]
}
''';

Map<String, dynamic> _prepare(TunnelOptions options) {
  final prepared = prepareSingBoxConfig(_panelConfig, options: options);
  return jsonDecode(prepared.json) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _rules(Map<String, dynamic> root) {
  final route = root['route'] as Map<String, dynamic>;
  return (route['rules'] as List).cast<Map<String, dynamic>>();
}

void main() {
  test('adds a TUN inbound with the tuned MTU', () {
    final root = _prepare(const TunnelOptions(mtu: 1380));
    final inbounds = (root['inbounds'] as List).cast<Map<String, dynamic>>();
    final tun = inbounds.firstWhere((e) => e['type'] == 'tun');
    expect(tun['mtu'], 1380);
    expect(tun['address'], ['172.19.0.1/30']);
  });

  test('keeps an IPv6 address only when IPv6 is allowed', () {
    final root = _prepare(const TunnelOptions(blockIpv6: false));
    final inbounds = (root['inbounds'] as List).cast<Map<String, dynamic>>();
    final tun = inbounds.firstWhere((e) => e['type'] == 'tun');
    expect((tun['address'] as List).length, 2);
  });

  test('private ranges stay direct before anything else', () {
    final rules = _rules(_prepare(const TunnelOptions()));
    expect(rules.first['ip_is_private'], true);
    expect(rules.first['outbound'], 'direct-out');
  });

  test('bypassed apps and domains route around the tunnel', () {
    final root = _prepare(
      const TunnelOptions(
        bypassApps: ['steam.exe'],
        bypassDomains: ['bank.ir'],
      ),
    );
    final rules = _rules(root);
    final app = rules.firstWhere((r) => r['process_name'] != null);
    final domain = rules.firstWhere(
      (r) => r['domain_suffix'] != null && r['outbound'] == 'direct-out',
    );
    expect(app['outbound'], 'direct-out');
    expect(app['process_name'], ['steam.exe']);
    expect(domain['domain_suffix'], ['bank.ir']);
  });

  test('domestic profile pulls the Iran rule sets and keeps .ir direct', () {
    final root = _prepare(const TunnelOptions(domesticDirect: true));
    final route = root['route'] as Map<String, dynamic>;
    final ruleSets = (route['rule_set'] as List).cast<Map<String, dynamic>>();
    expect(
      ruleSets.map((e) => e['tag']),
      containsAll(['geosite-ir', 'geoip-ir']),
    );
    final direct = _rules(root).where((r) => r['outbound'] == 'direct-out');
    expect(
      direct.any((r) => (r['domain_suffix'] as List?)?.contains('.ir') == true),
      isTrue,
    );
  });

  test('selected-apps profile tunnels only the listed processes', () {
    final root = _prepare(
      const TunnelOptions(selectedOnly: true, tunnelApps: ['chrome.exe']),
    );
    final route = root['route'] as Map<String, dynamic>;
    expect(route['final'], 'direct-out');
    final tunnelled = _rules(root).firstWhere(
      (r) => (r['process_name'] as List?)?.contains('chrome.exe') == true,
    );
    expect(tunnelled['outbound'], isNot('direct-out'));
  });

  test('multi-hop chains the exit node through the entry node', () {
    final root = _prepare(const TunnelOptions(multiHop: true));
    final outbounds = (root['outbounds'] as List).cast<Map<String, dynamic>>();
    final exit = outbounds.firstWhere((e) => e['tag'] == 'exit');
    expect(exit['detour'], 'entry');
    expect((root['route'] as Map<String, dynamic>)['final'], 'exit');
  });

  test('single hop leaves outbounds untouched', () {
    final root = _prepare(const TunnelOptions());
    final outbounds = (root['outbounds'] as List).cast<Map<String, dynamic>>();
    final exit = outbounds.firstWhere((e) => e['tag'] == 'exit');
    expect(exit.containsKey('detour'), isFalse);
  });

  test('encrypted DNS is routed through the proxy, not the local link', () {
    final root = _prepare(
      const TunnelOptions(dohUrl: 'https://1.1.1.1/dns-query'),
    );
    final dns = root['dns'] as Map<String, dynamic>;
    final server = (dns['servers'] as List).first as Map<String, dynamic>;
    expect(server['address'], 'https://1.1.1.1/dns-query');
    expect(server['detour'], 'entry');
    expect(dns['strategy'], 'ipv4_only');
  });

  test('ads and IPv6 land on a block outbound', () {
    final root = _prepare(const TunnelOptions(blockAds: true));
    final outbounds = (root['outbounds'] as List).cast<Map<String, dynamic>>();
    expect(outbounds.any((e) => e['tag'] == 'block-out'), isTrue);
    final rules = _rules(root);
    expect(
      rules.any(
        (r) => r['outbound'] == 'block-out' && r['domain_suffix'] != null,
      ),
      isTrue,
    );
    expect(
      rules.any((r) => r['outbound'] == 'block-out' && r['ip_version'] == 6),
      isTrue,
    );
  });
}
