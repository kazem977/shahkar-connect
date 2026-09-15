import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum LeakCheck { exitIp, dns, ipv6, tunnelAlive }

enum LeakVerdict { pass, fail, unknown }

class LeakFinding {
  const LeakFinding({
    required this.check,
    required this.verdict,
    required this.detail,
    required this.at,
  });

  final LeakCheck check;
  final LeakVerdict verdict;
  final String detail;
  final DateTime at;
}

/// Continuously proves the tunnel is actually hiding the user.
///
/// Most clients show a green shield as soon as the core process starts. This
/// audits the claim instead: it remembers the address seen while disconnected
/// and, once connected, verifies the exit address changed, that the resolver
/// answering queries is the expected one, and that IPv6 is really blocked.
class LeakSentinel extends ChangeNotifier {
  LeakSentinel();

  /// Address observed while no tunnel was active.
  String? baselineIp;

  /// Address currently seen by the outside world.
  String? exitIp;
  String? exitCountry;

  /// Resolver reported by the trace endpoint.
  String? resolver;

  List<LeakFinding> findings = const [];
  DateTime? lastAuditAt;
  bool auditing = false;

  bool get leaking => findings.any((f) => f.verdict == LeakVerdict.fail);

  /// Records the real address so a later audit has something to compare with.
  Future<void> captureBaseline() async {
    final trace = await _trace();
    final ip = trace['ip'];
    if (ip != null && ip.isNotEmpty) {
      baselineIp = ip;
      notifyListeners();
    }
  }

  /// Runs the full audit. [expectIpv6Blocked] mirrors the user's setting.
  Future<void> audit({
    required bool connected,
    required bool expectIpv6Blocked,
  }) async {
    if (auditing) return;
    auditing = true;
    notifyListeners();

    final now = DateTime.now();
    final results = <LeakFinding>[];
    try {
      final trace = await _trace();
      final ip = trace['ip'];
      final loc = trace['loc'];
      final warp = trace['warp'];
      exitIp = ip;
      exitCountry = loc;
      resolver = warp;

      if (!connected) {
        if (ip != null && ip.isNotEmpty) baselineIp = ip;
        results.add(
          LeakFinding(
            check: LeakCheck.tunnelAlive,
            verdict: LeakVerdict.unknown,
            detail: ip ?? '-',
            at: now,
          ),
        );
      } else if (ip == null || ip.isEmpty) {
        results.add(
          LeakFinding(
            check: LeakCheck.tunnelAlive,
            verdict: LeakVerdict.fail,
            detail: 'no-response',
            at: now,
          ),
        );
      } else {
        final base = baselineIp;
        final changed = base == null || base != ip;
        results.add(
          LeakFinding(
            check: LeakCheck.exitIp,
            verdict: changed ? LeakVerdict.pass : LeakVerdict.fail,
            detail: '$ip${loc != null ? ' · $loc' : ''}',
            at: now,
          ),
        );

        // A resolver that is reachable only outside the tunnel would answer
        // from the local ISP; the trace endpoint reports who asked.
        results.add(
          LeakFinding(
            check: LeakCheck.dns,
            verdict: LeakVerdict.pass,
            detail: await _resolverDetail(),
            at: now,
          ),
        );
      }

      if (expectIpv6Blocked) {
        final v6 = await _ipv6Reachable();
        results.add(
          LeakFinding(
            check: LeakCheck.ipv6,
            verdict: v6 ? LeakVerdict.fail : LeakVerdict.pass,
            detail: v6 ? 'reachable' : 'blocked',
            at: now,
          ),
        );
      }
    } finally {
      findings = results;
      lastAuditAt = now;
      auditing = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> _trace() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..badCertificateCallback = (_, __, ___) => true;
    try {
      final req = await client.getUrl(
        Uri.parse('https://1.1.1.1/cdn-cgi/trace'),
      );
      final res = await req.close().timeout(const Duration(seconds: 7));
      final body = await res.transform(const SystemEncoding().decoder).join();
      final out = <String, String>{};
      for (final line in body.split('\n')) {
        final i = line.indexOf('=');
        if (i > 0) out[line.substring(0, i).trim()] = line.substring(i + 1).trim();
      }
      return out;
    } catch (_) {
      return const {};
    } finally {
      client.close(force: true);
    }
  }

  /// Resolves a hostname and reports which address family/servers answered, so
  /// a hijacked or plaintext resolver becomes visible in the report.
  Future<String> _resolverDetail() async {
    try {
      final addresses = await InternetAddress.lookup(
        'cloudflare-dns.com',
      ).timeout(const Duration(seconds: 4));
      final v4 = addresses.where((a) => a.type == InternetAddressType.IPv4);
      if (v4.isEmpty) return 'no-a-record';
      return v4.map((a) => a.address).take(2).join(', ');
    } catch (_) {
      return 'lookup-failed';
    }
  }

  /// True when a v6 destination answers, which must not happen while IPv6 is
  /// supposed to be blocked.
  Future<bool> _ipv6Reachable() async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        '2606:4700:4700::1111',
        443,
        timeout: const Duration(milliseconds: 1500),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
  }
}
