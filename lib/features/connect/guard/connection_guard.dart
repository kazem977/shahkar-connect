import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';
import 'package:shahkar_connect/features/connect/data/panel_material.dart';
import 'package:shahkar_connect/features/connect/data/vpn_server.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/connect/quality/connection_quality.dart';
import 'package:shahkar_connect/features/connect/quality/mtu_prober.dart';
import 'package:shahkar_connect/features/connect/quality/server_scout.dart';
import 'package:shahkar_connect/features/connect/quality/shadow_tester.dart';
import 'package:shahkar_connect/features/connect/security/kill_switch.dart';
import 'package:shahkar_connect/features/connect/security/leak_sentinel.dart';
import 'package:shahkar_connect/features/connect/security/network_watcher.dart';

/// A measurably better server the user can move to.
class SwitchSuggestion {
  const SwitchSuggestion({
    required this.server,
    required this.currentScore,
    required this.candidateScore,
  });

  final VpnServer server;
  final int currentScore;
  final int candidateScore;

  int get gain => candidateScore - currentScore;
}

/// Transient event the UI surfaces as a notification.
enum GuardNotice { switched, reconnected, reconnecting, internetDown, locked }

/// Watches the live connection and keeps it fast and leak-free.
///
/// Responsibilities: probe the tunnel, hunt for a better server when quality
/// drops, reconnect after a drop with backoff, and drive the kill switch.
class ConnectionGuard extends ChangeNotifier {
  ConnectionGuard({
    required SessionController session,
    required AppPrefs prefs,
    required KillSwitchService killSwitch,
    required LeakSentinel leakSentinel,
    required NetworkWatcher networkWatcher,
  })  : _session = session,
        _prefs = prefs,
        _killSwitch = killSwitch,
        _leaks = leakSentinel,
        _networks = networkWatcher;

  static const _tickInterval = Duration(seconds: 5);
  static const _suggestCooldown = Duration(minutes: 3);
  static const _dismissMemory = Duration(minutes: 10);
  static const _minGain = 15;
  static const _backoffSeconds = [2, 5, 10, 20, 30];

  final SessionController _session;
  final AppPrefs _prefs;
  final KillSwitchService _killSwitch;
  final LeakSentinel _leaks;
  final NetworkWatcher _networks;

  final EndpointProbe _probe = EndpointProbe();
  final Map<int, DateTime> _dismissed = {};

  /// Real-throughput results keyed by server id, newest wins.
  final Map<int, ShadowResult> shadowResults = {};

  DateTime? _lastAuditAt;
  bool _mtuProbed = false;

  Timer? _tick;
  Timer? _retry;
  Timer? _noticeTimer;
  DateTime? _lastSuggestedAt;
  DateTime? _sessionStart;
  int _badStreak = 0;
  int _reconnectAttempt = 0;
  int _lastUp = 0;
  int _lastDown = 0;

  ConnectionQuality quality = ConnectionQuality.unknown;
  SwitchSuggestion? suggestion;
  GuardNotice? notice;
  String? noticeDetail;
  bool internetDown = false;
  bool scanning = false;
  bool switching = false;

  KillSwitchService get killSwitch => _killSwitch;
  AppPrefs get prefs => _prefs;
  LeakSentinel get leaks => _leaks;
  NetworkWatcher get networks => _networks;

  /// True when the current Wi-Fi is not on the user's trusted list.
  bool get onUntrustedNetwork {
    final net = _networks.current;
    if (!net.isWifi) return false;
    if (!net.secured) return true;
    return !_prefs.trustedNetworks.contains(net.ssid);
  }

  bool _started = false;

  /// Wires the guard to the session and recovers a stale firewall lockdown.
  /// Safe to call more than once; only the first call does the work.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _session.onUnexpectedDrop = _handleDrop;
    _session.addListener(_onSessionChanged);
    _killSwitch.corePath = _session.corePath;
    await _killSwitch.restoreAfterCrash();
    _networks.onChanged = _onNetworkChanged;
    _networks.start();
    if (!_session.isConnected && _prefs.leakSentinel) {
      unawaited(_leaks.captureBaseline());
    }
    _tick = Timer.periodic(_tickInterval, (_) => unawaited(_onTick()));
    if (_prefs.autoConnectOnLaunch) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await smartConnect();
    }
  }

  /// Protection follows the user: joining an untrusted or open network can
  /// bring the tunnel up on its own.
  void _onNetworkChanged(NetworkIdentity network) {
    if (!_prefs.autoConnectUntrusted) return;
    if (_session.isConnected || _session.wantsConnected) return;
    if (!onUntrustedNetwork) return;
    unawaited(smartConnect());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _retry?.cancel();
    _noticeTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    _session.onUnexpectedDrop = null;
    super.dispose();
  }

  void clearNotice() {
    _noticeTimer?.cancel();
    notice = null;
    noticeDetail = null;
    notifyListeners();
  }

  /// Notices are informational; they fade on their own unless they describe an
  /// ongoing problem the user still needs to see.
  void _showNotice(GuardNotice value, {String? detail}) {
    _noticeTimer?.cancel();
    notice = value;
    noticeDetail = detail;
    final sticky = value == GuardNotice.internetDown ||
        value == GuardNotice.locked ||
        value == GuardNotice.reconnecting;
    if (!sticky) {
      _noticeTimer = Timer(const Duration(seconds: 6), clearNotice);
    }
    notifyListeners();
  }

  /// Connect, picking the fastest server first when the user asked for it.
  Future<void> smartConnect() async {
    _retry?.cancel();
    _reconnectAttempt = 0;
    if (_prefs.autoPickBestServer) {
      final best = await pickBestServer();
      if (best != null) _session.selectServer(best);
    }
    await _killSwitch.onConnecting();
    await _session.connect();
    if (_session.isConnected) await _afterConnected();
  }

  /// Connect to a server the user chose explicitly.
  Future<void> connectTo(VpnServer server) async {
    _retry?.cancel();
    _reconnectAttempt = 0;
    await _killSwitch.onConnecting();
    await _session.connect(server: server);
    if (_session.isConnected) await _afterConnected();
  }

  Future<void> userDisconnect() async {
    _retry?.cancel();
    _reconnectAttempt = 0;
    _finishSessionRecord();
    await _session.disconnect();
    await _killSwitch.onUserDisconnect();
    _resetQuality();
    notifyListeners();
    if (_prefs.leakSentinel) {
      // With the tunnel down this reading is the real address, which every
      // later audit is compared against.
      unawaited(_leaks.captureBaseline());
    }
  }

  /// Fastest server by live probing, falling back to the reported latency.
  Future<VpnServer?> pickBestServer() async {
    final candidates = shortlist(
      _session.servers,
      current: _session.selectedServer,
      limit: 8,
    );
    if (candidates.isEmpty) return null;
    scanning = true;
    notifyListeners();
    try {
      final results = await scoutServers(candidates, samplesPerServer: 2);
      final usable = results.where((r) => r.quality.hasData).toList();
      if (usable.isEmpty) return null;

      // The panel sees load and health we cannot; give it our measurements and
      // prefer its pick when it is among the servers we just validated.
      final pick = await _session.reportProbe(_probeSamples(usable));
      final nodeId = pick?.nodeId;
      if (nodeId != null) {
        for (final result in usable) {
          if (result.server.id == nodeId) return result.server;
        }
      }
      return usable.first.server;
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  List<ProbeSample> _probeSamples(List<ScoutResult> results) {
    return [
      for (final r in results.take(8))
        ProbeSample(
          nodeId: r.server.id,
          pingMs: r.quality.latencyMs,
          packetLossPct: r.quality.lossPct,
          handshakeMs: shadowResults[r.server.id]?.handshakeMs,
          protocolTested: _session.negotiation?.recommended,
        ),
    ];
  }

  /// Full ranking for the diagnostics screen.
  Future<List<ScoutResult>> rankAllServers() async {
    scanning = true;
    notifyListeners();
    try {
      return await scoutServers(
        shortlist(_session.servers, limit: 24),
        samplesPerServer: 3,
      );
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> applySuggestion() async {
    final target = suggestion?.server;
    suggestion = null;
    if (target == null) return;
    await _switchTo(target);
  }

  void dismissSuggestion() {
    final target = suggestion?.server;
    if (target != null) _dismissed[target.id] = DateTime.now();
    suggestion = null;
    notifyListeners();
  }

  Future<void> _switchTo(VpnServer server) async {
    switching = true;
    notice = null;
    notifyListeners();
    try {
      await _session.switchTo(server);
      if (_session.isConnected) {
        _resetQuality();
        await _afterConnected();
        _showNotice(GuardNotice.switched, detail: server.name);
      }
    } finally {
      switching = false;
      notifyListeners();
    }
  }

  Future<void> _afterConnected() async {
    _sessionStart ??= DateTime.now();
    _reconnectAttempt = 0;
    _badStreak = 0;
    _lastAuditAt = null;
    unawaited(_tuneMtu());
    await _killSwitch.onConnected();
    if (_killSwitch.engaged && _prefs.killSwitch == KillSwitchMode.auto) {
      // Traffic is safe inside the tunnel again.
      await _killSwitch.release();
    }
  }

  /// The engine reports counters per tunnel, so a restart resets them; bank
  /// what we saw before the reset instead of losing it.
  void _onSessionChanged() {
    final up = _session.stats.upBytes;
    final down = _session.stats.downBytes;
    if (up < _lastUp || down < _lastDown) {
      unawaited(_prefs.addUsage(up: _lastUp, down: _lastDown));
      _lastUp = 0;
      _lastDown = 0;
    }
    _lastUp = up;
    _lastDown = down;
  }

  Future<void> _handleDrop(String? reason) async {
    await _killSwitch.onUnexpectedDrop();
    if (_killSwitch.engaged) {
      _showNotice(GuardNotice.locked, detail: reason);
    }
    _resetQuality();
    if (_prefs.autoReconnect && _session.wantsConnected) {
      _scheduleReconnect();
    }
    notifyListeners();
  }

  void _scheduleReconnect() {
    _retry?.cancel();
    final index = _reconnectAttempt.clamp(0, _backoffSeconds.length - 1);
    final delay = Duration(seconds: _backoffSeconds[index]);
    _reconnectAttempt++;
    _showNotice(GuardNotice.reconnecting);
    _retry = Timer(delay, () => unawaited(_attemptReconnect()));
  }

  Future<void> _attemptReconnect() async {
    if (!_session.wantsConnected || _session.isConnected) return;
    if (!await internetReachable()) {
      internetDown = true;
      _showNotice(GuardNotice.internetDown);
      _retry = Timer(
        const Duration(seconds: 5),
        () => unawaited(_attemptReconnect()),
      );
      return;
    }
    internetDown = false;
    if (_prefs.autoPickBestServer) {
      final best = await pickBestServer();
      if (best != null) _session.selectServer(best);
    }
    await _session.connect(silent: true);
    if (_session.isConnected) {
      await _afterConnected();
      _showNotice(GuardNotice.reconnected);
      return;
    }
    if (_reconnectAttempt < 8) _scheduleReconnect();
  }

  Future<void> _onTick() async {
    if (_session.isConnected) {
      await _sampleQuality();
      await _maybeAudit();
      await _maybeHuntBetterServer();
      return;
    }
    if (_session.wantsConnected) {
      final up = await internetReachable();
      if (internetDown != !up) {
        internetDown = !up;
        notifyListeners();
      }
    }
  }

  Future<void> _sampleQuality() async {
    // Probing a neutral endpoint measures the whole tunnel path end to end.
    final result = await _probe.sample(
      internetProbes.first.$1,
      internetProbes.first.$2,
    );
    quality = result;
    _session.reportedPingMs = result.latencyMs;
    _session.reportedLossPct = result.lossPct;
    if (result.degraded) {
      _badStreak++;
    } else {
      _badStreak = 0;
    }
    notifyListeners();
  }

  Future<void> _maybeHuntBetterServer() async {
    if (_prefs.smartSwitch == SmartSwitchMode.off) return;
    if (switching || scanning || suggestion != null) return;
    if (_badStreak < 3) return;
    final last = _lastSuggestedAt;
    if (last != null && DateTime.now().difference(last) < _suggestCooldown) {
      return;
    }

    _lastSuggestedAt = DateTime.now();
    final current = _session.selectedServer;
    final candidates = shortlist(_session.servers, current: current, limit: 6);
    var results = await scoutServers(candidates, samplesPerServer: 2);
    if (results.isEmpty) return;

    // Handshake speed is only a hint; re-rank the top picks by what they can
    // actually deliver, measured through a throwaway core instance.
    if (_prefs.shadowTesting) {
      results = await _rerankByThroughput(results, current: current, take: 3);
    }

    _dismissed.removeWhere(
      (_, at) => DateTime.now().difference(at) > _dismissMemory,
    );

    final currentScore = quality.score;
    final better = results.firstWhere(
      (r) =>
          r.server.id != current?.id &&
          !_dismissed.containsKey(r.server.id) &&
          r.quality.hasData &&
          r.score - currentScore >= _minGain,
      orElse: () => ScoutResult(
        server: current ?? results.first.server,
        quality: ConnectionQuality.unknown,
      ),
    );
    if (!better.quality.hasData || better.server.id == current?.id) return;

    if (_prefs.smartSwitch == SmartSwitchMode.auto) {
      await _switchTo(better.server);
      return;
    }
    suggestion = SwitchSuggestion(
      server: better.server,
      currentScore: currentScore,
      candidateScore: better.score,
    );
    _badStreak = 0;
    notifyListeners();
  }

  /// Measures the leading candidates end to end and reorders them by the blend
  /// of throughput and time-to-first-byte.
  Future<List<ScoutResult>> _rerankByThroughput(
    List<ScoutResult> ranked, {
    VpnServer? current,
    int take = 3,
  }) async {
    final tester = ShadowTester(corePath: _session.corePath);
    if (!tester.available || _session.materials.isEmpty) return ranked;

    scanning = true;
    notifyListeners();
    try {
      final measured = <int, int>{};
      var port = 21080;
      for (final result in ranked.take(take)) {
        if (result.server.id == current?.id) continue;
        final config = _session.materialForServer(result.server);
        if (config == null) continue;
        final shadow = await tester.measure(config, port: port++);
        shadowResults[result.server.id] = shadow;
        if (shadow.reachable) measured[result.server.id] = shadow.score;
      }
      if (measured.isEmpty) return ranked;

      final reordered = [...ranked]..sort((a, b) {
          final sa = measured[a.server.id] ?? a.score;
          final sb = measured[b.server.id] ?? b.score;
          return sb.compareTo(sa);
        });
      return reordered;
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  /// Finds the real path MTU once per connection so transfers stop stalling on
  /// oversized packets.
  Future<void> _tuneMtu() async {
    if (!_prefs.adaptiveMtu || _mtuProbed) return;
    _mtuProbed = true;
    final host = _session.selectedServer?.host.isNotEmpty == true
        ? _session.selectedServer!.host
        : internetProbes.first.$1;
    final mtu = await const MtuProber().probe(host);
    if (mtu == null) return;
    if (_prefs.tunedMtu == mtu) return;
    await _prefs.setTunedMtu(mtu);
  }

  Future<void> _maybeAudit() async {
    if (!_prefs.leakSentinel) return;
    final last = _lastAuditAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 60)) {
      return;
    }
    _lastAuditAt = DateTime.now();
    await _leaks.audit(
      connected: _session.isConnected,
      expectIpv6Blocked: _prefs.blockIpv6,
    );
  }

  void _resetQuality() {
    _probe.reset();
    quality = ConnectionQuality.unknown;
    _badStreak = 0;
  }

  void _finishSessionRecord() {
    final start = _sessionStart;
    _sessionStart = null;
    if (start == null) return;
    final up = _lastUp;
    final down = _lastDown;
    _lastUp = 0;
    _lastDown = 0;
    unawaited(_prefs.addUsage(up: up, down: down));
    unawaited(
      _prefs.addSession(
        SessionRecord(
          serverName: _session.selectedServer?.name ?? '',
          startedAt: start,
          seconds: DateTime.now().difference(start).inSeconds,
          upBytes: up,
          downBytes: down,
        ),
      ),
    );
  }
}

/// Convenience for reading the live engine phase in the UI.
bool isEngineBusy(SessionController session) =>
    session.busy ||
    session.engineState.kind == ConnectionStateKind.connecting;
