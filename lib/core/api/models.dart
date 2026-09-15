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
      trafficRemainingBytes: json['traffic_remaining_bytes'] as int?,
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
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      durationDays: json['duration_days'] as int?,
      trafficGb: json['traffic_gb'] as num?,
      priceIrr: json['price_irr'] as num?,
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
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 443,
      region: json['region'] as String?,
      sni: json['sni'] as String?,
      loadPct: json['load_pct'] as num? ?? 0,
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
      nodeId: json['node_id'] as int,
      nodeName: json['node_name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 443,
      singboxJson: json['singbox_json'] as String? ?? '',
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
