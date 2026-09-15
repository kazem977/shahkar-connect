import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

/// Runs a local `sing-box` binary. Set `SINGBOX_BIN` or put the binary at
/// `native/bin/sing-box` after `tool/fetch_singbox.sh`.
class DesktopVpnEngine implements VpnEngine {
  DesktopVpnEngine({String? binaryPath}) : _binaryPath = binaryPath;

  final String? _binaryPath;
  final _state = StreamController<ConnectionStateSnap>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();
  Process? _process;
  File? _configFile;

  @override
  Future<void> connect(SingBoxConfig config) async {
    await disconnect();
    final bin = _resolveBinary();
    if (bin == null) {
      throw VpnUnavailableException(
        'باینری sing-box پیدا نشد. روی لپ‌تاپ tool/fetch_singbox.sh را اجرا کنید.',
      );
    }
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.connecting));
    final file = File(
      '${Directory.systemTemp.path}/shahkar-singbox-$pid.json',
    );
    await file.writeAsString(config.json, encoding: utf8);
    _configFile = file;
    try {
      _process = await Process.start(bin, ['run', '-c', file.path]);
    } on ProcessException catch (e) {
      throw VpnUnavailableException('اجرای sing-box ناموفق بود: ${e.message}');
    }
    _state.add(
      ConnectionStateSnap(kind: ConnectionStateKind.connected, message: bin),
    );
  }

  @override
  Future<void> disconnect() async {
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    try {
      await _configFile?.delete();
    } catch (_) {}
    _configFile = null;
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.idle));
  }

  @override
  Stream<ConnectionStateSnap> get stateStream => _state.stream;

  @override
  Stream<TrafficStats> get trafficStream => _traffic.stream;

  String? _resolveBinary() {
    final fromCtor = _binaryPath;
    if (fromCtor != null &&
        fromCtor.isNotEmpty &&
        File(fromCtor).existsSync()) {
      return fromCtor;
    }
    final env = Platform.environment['SINGBOX_BIN'];
    if (env != null && env.isNotEmpty && File(env).existsSync()) {
      return env;
    }
    for (final candidate in [
      'native/bin/sing-box',
      'native/bin/sing-box.exe',
    ]) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }
}
