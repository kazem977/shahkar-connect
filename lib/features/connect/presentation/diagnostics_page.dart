import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/connect/presentation/widgets/guard_widgets.dart';
import 'package:shahkar_connect/features/connect/quality/server_scout.dart';
import 'package:shahkar_connect/features/connect/quality/shadow_tester.dart';
import 'package:shahkar_connect/features/connect/security/kill_switch.dart';
import 'package:shahkar_connect/features/connect/security/leak_sentinel.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';

/// Server ranking, exit IP and protection status in one place.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  List<ScoutResult> _results = const [];
  String? _ip;
  String? _ipLocation;
  bool _testing = false;
  bool _checkingIp = false;

  Future<void> _runTest() async {
    setState(() => _testing = true);
    final guard = context.read<ConnectionGuard>();
    final results = await guard.rankAllServers();
    if (!mounted) return;
    setState(() {
      _results = results;
      _testing = false;
    });
  }

  /// Reads the exit IP straight from Cloudflare's trace endpoint, so it shows
  /// the tunnel's address when connected and the real one when not.
  Future<void> _checkIp() async {
    setState(() => _checkingIp = true);
    String? ip;
    String? loc;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..badCertificateCallback = (_, __, ___) => true;
    try {
      final req = await client.getUrl(
        Uri.parse('https://1.1.1.1/cdn-cgi/trace'),
      );
      final res = await req.close().timeout(const Duration(seconds: 8));
      final body = await res.transform(const SystemEncoding().decoder).join();
      for (final line in body.split('\n')) {
        if (line.startsWith('ip=')) ip = line.substring(3).trim();
        if (line.startsWith('loc=')) loc = line.substring(4).trim();
      }
    } catch (_) {
      // Leave the fields empty; the UI shows a dash.
    } finally {
      client.close(force: true);
    }
    if (!mounted) return;
    setState(() {
      _ip = ip;
      _ipLocation = loc;
      _checkingIp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final prefs = context.watch<AppPrefs>();
    final killSwitch = context.watch<KillSwitchService>();
    final guard = context.watch<ConnectionGuard>();
    final session = context.watch<SessionController>();
    final leaks = context.watch<LeakSentinel>();

    return AppScaffold(
      showBack: true,
      showBrand: false,
      backgroundColor: const Color(0xFF07080A),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: Text(
              s.diagnostics,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ShahkarTheme.fog,
              ),
            ),
          ),

          _Panel(
            title: s.protectionStatus,
            child: Column(
              children: [
                _Row(
                  label: s.killSwitch,
                  value: _killSwitchLabel(killSwitch, prefs, s),
                  tone: killSwitch.state == KillSwitchState.unavailable
                      ? const Color(0xFFF5A623)
                      : null,
                ),
                _Row(
                  label: s.quality,
                  value: guard.quality.hasData
                      ? '${gradeLabel(guard.quality.grade, s)} · '
                          '${s.score} ${guard.quality.score}'
                      : '—',
                ),
                _Row(
                  label: s.dnsProtection,
                  value: prefs.dns == DnsMode.auto ? s.dnsAuto : prefs.dns.name,
                ),
                _Row(
                  label: s.dataUsed,
                  value: '${_mb(prefs.totalDownBytes)} ↓ · '
                      '${_mb(prefs.totalUpBytes)} ↑',
                ),
              ],
            ),
          ),

          _Panel(
            title: s.leakAudit,
            trailing: _SmallButton(
              label: s.runAudit,
              busy: leaks.auditing,
              onTap: () => leaks.audit(
                connected: session.isConnected,
                expectIpv6Blocked: prefs.blockIpv6,
              ),
            ),
            child: Column(
              children: [
                _Row(
                  label: s.realIp,
                  value: leaks.baselineIp ?? '—',
                ),
                for (final finding in leaks.findings)
                  _Row(
                    label: _checkLabel(finding.check, s),
                    value: '${_verdictLabel(finding.verdict, s)} · '
                        '${finding.detail}',
                    tone: finding.verdict == LeakVerdict.fail
                        ? ShahkarTheme.danger
                        : (finding.verdict == LeakVerdict.pass
                            ? ShahkarTheme.connected
                            : null),
                  ),
                if (leaks.findings.isEmpty)
                  _Row(label: s.leakAudit, value: '—'),
              ],
            ),
          ),

          _Panel(
            title: s.publicIp,
            trailing: _SmallButton(
              label: s.checkIp,
              busy: _checkingIp,
              onTap: _checkIp,
            ),
            child: _Row(
              label: session.isConnected ? s.connected : s.disconnected,
              value: _ip == null
                  ? '—'
                  : '$_ip${_ipLocation != null ? ' · $_ipLocation' : ''}',
            ),
          ),

          _Panel(
            title: s.testServers,
            trailing: _SmallButton(
              label: s.testServers,
              busy: _testing,
              onTap: _runTest,
            ),
            child: _results.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(
                      color: ShahkarTheme.mute,
                      fontSize: 11,
                    ),
                  )
                : Column(
                    children: [
                      for (final r in _results.take(12))
                        _ServerRow(
                          result: r,
                          shadow: guard.shadowResults[r.server.id],
                          onTap: () async {
                            await context
                                .read<ConnectionGuard>()
                                .connectTo(r.server);
                          },
                        ),
                    ],
                  ),
          ),

          _Panel(
            title: s.sessionHistory,
            child: prefs.history.isEmpty
                ? Text(
                    s.noHistory,
                    style: const TextStyle(
                      color: ShahkarTheme.mute,
                      fontSize: 11,
                    ),
                  )
                : Column(
                    children: [
                      for (final h in prefs.history.take(8))
                        _Row(
                          label: h.serverName.isEmpty ? '—' : h.serverName,
                          value: '${_minutes(h.seconds)} · '
                              '${_mb(h.downBytes)} ↓',
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 6),
          _SmallButton(
            label: s.copyReport,
            wide: true,
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: _report(prefs, killSwitch, guard, session)),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.copied)),
              );
            },
          ),
        ],
      ),
    );
  }

  String _killSwitchLabel(
    KillSwitchService ks,
    AppPrefs prefs,
    S s,
  ) {
    if (prefs.killSwitch == KillSwitchMode.off) return s.inactive;
    switch (ks.state) {
      case KillSwitchState.engaged:
        return s.internetLocked;
      case KillSwitchState.armed:
        return s.armed;
      case KillSwitchState.unavailable:
        return ks.blocker == 'admin'
            ? s.killSwitchNeedsAdmin
            : s.killSwitchUnsupported;
      case KillSwitchState.off:
        return s.inactive;
    }
  }

  String _report(
    AppPrefs prefs,
    KillSwitchService ks,
    ConnectionGuard guard,
    SessionController session,
  ) {
    final lines = <String>[
      'vpnai diagnostics',
      'platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'connected: ${session.isConnected}',
      'server: ${session.selectedServer?.name ?? '-'}',
      'quality: ${guard.quality.latencyMs}ms jitter ${guard.quality.jitterMs}ms '
          'loss ${guard.quality.lossPct}% score ${guard.quality.score}',
      'killSwitch: ${prefs.killSwitch.name} state ${ks.state.name} '
          'blocker ${ks.blocker ?? '-'}',
      'smartSwitch: ${prefs.smartSwitch.name}',
      'dns: ${prefs.dns.name} blockIpv6: ${prefs.blockIpv6} '
          'blockAds: ${prefs.blockAds} allowLan: ${prefs.allowLan}',
      'usage: down ${prefs.totalDownBytes} up ${prefs.totalUpBytes}',
      'exitIp: ${_ip ?? '-'} ${_ipLocation ?? ''}',
    ];
    for (final r in _results.take(12)) {
      lines.add(
        '  ${r.server.name}: ${r.quality.latencyMs}ms '
        'jitter ${r.quality.jitterMs}ms loss ${r.quality.lossPct}% '
        'score ${r.score}',
      );
    }
    return lines.join('\n');
  }
}

String _checkLabel(LeakCheck check, S s) {
  switch (check) {
    case LeakCheck.exitIp:
      return s.checkExitIp;
    case LeakCheck.dns:
      return s.checkDns;
    case LeakCheck.ipv6:
      return s.checkIpv6;
    case LeakCheck.tunnelAlive:
      return s.checkTunnel;
  }
}

String _verdictLabel(LeakVerdict verdict, S s) {
  switch (verdict) {
    case LeakVerdict.pass:
      return s.leakPass;
    case LeakVerdict.fail:
      return s.leakFail;
    case LeakVerdict.unknown:
      return s.leakUnknown;
  }
}

String _mb(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
  return '${mb.toStringAsFixed(1)} MB';
}

String _minutes(int seconds) {
  final d = Duration(seconds: seconds);
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF11141A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D222B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ShahkarTheme.fog,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ShahkarTheme.mute, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tone ?? ShahkarTheme.fog,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.result,
    required this.onTap,
    this.shadow,
  });

  final ScoutResult result;
  final ShadowResult? shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = gradeColor(result.quality.grade);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                result.server.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ShahkarTheme.fog,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              shadow?.reachable == true
                  ? '${result.quality.latencyMs}ms · '
                      '${(shadow!.kbps / 1024).toStringAsFixed(1)}MB/s'
                  : '${result.quality.latencyMs}ms · ${result.score}',
              style: const TextStyle(color: ShahkarTheme.mute, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onTap,
    this.busy = false,
    this.wide = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShahkarTheme.accent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: wide ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ShahkarTheme.accent.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ShahkarTheme.accentSoft,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: ShahkarTheme.accentSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
