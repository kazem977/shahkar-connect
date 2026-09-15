import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Real-world result of a candidate config measured through its own core.
class ShadowResult {
  const ShadowResult({
    required this.reachable,
    required this.handshakeMs,
    required this.firstByteMs,
    required this.kbps,
  });

  static const failed = ShadowResult(
    reachable: false,
    handshakeMs: 0,
    firstByteMs: 0,
    kbps: 0,
  );

  final bool reachable;
  final int handshakeMs;
  final int firstByteMs;
  final int kbps;

  /// 0–100 blend of responsiveness and actual throughput.
  int get score {
    if (!reachable) return 0;
    final latencyPart = (100 - (firstByteMs / 12).clamp(0, 60)).toDouble();
    final speedPart = (kbps / 250).clamp(0, 40).toDouble();
    return (latencyPart * 0.6 + speedPart).clamp(0, 100).round();
  }
}

/// Measures a candidate server by running a second, tunnel-free core instance
/// and pushing a real HTTP download through it.
///
/// This is what makes ranking honest: a node can answer a TCP handshake in
/// 40 ms and still deliver 200 KB/s. Because the shadow instance only opens a
/// local SOCKS port — no TUN, no routes — the live tunnel keeps serving the
/// user while candidates are being measured.
class ShadowTester {
  ShadowTester({required this.corePath});

  final String? corePath;

  /// A small, globally cached object with predictable size.
  static final Uri _probeUrl = Uri.parse(
    'https://speed.cloudflare.com/__down?bytes=400000',
  );

  bool get available => corePath != null && File(corePath!).existsSync();

  /// Spins up the candidate config on [port] and measures it.
  Future<ShadowResult> measure(
    String configJson, {
    int port = 21080,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final bin = corePath;
    if (bin == null || configJson.trim().isEmpty) return ShadowResult.failed;

    final prepared = _asProxyOnly(configJson, port);
    if (prepared == null) return ShadowResult.failed;

    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'vpnai-shadow-$port-$pid.json',
    );
    Process? proc;
    try {
      await file.writeAsString(prepared, encoding: utf8);
      proc = await Process.start(
        bin,
        ['run', '-c', file.path],
        workingDirectory: File(bin).parent.path,
      );
      // Drain output so the pipe buffer cannot stall the core.
      proc.stdout.drain<void>();
      proc.stderr.drain<void>();

      if (!await _waitForPort(port)) return ShadowResult.failed;
      return await _measureThrough(port, timeout);
    } catch (_) {
      return ShadowResult.failed;
    } finally {
      proc?.kill();
      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  /// Strips TUN/inbounds and exposes a single local SOCKS entry point.
  String? _asProxyOnly(String raw, int port) {
    try {
      final decoded = jsonDecode(raw.trim());
      final Map<String, dynamic> root;
      if (decoded is List) {
        root = <String, dynamic>{'outbounds': decoded};
      } else if (decoded is Map) {
        root = Map<String, dynamic>.from(decoded);
      } else {
        return null;
      }
      if (root['outbounds'] == null) return null;

      root['log'] = <String, dynamic>{'level': 'error'};
      root['inbounds'] = <Map<String, dynamic>>[
        {
          'type': 'socks',
          'tag': 'shadow-in',
          'listen': '127.0.0.1',
          'listen_port': port,
        },
      ];
      root.remove('experimental');
      root.remove('dns');
      final route = <String, dynamic>{'auto_detect_interface': true};
      final tag = _firstProxyTag(root['outbounds']);
      if (tag != null) route['final'] = tag;
      root['route'] = route;
      return jsonEncode(root);
    } catch (_) {
      return null;
    }
  }

  String? _firstProxyTag(Object? raw) {
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final type = item['type'] as String? ?? '';
      final tag = item['tag'] as String?;
      if (tag == null || tag.isEmpty) continue;
      if (type == 'direct' || type == 'block' || type == 'dns') continue;
      return tag;
    }
    return null;
  }

  Future<bool> _waitForPort(int port) async {
    for (var i = 0; i < 20; i++) {
      try {
        final socket = await Socket.connect(
          '127.0.0.1',
          port,
          timeout: const Duration(milliseconds: 300),
        );
        socket.destroy();
        return true;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    return false;
  }

  /// Runs the download over the shadow SOCKS proxy and times the transfer.
  Future<ShadowResult> _measureThrough(int port, Duration timeout) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..findProxy = ((_) => 'SOCKS5 127.0.0.1:$port')
      ..badCertificateCallback = ((_, __, ___) => true);
    final handshake = Stopwatch()..start();
    try {
      final req = await client.getUrl(_probeUrl);
      final res = await req.close().timeout(timeout);
      handshake.stop();
      if (res.statusCode >= 400) return ShadowResult.failed;

      final transfer = Stopwatch()..start();
      var bytes = 0;
      var firstByteMs = 0;
      await for (final chunk in res.timeout(timeout)) {
        if (bytes == 0) firstByteMs = handshake.elapsedMilliseconds;
        bytes += chunk.length;
      }
      transfer.stop();
      if (bytes == 0) return ShadowResult.failed;

      final seconds = transfer.elapsedMilliseconds / 1000;
      final kbps = seconds <= 0 ? 0 : (bytes / 1024 / seconds).round();
      return ShadowResult(
        reachable: true,
        handshakeMs: handshake.elapsedMilliseconds,
        firstByteMs: firstByteMs == 0 ? handshake.elapsedMilliseconds : firstByteMs,
        kbps: kbps,
      );
    } catch (_) {
      return ShadowResult.failed;
    } finally {
      client.close(force: true);
    }
  }
}
