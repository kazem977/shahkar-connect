import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shahkar_connect/features/connect/engine/clash_poller.dart';
import 'package:shahkar_connect/features/connect/engine/singbox_prepare.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';

/// Runs a local `sing-box` binary. Set `SINGBOX_BIN` or put the binary at
/// `native/bin/sing-box` after `tool/fetch_singbox.sh`.
class DesktopVpnEngine implements VpnEngine {
  DesktopVpnEngine({String? binaryPath}) : _binaryPath = binaryPath;

  final String? _binaryPath;
  final _state = StreamController<ConnectionStateSnap>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();
  late final ClashTrafficPoller _poller = ClashTrafficPoller(
    onStats: _traffic.add,
  );
  Process? _process;
  File? _configFile;
  StreamSubscription<int>? _exitSub;
  bool _stopping = false;

  @override
  Future<void> connect(SingBoxConfig config) async {
    await disconnect();
    final bin = _resolveBinary();
    if (bin == null) {
      throw VpnUnavailableException(
        'باینری sing-box پیدا نشد. روی ویندوز tool/fetch_singbox.ps1 '
        'و روی مک/لینوکس tool/fetch_singbox.sh را اجرا کنید.',
      );
    }
    _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.connecting));
    final prepared = prepareSingBoxConfig(
      config.json,
      runtime: SingBoxRuntime.desktop,
      options: config.options,
    );
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}shahkar-singbox-$pid.json',
    );
    await file.writeAsString(prepared.json, encoding: utf8);
    _configFile = file;
    final workDir = File(bin).parent.path;
    try {
      _process = await Process.start(
        bin,
        ['run', '-c', file.path],
        workingDirectory: workDir,
      );
    } on ProcessException catch (e) {
      throw VpnUnavailableException('اجرای sing-box ناموفق بود: ${e.message}');
    }
    final proc = _process!;
    _stopping = false;
    var exitedEarly = false;
    var earlyCode = -1;
    final errBuf = StringBuffer();
    proc.stderr.transform(utf8.decoder).listen(errBuf.write);
    _exitSub = proc.exitCode.asStream().listen((code) {
      _poller.stop();
      exitedEarly = true;
      earlyCode = code;
      _process = null;
      if (_stopping) return;
      if (code != 0) {
        _state.add(
          ConnectionStateSnap(
            kind: ConnectionStateKind.error,
            message: _humanizeExit(code, errBuf.toString()),
          ),
        );
      } else {
        _state.add(const ConnectionStateSnap(kind: ConnectionStateKind.idle));
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (exitedEarly || _process == null) {
      throw VpnUnavailableException(
        _humanizeExit(earlyCode, errBuf.toString()),
      );
    }
    _poller.start(port: prepared.clashPort);
    _state.add(
      ConnectionStateSnap(kind: ConnectionStateKind.connected, message: bin),
    );
  }

  @override
  Future<void> disconnect() async {
    _stopping = true;
    _poller.stop();
    await _exitSub?.cancel();
    _exitSub = null;
    final proc = _process;
    _process = null;
    if (proc != null) {
      if (Platform.isWindows) {
        proc.kill();
      } else {
        proc.kill(ProcessSignal.sigterm);
      }
    }
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

  @override
  String? get corePath => _resolveBinary();

  String _humanizeExit(int code, String err) {
    final lower = err.toLowerCase();
    if (lower.contains('access is denied') ||
        lower.contains('permission') ||
        lower.contains('operation not permitted') ||
        lower.contains('cap_net_admin')) {
      return 'برای تونل سیستم باید اپ را با دسترسی مدیر اجرا کنید.';
    }
    if (err.trim().isNotEmpty) {
      return err.trim().split('\n').last;
    }
    return 'تونل با کد $code متوقف شد.';
  }

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
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final names = Platform.isWindows
        ? <String>['sing-box.exe', 'sing-box']
        : <String>['sing-box', 'sing-box.exe'];
    final dirs = <String>[
      'native${Platform.pathSeparator}bin',
      exeDir,
      '$exeDir${Platform.pathSeparator}data',
      Directory.current.path,
      '${Directory.current.path}${Platform.pathSeparator}native${Platform.pathSeparator}bin',
    ];
    for (final dir in dirs) {
      for (final name in names) {
        final candidate = '$dir${Platform.pathSeparator}$name';
        if (File(candidate).existsSync()) return candidate;
      }
    }
    return null;
  }
}
