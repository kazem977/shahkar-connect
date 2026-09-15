import 'dart:convert';

/// One entry of `protocol_materials` from `GET /api/v2/client/config`.
///
/// The client never rewrites tunnel definitions: [singbox] must already be a
/// runnable sing-box document produced by the panel. When it is missing, the
/// material is reported as [usable] == false together with [shape], so the
/// mismatch is visible in diagnostics instead of failing as "no server".
class PanelMaterial {
  const PanelMaterial({
    required this.protocol,
    required this.singbox,
    required this.shape,
    this.nodeId,
    this.nodeName,
    this.region,
    this.host,
    this.port,
    this.tlsTrusted,
  });

  /// Panel key: `vless-reality`, `hysteria2`, `tuic`, `anytls`, `cdn`, …
  final String protocol;

  /// Ready-to-run sing-box JSON, or null when the panel did not provide it.
  final String? singbox;

  /// What the panel actually sent, used for diagnostics: `singbox`, `link`,
  /// `outbounds` or `unknown`.
  final String shape;

  final int? nodeId;
  final String? nodeName;
  final String? region;
  final String? host;
  final int? port;
  final bool? tlsTrusted;

  bool get usable => singbox != null && singbox!.trim().isNotEmpty;

  static PanelMaterial parse(String protocol, Object? raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      final looksLikeConfig = trimmed.startsWith('{') || trimmed.startsWith('[');
      return PanelMaterial(
        protocol: protocol,
        singbox: looksLikeConfig ? trimmed : null,
        shape: looksLikeConfig ? 'singbox' : 'link',
      );
    }
    if (raw is! Map) {
      return PanelMaterial(protocol: protocol, singbox: null, shape: 'unknown');
    }

    final map = Map<String, dynamic>.from(raw);
    final direct = map['singbox'] ?? map['singbox_json'];
    String? json;
    var shape = 'unknown';
    if (direct != null) {
      json = _asJson(direct);
      shape = 'singbox';
    } else if (map['link'] != null) {
      shape = 'link';
    } else if (map['outbounds'] != null) {
      // Panel-side descriptors, not sing-box outbounds.
      shape = 'outbounds';
    }

    return PanelMaterial(
      protocol: protocol,
      singbox: json,
      shape: shape,
      nodeId: _asInt(map['node_id']),
      nodeName: map['node_name'] as String?,
      region: (map['region'] as String?)?.toUpperCase(),
      host: map['host'] as String?,
      port: _asInt(map['port']),
      tlsTrusted: map['tls_trusted'] as bool?,
    );
  }

  static Map<String, PanelMaterial> parseAll(Object? rawMaterials) {
    if (rawMaterials is! Map) return const {};
    final out = <String, PanelMaterial>{};
    rawMaterials.forEach((key, value) {
      final name = '$key';
      out[name] = PanelMaterial.parse(name, value);
    });
    return out;
  }
}

/// What the panel says about protocol availability on this network.
class PanelNegotiation {
  const PanelNegotiation({
    this.recommended,
    this.usableProtocols = const [],
    this.blockedProtocols = const [],
    this.profile,
    this.net,
  });

  final String? recommended;
  final List<String> usableProtocols;
  final List<String> blockedProtocols;
  final String? profile;
  final String? net;

  bool allows(String protocol) {
    if (blockedProtocols.contains(protocol)) return false;
    if (usableProtocols.isEmpty) return true;
    return usableProtocols.contains(protocol);
  }

  /// Panel preference order, best first.
  List<String> get preferenceOrder => [
        if (recommended != null && recommended!.isNotEmpty) recommended!,
        ...usableProtocols,
      ];

  static PanelNegotiation fromJson(Map<String, dynamic> json) {
    return PanelNegotiation(
      recommended: json['recommended'] as String?,
      usableProtocols: _asStrings(json['usable_protocols']),
      blockedProtocols: _asStrings(json['blocked_protocols']),
      profile: json['profile'] as String?,
      net: json['net'] as String?,
    );
  }
}

/// One measurement the client reports to `POST /api/v2/client/probe`.
class ProbeSample {
  const ProbeSample({
    this.nodeId,
    this.pingMs,
    this.packetLossPct,
    this.handshakeMs,
    this.protocolTested,
  });

  final int? nodeId;
  final num? pingMs;
  final num? packetLossPct;
  final num? handshakeMs;
  final String? protocolTested;

  Map<String, dynamic> toJson() => {
        if (nodeId != null) 'node_id': nodeId,
        if (pingMs != null) 'ping_ms': pingMs,
        if (packetLossPct != null) 'packet_loss_pct': packetLossPct,
        if (handshakeMs != null) 'handshake_ms': handshakeMs,
        if (protocolTested != null) 'protocol_tested': protocolTested,
      };
}

/// The panel's answer to a probe report.
class PanelRecommendation {
  const PanelRecommendation({
    this.nodeId,
    this.protocol,
    this.fallbackNodeId,
    this.fallbackProtocol,
  });

  final int? nodeId;
  final String? protocol;
  final int? fallbackNodeId;
  final String? fallbackProtocol;

  static PanelRecommendation fromJson(Map<String, dynamic> json) {
    return PanelRecommendation(
      nodeId: _asInt(json['recommended_node']),
      protocol: json['recommended_protocol'] as String?,
      fallbackNodeId: _asInt(json['fallback_node']),
      fallbackProtocol: json['fallback_protocol'] as String?,
    );
  }
}

List<String> _asStrings(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((e) => '$e').toList(growable: false);
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value;
  if (value is Map || value is List) return jsonEncode(value);
  return null;
}
