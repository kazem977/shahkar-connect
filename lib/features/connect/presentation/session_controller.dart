import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/api_errors.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';
import 'package:shahkar_connect/features/connect/data/panel_material.dart';
import 'package:shahkar_connect/features/connect/data/vpn_server.dart';
import 'package:shahkar_connect/features/connect/engine/singbox_prepare.dart';
import 'package:shahkar_connect/features/connect/engine/traffic_rate.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient api,
    required VpnEngine engine,
    AppPrefs? prefs,
  })  : _api = api,
        _engine = engine,
        _prefs = prefs {
    _servers = [
      ...defaultCountryServers(),
      ...curatedCatalog(),
    ];
    selectedServer = _servers.firstWhere(
      (s) => s.regionCode == 'GB',
      orElse: () => _servers.first,
    );
    _engineSub = _engine.stateStream.listen((s) {
      engineState = s;
      if (s.kind == ConnectionStateKind.connected) {
        connectedAt ??= DateTime.now();
      }
      if (s.kind == ConnectionStateKind.idle) {
        connectedAt = null;
      }
      final droppedOut = s.kind == ConnectionStateKind.error ||
          (s.kind == ConnectionStateKind.idle && wantsConnected);
      if (droppedOut && wantsConnected && !busy) {
        error = s.message ?? error;
        _heartbeat?.cancel();
        onUnexpectedDrop?.call(s.message);
      }
      notifyListeners();
    });
    _trafficSub = _engine.trafficStream.listen((t) {
      stats = t;
      rate = _rate.update(
        TrafficStatsSample(
          upBytes: t.upBytes,
          downBytes: t.downBytes,
          at: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }

  final ApiClient _api;
  final VpnEngine _engine;
  final AppPrefs? _prefs;
  final TrafficRate _rate = TrafficRate();
  StreamSubscription<ConnectionStateSnap>? _engineSub;
  StreamSubscription<TrafficStats>? _trafficSub;
  Timer? _heartbeat;
  String? _sessionId;

  /// Live quality numbers pushed into telemetry by the guard.
  num? reportedPingMs;
  num? reportedLossPct;

  Entitlement? entitlement;
  List<VpnServer> _servers = const [];
  VpnServer? selectedServer;
  String? error;
  DateTime? connectedAt;

  /// True while the user expects to be protected, even if the tunnel is down.
  bool wantsConnected = false;

  /// Raised when the tunnel dies without the user asking for it.
  void Function(String? reason)? onUnexpectedDrop;

  /// Executable of the tunnel core, for firewall allow-listing.
  String? get corePath => _engine.corePath;

  TunnelOptions get tunnelOptions {
    final p = _prefs;
    if (p == null) return const TunnelOptions();
    return TunnelOptions(
      allowLan: p.allowLan,
      blockIpv6: p.blockIpv6,
      dohUrl: p.dns.dohUrl,
      blockAds: p.blockAds,
      domesticDirect: p.routing == RoutingProfile.domesticDirect,
      selectedOnly: p.routing == RoutingProfile.selected,
      bypassApps: p.bypassApps,
      tunnelApps: p.tunnelApps,
      bypassDomains: p.bypassDomains,
      multiHop: p.multiHop == MultiHopMode.double,
      mtu: p.adaptiveMtu ? p.tunedMtu : null,
    );
  }

  /// Tunnel material per panel key from the last config fetch, reused by the
  /// shadow tester so candidates can be measured without reconnecting.
  Map<String, String> materials = const {};

  /// Everything the panel sent, including entries we cannot run, so the
  /// mismatch is visible instead of silently dropped.
  Map<String, PanelMaterial> panelMaterials = const {};

  /// Protocol availability reported by the panel for this network.
  PanelNegotiation? negotiation;

  /// The panel's own pick after we report our measurements.
  PanelRecommendation? recommendation;

  /// Panel keys that arrived without a runnable sing-box document.
  List<String> get unusableMaterials => panelMaterials.values
      .where((m) => !m.usable)
      .map((m) => '${m.protocol}(${m.shape})')
      .toList(growable: false);

  /// Material for a specific server, when the panel exposes one.
  String? materialForServer(VpnServer server) {
    for (final material in panelMaterials.values) {
      if (!material.usable) continue;
      if (material.nodeId != null && material.nodeId == server.id) {
        return material.singbox;
      }
      if (material.region != null &&
          server.regionCode.isNotEmpty &&
          material.region == server.regionCode) {
        return material.singbox;
      }
    }
    final needles = <String>[
      '${server.id}',
      server.regionCode.toLowerCase(),
      server.name.toLowerCase(),
    ].where((e) => e.isNotEmpty);
    for (final entry in materials.entries) {
      final key = entry.key.toLowerCase();
      if (needles.any(key.contains)) return entry.value;
    }
    return null;
  }

  /// Asks the panel which protocols work on this network before dialling, so a
  /// blocked transport is never attempted.
  Future<void> refreshNegotiation() async {
    try {
      final res = await _api.dio.get('/api/v2/client/negotiate');
      final data = res.data;
      if (data is Map) {
        negotiation = PanelNegotiation.fromJson(
          Map<String, dynamic>.from(data),
        );
        notifyListeners();
      }
    } catch (_) {
      // Negotiation is advisory; connecting must still work without it.
    }
  }

  /// Reports client-side measurements and keeps the panel's recommendation.
  Future<PanelRecommendation?> reportProbe(List<ProbeSample> samples) async {
    if (samples.isEmpty) return null;
    try {
      final res = await _api.dio.post(
        '/api/v2/client/probe',
        data: {
          if (negotiation?.profile != null) 'profile': negotiation!.profile,
          'results': samples.map((e) => e.toJson()).toList(),
        },
      );
      final data = res.data;
      if (data is Map) {
        recommendation = PanelRecommendation.fromJson(
          Map<String, dynamic>.from(data),
        );
        notifyListeners();
        return recommendation;
      }
    } catch (_) {}
    return null;
  }

  List<VpnServer> get servers => List.unmodifiable(_servers);

  List<VpnServer> get countryServers => _servers
      .where((s) => s.category == ServerCategory.country)
      .toList(growable: false);

  /// Legacy alias used by older UI paths.
  NodeCandidate? get selected {
    final s = selectedServer;
    if (s == null) return null;
    return NodeCandidate(
      id: s.id,
      name: s.name,
      host: s.host,
      port: s.port,
      region: s.regionCode.isEmpty ? null : s.regionCode,
    );
  }

  void applyEntitlement(Entitlement value) {
    entitlement = value;
    notifyListeners();
  }

  ConnectionStateSnap engineState = const ConnectionStateSnap(
    kind: ConnectionStateKind.idle,
  );
  TrafficStats stats = const TrafficStats();
  TrafficSnapshot rate = const TrafficSnapshot();
  bool busy = false;

  bool get isConnected => engineState.kind == ConnectionStateKind.connected;

  int? get pingMs => selectedServer?.latencyMs;

  void selectServer(VpnServer server) {
    selectedServer = server;
    notifyListeners();
  }

  void toggleFavorite(int id) {
    _servers = [
      for (final s in _servers)
        if (s.id == id) s.copyWith(favorite: !s.favorite) else s,
    ];
    if (selectedServer?.id == id) {
      selectedServer = _servers.firstWhere((s) => s.id == id);
    }
    notifyListeners();
  }

  Future<void> refreshEntitlement() async {
    try {
      final res = await _api.dio.get('/api/v2/client/config');
      final data = res.data as Map<String, dynamic>;
      entitlement = Entitlement.fromClientConfig(data);
      _mergeProtocols(data['protocols']);
      error = null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        error = describeApiError(e);
      }
    }
    notifyListeners();
  }

  void _mergeProtocols(Object? protocols) {
    final curated = [
      ..._servers.where((s) => s.category != ServerCategory.country),
    ];
    // Always keep a location catalog for the home UI.
    final defaults = defaultCountryServers();
    final fromApi = protocols is List
        ? serversFromProtocols(protocols)
        : const <VpnServer>[];

    List<VpnServer> countries;
    if (fromApi.isEmpty) {
      countries = defaults;
    } else {
      // Prefer API locations, but fill missing popular regions from defaults.
      final seen = <String>{};
      countries = [];
      for (final s in fromApi) {
        final key = s.regionCode.isNotEmpty ? s.regionCode : s.name;
        if (seen.add(key)) countries.add(s);
      }
      for (final s in defaults) {
        final key = s.regionCode.isNotEmpty ? s.regionCode : s.name;
        if (seen.add(key)) countries.add(s);
      }
    }

    _servers = [...countries, ...curated];

    final keep = selectedServer;
    if (keep != null) {
      for (final s in _servers) {
        if (s.id == keep.id ||
            (keep.regionCode.isNotEmpty && s.regionCode == keep.regionCode)) {
          selectedServer = s;
          return;
        }
      }
    }
    selectedServer = _servers.firstWhere(
      (s) => s.regionCode == 'GB',
      orElse: () => _servers.first,
    );
  }

  Future<void> connect({VpnServer? server, bool silent = false}) async {
    if (server != null) selectedServer = server;
    error = null;
    busy = true;
    if (!silent) wantsConnected = true;
    notifyListeners();
    try {
      await refreshEntitlement();
      if (entitlement?.canConnect != true) {
        error = const S('en').inactivePlan;
        return;
      }
      await refreshNegotiation();
      final res = await _api.dio.get('/api/v2/client/config');
      final data = res.data as Map<String, dynamic>;
      _mergeProtocols(data['protocols']);
      final singbox = _materialForSelected(data['protocol_materials']);
      if (singbox == null || singbox.isEmpty) {
        final shapes = unusableMaterials;
        error = shapes.isEmpty
            ? const S('en').noServer
            : 'پنل کانفیگ sing-box نداد: ${shapes.join(', ')}';
        return;
      }
      _sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await _engine.connect(
        SingBoxConfig(json: singbox, options: tunnelOptions),
      );
      wantsConnected = true;
      connectedAt = DateTime.now();
      _startHeartbeat();
    } on VpnUnavailableException catch (e) {
      error = e.message;
    } on DioException catch (e) {
      error = describeApiError(e);
    } catch (e) {
      error = describeApiError(e, fallback: e.toString());
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Re-dials the tunnel on another server without dropping user intent.
  Future<void> switchTo(VpnServer server) async {
    await _engine.disconnect();
    await connect(server: server, silent: true);
  }

  Future<void> disconnect({bool keepIntent = false}) async {
    _heartbeat?.cancel();
    connectedAt = null;
    if (!keepIntent) wantsConnected = false;
    await _engine.disconnect();
    try {
      await _api.dio.post('/api/v2/client/telemetry', data: _telemetryBody());
    } catch (_) {}
    notifyListeners();
  }

  Map<String, dynamic> _telemetryBody() => {
        if (_sessionId != null) 'session_id': _sessionId,
        'active_node': selectedServer?.id,
        if (_activeProtocol() != null) 'active_protocol': _activeProtocol(),
        if (reportedPingMs != null) 'ping_ms': reportedPingMs,
        if (reportedLossPct != null) 'packet_loss_pct': reportedLossPct,
        'bytes_sent': stats.upBytes,
        'bytes_recv': stats.downBytes,
      };

  /// Picks the tunnel material for the chosen location, preferring the protocol
  /// the panel recommends and never one it reported as blocked.
  String? _materialForSelected(Object? rawMaterials) {
    panelMaterials = PanelMaterial.parseAll(rawMaterials);
    materials = {
      for (final m in panelMaterials.values)
        if (m.usable) m.protocol: m.singbox!,
    };
    if (materials.isEmpty) return null;

    final wanted = selectedServer;
    final runnable = panelMaterials.values.where((m) => m.usable).toList();

    int rank(PanelMaterial m) {
      final order = negotiation?.preferenceOrder ?? const <String>[];
      final index = order.indexOf(m.protocol);
      return index < 0 ? order.length + 1 : index;
    }

    final allowed = runnable
        .where((m) => negotiation?.allows(m.protocol) ?? true)
        .toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    final pool = allowed.isEmpty ? runnable : allowed;

    if (wanted != null) {
      for (final m in pool) {
        if (m.nodeId != null && m.nodeId == wanted.id) return m.singbox;
      }
      for (final m in pool) {
        if (m.region != null &&
            wanted.regionCode.isNotEmpty &&
            m.region == wanted.regionCode) {
          return m.singbox;
        }
      }
    }

    final byNode = recommendation?.nodeId;
    if (byNode != null) {
      for (final m in pool) {
        if (m.nodeId == byNode) return m.singbox;
      }
    }
    return pool.first.singbox;
  }

  /// Protocol key of the material currently in use, for telemetry.
  String? _activeProtocol() {
    final wanted = selectedServer;
    for (final m in panelMaterials.values) {
      if (!m.usable) continue;
      if (wanted != null && m.nodeId == wanted.id) return m.protocol;
    }
    return materials.keys.isEmpty ? null : materials.keys.first;
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await _api.dio.post('/api/v2/client/telemetry', data: _telemetryBody());
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _engineSub?.cancel();
    _trafficSub?.cancel();
    super.dispose();
  }
}

