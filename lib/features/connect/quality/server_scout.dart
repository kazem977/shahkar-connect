import 'dart:async';

import 'package:shahkar_connect/features/connect/data/vpn_server.dart';
import 'package:shahkar_connect/features/connect/quality/connection_quality.dart';

/// A server plus the quality we just measured for it.
class ScoutResult {
  const ScoutResult({required this.server, required this.quality});

  final VpnServer server;
  final ConnectionQuality quality;

  int get score => quality.score;
}

/// Probes servers in parallel batches and ranks them by score.
///
/// Servers without a reachable host fall back to the latency the panel
/// reported, so a catalog with no host data still produces a sane order.
Future<List<ScoutResult>> scoutServers(
  List<VpnServer> servers, {
  int samplesPerServer = 3,
  int concurrency = 6,
  Duration timeout = const Duration(milliseconds: 1600),
}) async {
  final results = <ScoutResult>[];
  for (var i = 0; i < servers.length; i += concurrency) {
    final batch = servers.skip(i).take(concurrency);
    final measured = await Future.wait(
      batch.map(
        (server) => _measure(
          server,
          samples: samplesPerServer,
          timeout: timeout,
        ),
      ),
    );
    results.addAll(measured);
  }
  results.sort((a, b) => b.score.compareTo(a.score));
  return results;
}

Future<ScoutResult> _measure(
  VpnServer server, {
  required int samples,
  required Duration timeout,
}) async {
  if (server.host.isEmpty) {
    final reported = server.latencyMs;
    if (reported == null) {
      return ScoutResult(server: server, quality: ConnectionQuality.unknown);
    }
    return ScoutResult(
      server: server,
      quality: ConnectionQuality(
        latencyMs: reported,
        jitterMs: 0,
        lossPct: 0,
        samples: 1,
      ),
    );
  }

  final probe = EndpointProbe(window: samples);
  var quality = ConnectionQuality.unknown;
  for (var i = 0; i < samples; i++) {
    quality = await probe.sample(server.host, server.port, timeout: timeout);
  }
  return ScoutResult(server: server, quality: quality);
}

/// Candidates worth probing: the current pick plus the most promising others.
List<VpnServer> shortlist(
  List<VpnServer> servers, {
  VpnServer? current,
  int limit = 8,
}) {
  final pool = servers
      .where((s) => s.category == ServerCategory.country)
      .toList(growable: false);
  final ordered = [...pool]..sort((a, b) {
      final la = a.latencyMs ?? 9999;
      final lb = b.latencyMs ?? 9999;
      return la.compareTo(lb);
    });
  final picked = <VpnServer>[];
  if (current != null) picked.add(current);
  for (final server in ordered) {
    if (picked.length >= limit) break;
    if (picked.any((s) => s.id == server.id)) continue;
    picked.add(server);
  }
  return picked;
}
