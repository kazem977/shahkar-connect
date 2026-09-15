import 'dart:convert';

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

num? _asNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

String _asJsonString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map || value is List) {
    return jsonEncode(value);
  }
  return value.toString();
}

class Entitlement {
  const Entitlement({
    required this.username,
    required this.status,
    required this.canConnect,
    this.expiresAt,
    this.trafficRemainingBytes,
  });

  final String username;
  final String status;
  final bool canConnect;
  final String? expiresAt;
  final int? trafficRemainingBytes;

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      username: json['username'] as String? ?? '',
      status: json['status'] as String? ?? 'expired',
      canConnect: json['can_connect'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
      trafficRemainingBytes: _asInt(json['traffic_remaining_bytes']),
    );
  }

  /// Best-effort entitlement from the v2 client config payload.
  factory Entitlement.fromClientConfig(Map<String, dynamic> json) {
    final hasProtocols =
        (json['protocols'] is List) && (json['protocols'] as List).isNotEmpty;
    final hasSub = (json['subscription_url'] as String?)?.isNotEmpty == true;
    final canConnect = hasProtocols || hasSub;
    return Entitlement(
      username: json['username'] as String? ?? '',
      status: canConnect ? 'active' : 'expired',
      canConnect: canConnect,
      expiresAt: json['expires_at'] as String?,
      trafficRemainingBytes: _asInt(json['traffic_remaining_bytes']),
    );
  }
}

class PlanOffer {
  const PlanOffer({
    required this.id,
    required this.name,
    this.durationDays,
    this.trafficGb,
    this.priceIrr,
    this.appleProductId,
    this.googleProductId,
  });

  final int id;
  final String name;
  final int? durationDays;
  final num? trafficGb;
  final num? priceIrr;
  final String? appleProductId;
  final String? googleProductId;

  factory PlanOffer.fromJson(Map<String, dynamic> json) {
    return PlanOffer(
      id: _asInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      durationDays: _asInt(json['duration_days']),
      trafficGb: _asNum(json['traffic_gb']),
      priceIrr: _asNum(json['price_irr']),
      appleProductId: json['apple_product_id'] as String?,
      googleProductId: json['google_product_id'] as String?,
    );
  }
}

class NodeCandidate {
  const NodeCandidate({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.region,
    this.sni,
    this.loadPct = 0,
  });

  final int id;
  final String name;
  final String host;
  final int port;
  final String? region;
  final String? sni;
  final num loadPct;

  factory NodeCandidate.fromJson(Map<String, dynamic> json) {
    return NodeCandidate(
      id: _asInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: _asInt(json['port']) ?? 443,
      region: json['region'] as String?,
      sni: json['sni'] as String?,
      loadPct: _asNum(json['load_pct']) ?? 0,
    );
  }
}

class TunnelConfig {
  const TunnelConfig({
    required this.nodeId,
    required this.nodeName,
    required this.host,
    required this.port,
    required this.singboxJson,
    this.sni,
  });

  final int nodeId;
  final String nodeName;
  final String host;
  final int port;
  final String singboxJson;
  final String? sni;

  factory TunnelConfig.fromJson(Map<String, dynamic> json) {
    return TunnelConfig(
      nodeId: _asInt(json['node_id']) ?? 0,
      nodeName: json['node_name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: _asInt(json['port']) ?? 443,
      singboxJson: _asJsonString(
        json['singbox_json'] ?? json['config'] ?? json['singbox'],
      ),
      sni: json['sni'] as String?,
    );
  }
}

class TelegramLinkCode {
  const TelegramLinkCode({required this.code, this.botCommand = '/app'});
  final String code;
  final String botCommand;

  factory TelegramLinkCode.fromJson(Map<String, dynamic> json) {
    return TelegramLinkCode(
      code: json['code'] as String? ?? '',
      botCommand: json['bot_command'] as String? ?? '/app',
    );
  }
}

List<Map<String, dynamic>> _asObjectList(dynamic data, List<String> keys) {
  if (data is List) {
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
  if (data is Map) {
    for (final key in keys) {
      final inner = data[key];
      if (inner is List) {
        return inner.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    }
  }
  return const [];
}

List<PlanOffer> parsePlanOffers(dynamic data) {
  return _asObjectList(data, const ['plans', 'items'])
      .map(PlanOffer.fromJson)
      .toList();
}

List<NodeCandidate> parseNodeCandidates(dynamic data) {
  return _asObjectList(
    data,
    const ['candidates', 'nodes', 'items'],
  ).map(NodeCandidate.fromJson).toList();
}
