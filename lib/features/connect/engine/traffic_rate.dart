class TrafficRate {
  TrafficRate({this.window = const Duration(seconds: 1)});

  final Duration window;
  TrafficStatsSample? _prev;

  TrafficSnapshot update(TrafficStatsSample sample) {
    final prev = _prev;
    _prev = sample;
    if (prev == null) {
      return const TrafficSnapshot();
    }
    final dtMs = sample.at.difference(prev.at).inMilliseconds;
    if (dtMs <= 0) return const TrafficSnapshot();
    final dt = dtMs / 1000.0;
    return TrafficSnapshot(
      upBps: ((sample.upBytes - prev.upBytes).clamp(0, 1 << 62)) / dt,
      downBps: ((sample.downBytes - prev.downBytes).clamp(0, 1 << 62)) / dt,
    );
  }
}

class TrafficStatsSample {
  const TrafficStatsSample({
    required this.upBytes,
    required this.downBytes,
    required this.at,
  });
  final int upBytes;
  final int downBytes;
  final DateTime at;
}

class TrafficSnapshot {
  const TrafficSnapshot({this.upBps = 0, this.downBps = 0});
  final double upBps;
  final double downBps;
}

String formatBps(double bps) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var value = bps;
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  if (i == 0) return '${value.round()} ${units[i]}';
  return '${value.toStringAsFixed(1)} ${units[i]}';
}
