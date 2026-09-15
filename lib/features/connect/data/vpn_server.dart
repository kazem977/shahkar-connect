enum ServerCategory { country, stream, game }

class VpnServer {
  const VpnServer({
    required this.id,
    required this.name,
    required this.location,
    required this.flag,
    required this.category,
    this.regionCode = '',
    this.flagAsset,
    this.premium = false,
    this.latencyMs,
    this.favorite = false,
    this.host = '',
    this.port = 443,
  });

  final int id;
  final String name;
  final String location;
  final String flag;
  final String? flagAsset;
  final String regionCode;
  final ServerCategory category;
  final bool premium;
  final int? latencyMs;
  final bool favorite;
  final String host;
  final int port;

  String get displayTitle => name;
  String get subtitle => location;

  VpnServer copyWith({
    int? latencyMs,
    bool? favorite,
    bool? premium,
  }) {
    return VpnServer(
      id: id,
      name: name,
      location: location,
      flag: flag,
      flagAsset: flagAsset,
      regionCode: regionCode,
      category: category,
      premium: premium ?? this.premium,
      latencyMs: latencyMs ?? this.latencyMs,
      favorite: favorite ?? this.favorite,
      host: host,
      port: port,
    );
  }
}

bool looksLikeProtocolName(String? value) {
  if (value == null || value.trim().isEmpty) return true;
  final v = value.toLowerCase();
  const keys = [
    'shadowsocks',
    'ss2022',
    'ss-',
    'vless',
    'vmess',
    'trojan',
    'hysteria',
    'wireguard',
    'openvpn',
    'sing-box',
    'singbox',
    'tuic',
    'reality',
  ];
  return keys.any(v.contains);
}

String? flagAssetForRegion(String? region) {
  final r = (region ?? '').toUpperCase();
  const map = {
    'GB': 'assets/flags/gb.png',
    'UK': 'assets/flags/gb.png',
    'US': 'assets/flags/us.png',
    'DE': 'assets/flags/de.png',
    'NL': 'assets/flags/nl.png',
    'GR': 'assets/flags/gr.png',
    'EU': 'assets/flags/eu.png',
    'GE': 'assets/flags/ge.png',
    'CA': 'assets/flags/ca.png',
    'JP': 'assets/flags/jp.png',
    'NO': 'assets/flags/no.png',
  };
  return map[r];
}

String flagForRegion(String? region) {
  final r = (region ?? '').toUpperCase();
  const map = {
    'GB': '🇬🇧',
    'UK': '🇬🇧',
    'US': '🇺🇸',
    'DE': '🇩🇪',
    'NL': '🇳🇱',
    'FR': '🇫🇷',
    'TR': '🇹🇷',
    'AE': '🇦🇪',
    'SG': '🇸🇬',
    'JP': '🇯🇵',
    'KR': '🇰🇷',
    'IN': '🇮🇳',
    'CA': '🇨🇦',
    'AU': '🇦🇺',
    'IR': '🇮🇷',
    'RU': '🇷🇺',
    'CN': '🇨🇳',
    'SE': '🇸🇪',
    'FI': '🇫🇮',
    'CH': '🇨🇭',
    'GR': '🇬🇷',
    'EU': '🇪🇺',
    'GE': '🇬🇪',
    'NO': '🇳🇴',
  };
  if (map.containsKey(r)) return map[r]!;
  for (final entry in map.entries) {
    if (r.contains(entry.key)) return entry.value;
  }
  return '🌐';
}

String prettyRegionName(String? region, {String fallback = 'Auto'}) {
  final r = (region ?? '').trim();
  if (r.isEmpty) return fallback;
  const names = {
    'GB': 'United Kingdom',
    'UK': 'United Kingdom',
    'US': 'United States',
    'DE': 'Germany',
    'NL': 'Netherlands',
    'FR': 'France',
    'TR': 'Turkey',
    'AE': 'United Arab Emirates',
    'SG': 'Singapore',
    'JP': 'Japan',
    'KR': 'South Korea',
    'IN': 'India',
    'CA': 'Canada',
    'AU': 'Australia',
    'IR': 'Iran',
    'RU': 'Russia',
    'CN': 'China',
    'GR': 'Greece',
    'EU': 'Europe',
    'GE': 'Georgia',
    'NO': 'Norway',
  };
  final upper = r.toUpperCase();
  return names[upper] ?? r;
}

/// Curated catalog for Stream & Game sections (UI catalog).
List<VpnServer> curatedCatalog() {
  return const [
    VpnServer(
      id: 9001,
      name: 'Netflix',
      location: 'Australia - Sydney 2',
      flag: '🇦🇺',
      regionCode: 'AU',
      category: ServerCategory.stream,
      premium: false,
      latencyMs: 96,
    ),
    VpnServer(
      id: 9002,
      name: 'Hulu',
      location: 'United States - New York',
      flag: '🇺🇸',
      flagAsset: 'assets/flags/us.png',
      regionCode: 'US',
      category: ServerCategory.stream,
      premium: true,
      latencyMs: 84,
    ),
    VpnServer(
      id: 9003,
      name: 'Disney+',
      location: 'United Kingdom - London',
      flag: '🇬🇧',
      flagAsset: 'assets/flags/gb.png',
      regionCode: 'GB',
      category: ServerCategory.stream,
      premium: false,
      latencyMs: 72,
      favorite: true,
    ),
    VpnServer(
      id: 9101,
      name: 'PUBG',
      location: 'Singapore - SG1',
      flag: '🇸🇬',
      regionCode: 'SG',
      category: ServerCategory.game,
      premium: false,
      latencyMs: 58,
    ),
    VpnServer(
      id: 9102,
      name: 'Clash Royale',
      location: 'Germany - Frankfurt',
      flag: '🇩🇪',
      flagAsset: 'assets/flags/de.png',
      regionCode: 'DE',
      category: ServerCategory.game,
      premium: true,
      latencyMs: 64,
    ),
    VpnServer(
      id: 9103,
      name: 'Pokémon GO',
      location: 'Japan - Tokyo',
      flag: '🇯🇵',
      flagAsset: 'assets/flags/jp.png',
      regionCode: 'JP',
      category: ServerCategory.game,
      premium: false,
      latencyMs: 110,
    ),
  ];
}

/// Prefer real location servers; skip protocol-only rows.
List<VpnServer> serversFromProtocols(List<dynamic> protocols) {
  final out = <VpnServer>[];
  for (var i = 0; i < protocols.length; i++) {
    final item = protocols[i];
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final id = _asInt(map['node_id']) ?? (1000 + i);
    final region = (map['region'] as String?)?.trim();
    final nodeName = (map['node_name'] as String?)?.trim();
    final protocol = (map['protocol'] as String?)?.trim();

    String? display;
    if (region != null && region.isNotEmpty) {
      display = prettyRegionName(region);
    } else if (nodeName != null && !looksLikeProtocolName(nodeName)) {
      display = nodeName;
    }

    // Protocol-only entries are not locations for the home carousel.
    if (display == null || looksLikeProtocolName(display)) continue;

    final code = (region ?? '').toUpperCase();
    out.add(
      VpnServer(
        id: id,
        name: display,
        location: [
          if (region != null && region.isNotEmpty) region,
          if (protocol != null && protocol.isNotEmpty) protocol,
        ].join(' · '),
        flag: flagForRegion(region),
        flagAsset: flagAssetForRegion(region),
        regionCode: code,
        category: ServerCategory.country,
        premium: i > 2,
        latencyMs: 45 + (i * 17) % 90,
      ),
    );
  }
  return out;
}

List<VpnServer> defaultCountryServers() {
  return const [
    VpnServer(
      id: 11,
      name: 'Greece',
      location: 'Athens',
      flag: '🇬🇷',
      flagAsset: 'assets/flags/gr.png',
      regionCode: 'GR',
      category: ServerCategory.country,
      latencyMs: 92,
    ),
    VpnServer(
      id: 12,
      name: 'Europe',
      location: 'EU Hub',
      flag: '🇪🇺',
      flagAsset: 'assets/flags/eu.png',
      regionCode: 'EU',
      category: ServerCategory.country,
      latencyMs: 75,
    ),
    VpnServer(
      id: 13,
      name: 'Georgia',
      location: 'Tbilisi',
      flag: '🇬🇪',
      flagAsset: 'assets/flags/ge.png',
      regionCode: 'GE',
      category: ServerCategory.country,
      latencyMs: 68,
    ),
    VpnServer(
      id: 14,
      name: 'Canada',
      location: 'Toronto',
      flag: '🇨🇦',
      flagAsset: 'assets/flags/ca.png',
      regionCode: 'CA',
      category: ServerCategory.country,
      latencyMs: 130,
    ),
    VpnServer(
      id: 1,
      name: 'United Kingdom',
      location: 'London',
      flag: '🇬🇧',
      flagAsset: 'assets/flags/gb.png',
      regionCode: 'GB',
      category: ServerCategory.country,
      latencyMs: 80,
    ),
    VpnServer(
      id: 15,
      name: 'Japan',
      location: 'Tokyo',
      flag: '🇯🇵',
      flagAsset: 'assets/flags/jp.png',
      regionCode: 'JP',
      category: ServerCategory.country,
      latencyMs: 145,
    ),
    VpnServer(
      id: 16,
      name: 'Norway',
      location: 'Oslo',
      flag: '🇳🇴',
      flagAsset: 'assets/flags/no.png',
      regionCode: 'NO',
      category: ServerCategory.country,
      latencyMs: 88,
    ),
    VpnServer(
      id: 2,
      name: 'United States',
      location: 'New York',
      flag: '🇺🇸',
      flagAsset: 'assets/flags/us.png',
      regionCode: 'US',
      category: ServerCategory.country,
      latencyMs: 120,
    ),
    VpnServer(
      id: 3,
      name: 'Germany',
      location: 'Frankfurt',
      flag: '🇩🇪',
      flagAsset: 'assets/flags/de.png',
      regionCode: 'DE',
      category: ServerCategory.country,
      latencyMs: 70,
    ),
    VpnServer(
      id: 4,
      name: 'Netherlands',
      location: 'Amsterdam',
      flag: '🇳🇱',
      flagAsset: 'assets/flags/nl.png',
      regionCode: 'NL',
      category: ServerCategory.country,
      latencyMs: 65,
    ),
  ];
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
