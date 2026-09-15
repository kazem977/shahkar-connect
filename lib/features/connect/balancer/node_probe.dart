import 'dart:async';
import 'dart:io';

import 'package:shahkar_connect/core/api/models.dart';

class NoHealthyNodeException implements Exception {}

class NodeLatencyResult {
  const NodeLatencyResult({
    required this.node,
    required this.latencyMs,
    required this.success,
  });

  final NodeCandidate node;
  final int latencyMs;
  final bool success;
}

/// Real TCP+TLS handshake to the candidate's public port — not ICMP.
Future<List<NodeCandidate>> rankHealthyNodes(
  List<NodeCandidate> candidates,
) async {
  if (candidates.isEmpty) throw NoHealthyNodeException();
  final results = await Future.wait(candidates.map(_probe));
  final healthy = results.where((r) => r.success).toList()
    ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
  if (healthy.isEmpty) throw NoHealthyNodeException();
  return healthy.map((r) => r.node).toList();
}

Future<NodeCandidate> selectBestNode(List<NodeCandidate> candidates) async {
  final ranked = await rankHealthyNodes(candidates);
  return ranked.first;
}

Future<NodeLatencyResult> _probe(NodeCandidate c) async {
  final sw = Stopwatch()..start();
  try {
    await testTlsHandshake(c.host, c.port, timeout: const Duration(seconds: 3));
    sw.stop();
    return NodeLatencyResult(
      node: c,
      latencyMs: sw.elapsedMilliseconds,
      success: true,
    );
  } catch (_) {
    return NodeLatencyResult(node: c, latencyMs: 9999, success: false);
  }
}

Future<void> testTlsHandshake(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final socket = await SecureSocket.connect(
    host,
    port,
    timeout: timeout,
    onBadCertificate: (_) => true,
  );
  await socket.close();
}
