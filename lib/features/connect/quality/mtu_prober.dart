import 'dart:io';

/// Discovers the largest packet that reaches a host without fragmentation and
/// turns it into a TUN MTU.
///
/// Wrong MTU is one of the most common causes of "connected but slow" tunnels:
/// oversized packets are silently dropped and every transfer stalls on
/// retransmits. A binary search with the don't-fragment bit finds the real path
/// limit in a few seconds.
class MtuProber {
  const MtuProber();

  static const int minMtu = 1200;
  static const int maxMtu = 1500;

  /// IPv4 + ICMP header overhead subtracted from the payload size.
  static const int _icmpOverhead = 28;

  /// Room for the tunnel's own encapsulation on top of the path MTU.
  static const int _tunnelOverhead = 80;

  /// Returns the MTU to configure, or null when probing is not possible.
  Future<int?> probe(String host) async {
    if (host.isEmpty) return null;
    if (!Platform.isWindows) return null;

    var low = minMtu - _icmpOverhead;
    var high = maxMtu - _icmpOverhead;
    if (!await _pings(host, low)) return null;
    if (await _pings(host, high)) return maxMtu - _tunnelOverhead;

    while (high - low > 8) {
      final mid = (low + high) ~/ 2;
      if (await _pings(host, mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final pathMtu = low + _icmpOverhead;
    return (pathMtu - _tunnelOverhead).clamp(1000, maxMtu);
  }

  Future<bool> _pings(String host, int payload) async {
    try {
      final res = await Process.run(
        'ping',
        ['-n', '1', '-w', '1200', '-f', '-l', '$payload', host],
        runInShell: true,
      );
      final out = '${res.stdout}'.toLowerCase();
      if (out.contains('needs to be fragmented') ||
          out.contains('packet needs to be fragmented')) {
        return false;
      }
      return res.exitCode == 0 && out.contains('ttl=');
    } catch (_) {
      return false;
    }
  }
}
