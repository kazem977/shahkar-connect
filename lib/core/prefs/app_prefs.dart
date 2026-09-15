import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How aggressively traffic is blocked when the tunnel is not carrying it.
enum KillSwitchMode {
  /// No blocking at all.
  off,

  /// Block only when an established tunnel drops unexpectedly.
  auto,

  /// Block from the moment a connection starts until the user disconnects.
  strict,
}

/// What to do when a measurably better server is available.
enum SmartSwitchMode { off, ask, auto }

/// Encrypted resolver used inside the tunnel.
enum DnsMode { auto, cloudflare, google, quad9, adguard }

/// How traffic is divided between the tunnel and the direct link.
enum RoutingProfile {
  /// Everything goes through the tunnel.
  global,

  /// Iranian sites and IPs stay on the local link, the rest is tunnelled.
  domesticDirect,

  /// Only the apps and domains the user listed are tunnelled.
  selected,
}

/// Extra hop between the client and the exit node.
enum MultiHopMode { off, double }

extension DnsModeX on DnsMode {
  String? get dohUrl {
    switch (this) {
      case DnsMode.auto:
        return null;
      case DnsMode.cloudflare:
        return 'https://1.1.1.1/dns-query';
      case DnsMode.google:
        return 'https://8.8.8.8/dns-query';
      case DnsMode.quad9:
        return 'https://9.9.9.9/dns-query';
      case DnsMode.adguard:
        return 'https://94.140.14.14/dns-query';
    }
  }
}

/// One finished tunnel session, kept for the usage report.
class SessionRecord {
  const SessionRecord({
    required this.serverName,
    required this.startedAt,
    required this.seconds,
    required this.upBytes,
    required this.downBytes,
  });

  final String serverName;
  final DateTime startedAt;
  final int seconds;
  final int upBytes;
  final int downBytes;

  Map<String, dynamic> toJson() => {
        'server': serverName,
        'at': startedAt.toIso8601String(),
        'sec': seconds,
        'up': upBytes,
        'down': downBytes,
      };

  static SessionRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(raw['at'] as String? ?? '');
    if (at == null) return null;
    return SessionRecord(
      serverName: raw['server'] as String? ?? '',
      startedAt: at,
      seconds: (raw['sec'] as num?)?.toInt() ?? 0,
      upBytes: (raw['up'] as num?)?.toInt() ?? 0,
      downBytes: (raw['down'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persisted client preferences. Everything here survives restarts so the
/// guard can restore protection before the first frame is drawn.
class AppPrefs extends ChangeNotifier {
  AppPrefs._(this._prefs);

  static Future<AppPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppPrefs._(prefs);
    store._readAll();
    return store;
  }

  final SharedPreferences _prefs;

  KillSwitchMode killSwitch = KillSwitchMode.auto;
  SmartSwitchMode smartSwitch = SmartSwitchMode.ask;
  DnsMode dns = DnsMode.cloudflare;
  RoutingProfile routing = RoutingProfile.global;
  MultiHopMode multiHop = MultiHopMode.off;

  bool autoConnectOnLaunch = false;
  bool autoPickBestServer = true;
  bool autoReconnect = true;
  bool allowLan = true;
  bool blockIpv6 = true;
  bool blockAds = false;

  /// Real-throughput probing of candidates while the tunnel keeps running.
  bool shadowTesting = true;

  /// Continuous exit-IP / DNS / IPv6 leak auditing.
  bool leakSentinel = true;

  /// Path-MTU discovery and TUN tuning.
  bool adaptiveMtu = true;
  int? tunedMtu;

  /// Processes that bypass the tunnel (`chrome.exe`, `steam.exe`, …).
  List<String> bypassApps = const [];

  /// Processes forced through the tunnel in `selected` routing.
  List<String> tunnelApps = const [];

  /// Domains that always bypass the tunnel.
  List<String> bypassDomains = const [];

  /// Wi-Fi networks the user considers safe; automation can skip them.
  List<String> trustedNetworks = const [];

  /// Connect automatically when joining a network that is not trusted.
  bool autoConnectUntrusted = false;

  int totalUpBytes = 0;
  int totalDownBytes = 0;
  List<SessionRecord> history = const [];

  /// Firewall state saved while a lockdown is active, so a crash can be undone.
  bool lockdownActive = false;
  Map<String, String> savedFirewallPolicy = const {};

  void _readAll() {
    killSwitch = _enum(KillSwitchMode.values, 'ks', KillSwitchMode.auto);
    smartSwitch = _enum(SmartSwitchMode.values, 'ss', SmartSwitchMode.ask);
    dns = _enum(DnsMode.values, 'dns', DnsMode.cloudflare);
    routing = _enum(RoutingProfile.values, 'routing', RoutingProfile.global);
    multiHop = _enum(MultiHopMode.values, 'multiHop', MultiHopMode.off);
    autoConnectOnLaunch = _prefs.getBool('autoConnect') ?? false;
    autoPickBestServer = _prefs.getBool('autoBest') ?? true;
    autoReconnect = _prefs.getBool('autoReconnect') ?? true;
    allowLan = _prefs.getBool('allowLan') ?? true;
    blockIpv6 = _prefs.getBool('blockIpv6') ?? true;
    blockAds = _prefs.getBool('blockAds') ?? false;
    shadowTesting = _prefs.getBool('shadowTesting') ?? true;
    leakSentinel = _prefs.getBool('leakSentinel') ?? true;
    adaptiveMtu = _prefs.getBool('adaptiveMtu') ?? true;
    tunedMtu = _prefs.getInt('tunedMtu');
    bypassApps = _prefs.getStringList('bypassApps') ?? const [];
    tunnelApps = _prefs.getStringList('tunnelApps') ?? const [];
    bypassDomains = _prefs.getStringList('bypassDomains') ?? const [];
    trustedNetworks = _prefs.getStringList('trustedNets') ?? const [];
    autoConnectUntrusted = _prefs.getBool('autoUntrusted') ?? false;
    totalUpBytes = _prefs.getInt('totalUp') ?? 0;
    totalDownBytes = _prefs.getInt('totalDown') ?? 0;
    lockdownActive = _prefs.getBool('lockdown') ?? false;
    final policy = _prefs.getString('fwPolicy');
    if (policy != null && policy.isNotEmpty) {
      try {
        final decoded = jsonDecode(policy);
        if (decoded is Map) {
          savedFirewallPolicy = decoded.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }
      } catch (_) {}
    }
    final raw = _prefs.getStringList('history') ?? const [];
    history = raw
        .map((e) {
          try {
            return SessionRecord.fromJson(jsonDecode(e));
          } catch (_) {
            return null;
          }
        })
        .whereType<SessionRecord>()
        .toList(growable: false);
  }

  T _enum<T extends Enum>(List<T> values, String key, T fallback) {
    final name = _prefs.getString(key);
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Future<void> setKillSwitch(KillSwitchMode value) async {
    killSwitch = value;
    notifyListeners();
    await _prefs.setString('ks', value.name);
  }

  Future<void> setSmartSwitch(SmartSwitchMode value) async {
    smartSwitch = value;
    notifyListeners();
    await _prefs.setString('ss', value.name);
  }

  Future<void> setDns(DnsMode value) async {
    dns = value;
    notifyListeners();
    await _prefs.setString('dns', value.name);
  }

  Future<void> setAutoConnectOnLaunch(bool value) async {
    autoConnectOnLaunch = value;
    notifyListeners();
    await _prefs.setBool('autoConnect', value);
  }

  Future<void> setAutoPickBestServer(bool value) async {
    autoPickBestServer = value;
    notifyListeners();
    await _prefs.setBool('autoBest', value);
  }

  Future<void> setAutoReconnect(bool value) async {
    autoReconnect = value;
    notifyListeners();
    await _prefs.setBool('autoReconnect', value);
  }

  Future<void> setAllowLan(bool value) async {
    allowLan = value;
    notifyListeners();
    await _prefs.setBool('allowLan', value);
  }

  Future<void> setBlockIpv6(bool value) async {
    blockIpv6 = value;
    notifyListeners();
    await _prefs.setBool('blockIpv6', value);
  }

  Future<void> setBlockAds(bool value) async {
    blockAds = value;
    notifyListeners();
    await _prefs.setBool('blockAds', value);
  }

  Future<void> setRouting(RoutingProfile value) async {
    routing = value;
    notifyListeners();
    await _prefs.setString('routing', value.name);
  }

  Future<void> setMultiHop(MultiHopMode value) async {
    multiHop = value;
    notifyListeners();
    await _prefs.setString('multiHop', value.name);
  }

  Future<void> setShadowTesting(bool value) async {
    shadowTesting = value;
    notifyListeners();
    await _prefs.setBool('shadowTesting', value);
  }

  Future<void> setLeakSentinel(bool value) async {
    leakSentinel = value;
    notifyListeners();
    await _prefs.setBool('leakSentinel', value);
  }

  Future<void> setAdaptiveMtu(bool value) async {
    adaptiveMtu = value;
    notifyListeners();
    await _prefs.setBool('adaptiveMtu', value);
  }

  Future<void> setTunedMtu(int? value) async {
    tunedMtu = value;
    notifyListeners();
    if (value == null) {
      await _prefs.remove('tunedMtu');
    } else {
      await _prefs.setInt('tunedMtu', value);
    }
  }

  Future<void> setBypassApps(List<String> value) async {
    bypassApps = List.unmodifiable(value);
    notifyListeners();
    await _prefs.setStringList('bypassApps', value);
  }

  Future<void> setTunnelApps(List<String> value) async {
    tunnelApps = List.unmodifiable(value);
    notifyListeners();
    await _prefs.setStringList('tunnelApps', value);
  }

  Future<void> setBypassDomains(List<String> value) async {
    bypassDomains = List.unmodifiable(value);
    notifyListeners();
    await _prefs.setStringList('bypassDomains', value);
  }

  Future<void> setTrustedNetworks(List<String> value) async {
    trustedNetworks = List.unmodifiable(value);
    notifyListeners();
    await _prefs.setStringList('trustedNets', value);
  }

  Future<void> setAutoConnectUntrusted(bool value) async {
    autoConnectUntrusted = value;
    notifyListeners();
    await _prefs.setBool('autoUntrusted', value);
  }

  Future<void> addUsage({required int up, required int down}) async {
    totalUpBytes += up;
    totalDownBytes += down;
    notifyListeners();
    await _prefs.setInt('totalUp', totalUpBytes);
    await _prefs.setInt('totalDown', totalDownBytes);
  }

  Future<void> addSession(SessionRecord record) async {
    history = [record, ...history].take(20).toList(growable: false);
    notifyListeners();
    await _prefs.setStringList(
      'history',
      history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> rememberLockdown({
    required bool active,
    Map<String, String>? policy,
  }) async {
    lockdownActive = active;
    if (policy != null) savedFirewallPolicy = policy;
    await _prefs.setBool('lockdown', active);
    if (policy != null) {
      await _prefs.setString('fwPolicy', jsonEncode(policy));
    }
  }
}
