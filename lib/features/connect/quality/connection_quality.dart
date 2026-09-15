import 'dart:async';
import 'dart:io';

enum ConnectionGrade { excellent, good, fair, poor, dead }

/// Latency, jitter and loss folded into a single comparable score.
class ConnectionQuality {
  const ConnectionQuality({
    required this.latencyMs,
    required this.jitterMs,
    required this.lossPct,
    required this.samples,
  });

  static const unknown = ConnectionQuality(
    latencyMs: 0,
    jitterMs: 0,
    lossPct: 0,
    samples: 0,
  );

  final int latencyMs;
  final int jitterMs;
  final int lossPct;
  final int samples;

  bool get hasData => samples > 0;

  /// 0–100, higher is better.
  int get score {
    if (!hasData) return 0;
    if (lossPct >= 100) return 0;
    final latencyPenalty = (latencyMs / 6).clamp(0, 40).toDouble();
    final jitterPenalty = (jitterMs / 2).clamp(0, 25).toDouble();
    final lossPenalty = (lossPct * 1.5).clamp(0, 45).toDouble();
    return (100 - latencyPenalty - jitterPenalty - lossPenalty)
        .clamp(0, 100)
        .round();
  }

  ConnectionGrade get grade {
    if (!hasData) return ConnectionGrade.fair;
    if (lossPct >= 100) return ConnectionGrade.dead;
    final s = score;
    if (s >= 85) return ConnectionGrade.excellent;
    if (s >= 70) return ConnectionGrade.good;
    if (s >= 50) return ConnectionGrade.fair;
    return ConnectionGrade.poor;
  }

  /// True when the link is bad enough to justify looking for another server.
  bool get degraded =>
      hasData &&
      (grade == ConnectionGrade.poor ||
          grade == ConnectionGrade.dead ||
          lossPct >= 20 ||
          jitterMs >= 90 ||
          latencyMs >= 320);
}

/// Rolling probe of one endpoint: a TCP handshake is the closest thing to a
/// real user request that works on every desktop without raw sockets.
class EndpointProbe {
  EndpointProbe({this.window = 8});

  final int window;
  final _rtts = <int>[];
  var _attempts = 0;
  var _failures = 0;

  void reset() {
    _rtts.clear();
    _attempts = 0;
    _failures = 0;
  }

  ConnectionQuality get quality {
    if (_attempts == 0) return ConnectionQuality.unknown;
    if (_rtts.isEmpty) {
      return ConnectionQuality(
        latencyMs: 0,
        jitterMs: 0,
        lossPct: 100,
        samples: _attempts,
      );
    }
    final sorted = [..._rtts]..sort();
    final median = sorted[sorted.length ~/ 2];
    var jitter = 0;
    if (_rtts.length > 1) {
      var sum = 0;
      for (var i = 1; i < _rtts.length; i++) {
        sum += (_rtts[i] - _rtts[i - 1]).abs();
      }
      jitter = (sum / (_rtts.length - 1)).round();
    }
    return ConnectionQuality(
      latencyMs: median,
      jitterMs: jitter,
      lossPct: ((_failures / _attempts) * 100).round(),
      samples: _attempts,
    );
  }

  Future<ConnectionQuality> sample(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 2200),
  }) async {
    final rtt = await measureRtt(host, port, timeout: timeout);
    _attempts++;
    if (rtt == null) {
      _failures++;
    } else {
      _rtts.add(rtt);
      if (_rtts.length > window) _rtts.removeAt(0);
    }
    if (_attempts > window) {
      _attempts = window;
      _failures = _failures.clamp(0, window);
    }
    return quality;
  }
}

/// Round-trip time of a TCP handshake, or null when it did not complete.
Future<int?> measureRtt(
  String host,
  int port, {
  Duration timeout = const Duration(milliseconds: 2200),
}) async {
  if (host.isEmpty) return null;
  final sw = Stopwatch()..start();
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: timeout);
    sw.stop();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  } finally {
    try {
      socket?.destroy();
    } catch (_) {}
  }
}

/// Neutral endpoints used to tell "internet is down" from "tunnel is down".
const internetProbes = <(String, int)>[
  ('1.1.1.1', 443),
  ('8.8.8.8', 443),
  ('9.9.9.9', 443),
];

Future<bool> internetReachable() async {
  for (final probe in internetProbes) {
    final rtt = await measureRtt(
      probe.$1,
      probe.$2,
      timeout: const Duration(milliseconds: 1500),
    );
    if (rtt != null) return true;
  }
  return false;
}
