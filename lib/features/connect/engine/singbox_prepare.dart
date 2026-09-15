import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

/// Local Clash API used for live byte counters (never shown as a user setting).
const int clashApiPort = 16790;

enum SingBoxRuntime { desktop, mobile }

SingBoxRuntime singBoxRuntimeForHost() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return SingBoxRuntime.mobile;
    default:
      return SingBoxRuntime.desktop;
  }
}

class PreparedSingBox {
  const PreparedSingBox({required this.json, this.clashPort = clashApiPort});
  final String json;
  final int clashPort;
}

/// Hardening, routing and tuning applied on top of the panel config.
class TunnelOptions {
  const TunnelOptions({
    this.allowLan = true,
    this.blockIpv6 = true,
    this.dohUrl,
    this.blockAds = false,
    this.domesticDirect = false,
    this.selectedOnly = false,
    this.bypassApps = const [],
    this.tunnelApps = const [],
    this.bypassDomains = const [],
    this.multiHop = false,
    this.mtu,
  });

  /// Keep printers, NAS and other local devices reachable while connected.
  final bool allowLan;

  /// Drop IPv6 inside the tunnel so a v6-only route cannot leak.
  final bool blockIpv6;

  /// Encrypted resolver; when null the panel/system resolver is kept.
  final String? dohUrl;

  /// Sinkhole common ad and tracker domains.
  final bool blockAds;

  /// Iranian sites and IP ranges skip the tunnel (faster local banking, etc).
  final bool domesticDirect;

  /// Only [tunnelApps] and non-bypassed domains use the tunnel.
  final bool selectedOnly;

  /// Executable names that always bypass the tunnel.
  final List<String> bypassApps;

  /// Executable names that always use the tunnel in `selectedOnly` mode.
  final List<String> tunnelApps;

  /// Domain suffixes that always bypass the tunnel.
  final List<String> bypassDomains;

  /// Route through two proxy hops when the panel exposes more than one.
  final bool multiHop;

  /// TUN MTU discovered by the adaptive prober.
  final int? mtu;
}

const _adDomains = <String>[
  'doubleclick.net',
  'googleadservices.com',
  'googlesyndication.com',
  'adservice.google.com',
  'ads.yahoo.com',
  'adnxs.com',
  'scorecardresearch.com',
  'app-measurement.com',
  'graph.facebook.com',
  'ads.tiktok.com',
];

/// Turns panel tunnel JSON into a runnable sing-box config.
///
/// The panel renderer may return a full client document or only `outbounds`.
/// Desktop needs a TUN inbound + Clash API; mobile TUN is owned by VpnService
/// / Network Extension, so auto-route is left off.
PreparedSingBox prepareSingBoxConfig(
  String raw, {
  SingBoxRuntime runtime = SingBoxRuntime.desktop,
  int clashPort = clashApiPort,
  TunnelOptions options = const TunnelOptions(),
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '{}') {
    throw VpnUnavailableException(
      'کانفیگ تونل خالی است. پنل باید /client/tunnel-config را برگرداند.',
    );
  }

  final decoded = jsonDecode(trimmed);
  final Map<String, dynamic> root;
  if (decoded is List) {
    root = <String, dynamic>{'outbounds': decoded};
  } else if (decoded is Map) {
    root = Map<String, dynamic>.from(decoded);
  } else {
    throw VpnUnavailableException('کانفیگ تونل نامعتبر است.');
  }

  root.putIfAbsent(
    'log',
    () => <String, dynamic>{'level': 'warn', 'timestamp': true},
  );

  final inbounds = _asMapList(root['inbounds']);
  final hasTun = inbounds.any((e) => e['type'] == 'tun');
  if (!hasTun) {
    inbounds.insert(0, _tunInbound(runtime, options));
  } else if (runtime == SingBoxRuntime.mobile) {
    for (final inbound in inbounds) {
      if (inbound['type'] == 'tun') {
        inbound['auto_route'] = false;
        inbound['strict_route'] = false;
      }
    }
  }
  if (runtime == SingBoxRuntime.desktop) {
    final hasMixed = inbounds.any(
      (e) =>
          e['type'] == 'mixed' || e['type'] == 'socks' || e['type'] == 'http',
    );
    if (!hasMixed) {
      inbounds.add(<String, dynamic>{
        'type': 'mixed',
        'tag': 'mixed-in',
        'listen': '127.0.0.1',
        'listen_port': 2080,
      });
    }
  }
  root['inbounds'] = inbounds;

  if (root['outbounds'] == null) {
    throw VpnUnavailableException('کانفیگ تونل خروجی ندارد.');
  }

  final outbounds = _asMapList(root['outbounds']);
  final needsBlock = options.blockAds || options.blockIpv6;
  final needsDirect = options.allowLan ||
      options.domesticDirect ||
      options.selectedOnly ||
      options.bypassApps.isNotEmpty ||
      options.bypassDomains.isNotEmpty;
  if (needsBlock && !outbounds.any((e) => e['tag'] == 'block-out')) {
    outbounds.add(<String, dynamic>{'type': 'block', 'tag': 'block-out'});
  }
  if (needsDirect && !outbounds.any((e) => e['tag'] == 'direct-out')) {
    outbounds.add(<String, dynamic>{'type': 'direct', 'tag': 'direct-out'});
  }
  root['outbounds'] = outbounds;

  final tag = _multiHopTag(root, options) ?? _primaryOutboundTag(root['outbounds']);
  final route = Map<String, dynamic>.from((root['route'] as Map?) ?? const {});
  route['auto_detect_interface'] = true;
  if (tag != null) route['final'] = options.selectedOnly ? 'direct-out' : tag;

  // Order matters: the first matching rule wins in sing-box.
  final rules = <Map<String, dynamic>>[];
  if (options.allowLan) {
    rules.add(<String, dynamic>{
      'ip_is_private': true,
      'outbound': 'direct-out',
    });
  }
  if (options.blockAds) {
    rules.add(<String, dynamic>{
      'domain_suffix': _adDomains,
      'outbound': 'block-out',
    });
  }
  if (options.blockIpv6) {
    rules.add(<String, dynamic>{'ip_version': 6, 'outbound': 'block-out'});
  }
  if (options.bypassApps.isNotEmpty) {
    rules.add(<String, dynamic>{
      'process_name': options.bypassApps,
      'outbound': 'direct-out',
    });
  }
  if (options.bypassDomains.isNotEmpty) {
    rules.add(<String, dynamic>{
      'domain_suffix': options.bypassDomains,
      'outbound': 'direct-out',
    });
  }
  if (options.domesticDirect) {
    rules.add(<String, dynamic>{
      'domain_suffix': const ['.ir'],
      'outbound': 'direct-out',
    });
    rules.add(<String, dynamic>{
      'rule_set': const ['geosite-ir', 'geoip-ir'],
      'outbound': 'direct-out',
    });
  }
  if (options.selectedOnly && options.tunnelApps.isNotEmpty && tag != null) {
    rules.add(<String, dynamic>{
      'process_name': options.tunnelApps,
      'outbound': tag,
    });
  }
  rules.addAll(_asMapList(route['rules']));
  if (rules.isNotEmpty) route['rules'] = rules;
  if (options.domesticDirect) {
    route['rule_set'] = _iranRuleSets(_asMapList(route['rule_set']));
  }
  root['route'] = route;

  final doh = options.dohUrl;
  if (doh != null && doh.isNotEmpty) {
    root['dns'] = <String, dynamic>{
      'servers': [
        <String, dynamic>{
          'tag': 'secure-dns',
          'address': doh,
          'strategy': options.blockIpv6 ? 'ipv4_only' : 'prefer_ipv4',
          'detour': tag,
        },
      ],
      'strategy': options.blockIpv6 ? 'ipv4_only' : 'prefer_ipv4',
      'disable_cache': false,
      'independent_cache': true,
    };
  }

  final experimental = Map<String, dynamic>.from(
    (root['experimental'] as Map?) ?? const {},
  );
  experimental['clash_api'] = <String, dynamic>{
    'external_controller': '127.0.0.1:$clashPort',
    'secret': '',
  };
  root['experimental'] = experimental;

  return PreparedSingBox(json: jsonEncode(root), clashPort: clashPort);
}

List<Map<String, dynamic>> _asMapList(Object? raw) {
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

/// Remote rule sets used by the domestic-direct profile.
List<Map<String, dynamic>> _iranRuleSets(List<Map<String, dynamic>> existing) {
  final tags = existing.map((e) => e['tag']).whereType<String>().toSet();
  const base =
      'https://raw.githubusercontent.com/Chocolate4U/Iran-sing-box-rules/rule-set';
  return [
    ...existing,
    if (!tags.contains('geosite-ir'))
      <String, dynamic>{
        'type': 'remote',
        'tag': 'geosite-ir',
        'format': 'binary',
        'url': '$base/geosite-ir.srs',
        'download_detour': 'direct-out',
        'update_interval': '7d',
      },
    if (!tags.contains('geoip-ir'))
      <String, dynamic>{
        'type': 'remote',
        'tag': 'geoip-ir',
        'format': 'binary',
        'url': '$base/geoip-ir.srs',
        'download_detour': 'direct-out',
        'update_interval': '7d',
      },
  ];
}

/// Chains the two fastest proxy outbounds so traffic exits through a second
/// hop, which decouples the entry node from the exit address.
String? _multiHopTag(Map<String, dynamic> root, TunnelOptions options) {
  if (!options.multiHop) return null;
  final outbounds = _asMapList(root['outbounds']);
  final proxies = outbounds
      .where(
        (o) =>
            o['tag'] is String &&
            const ['direct', 'block', 'dns', 'selector', 'urltest']
                    .contains(o['type']) ==
                false,
      )
      .toList();
  if (proxies.length < 2) return null;

  final entry = proxies[0];
  final exit = proxies[1];
  // The exit hop dials through the entry hop.
  exit['detour'] = entry['tag'];
  root['outbounds'] = outbounds;
  return exit['tag'] as String?;
}

Map<String, dynamic> _tunInbound(SingBoxRuntime runtime, TunnelOptions o) {
  return <String, dynamic>{
    'type': 'tun',
    'tag': 'tun-in',
    'address': <String>[
      '172.19.0.1/30',
      if (!o.blockIpv6) 'fdfe:dcba:9876::1/126',
    ],
    'mtu': o.mtu ?? 1500,
    'auto_route': runtime == SingBoxRuntime.desktop,
    'strict_route': runtime == SingBoxRuntime.desktop,
    'stack': 'mixed',
  };
}

String? _primaryOutboundTag(Object? raw) {
  if (raw is! List) return null;
  String? fallback;
  for (final item in raw) {
    if (item is! Map) continue;
    final type = item['type'] as String? ?? '';
    final tag = item['tag'] as String?;
    if (tag == null || tag.isEmpty) continue;
    fallback ??= tag;
    if (type != 'direct' && type != 'block' && type != 'dns') {
      return tag;
    }
  }
  return fallback;
}
