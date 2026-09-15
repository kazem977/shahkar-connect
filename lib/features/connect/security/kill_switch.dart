import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';

enum KillSwitchState {
  /// Feature disabled by the user.
  off,

  /// Enabled and watching, traffic flows normally.
  armed,

  /// Traffic is blocked at the firewall right now.
  engaged,

  /// Platform or privileges cannot deliver a real lockdown.
  unavailable,
}

/// Blocks all traffic outside the tunnel using the platform firewall.
///
/// Windows is enforced for real: the outbound default action of every profile
/// is switched to *block* and only the client, the tunnel core, loopback and
/// (optionally) the local subnet are allowed through. The previous policy is
/// persisted so a crash or power loss can be undone on the next launch.
class KillSwitchService extends ChangeNotifier {
  KillSwitchService({required AppPrefs prefs}) : _prefs = prefs;

  static const _rulePrefix = 'VPNAI Kill Switch';
  static const _profiles = ['domainprofile', 'privateprofile', 'publicprofile'];

  final AppPrefs _prefs;

  KillSwitchState state = KillSwitchState.off;

  /// Set when the lockdown cannot be enforced (wrong platform, no admin).
  String? blocker;

  bool? _elevated;
  String? _corePath;

  bool get platformSupported => Platform.isWindows;
  bool get engaged => state == KillSwitchState.engaged;

  /// Path of the tunnel core, allowed to reach the internet during lockdown.
  set corePath(String? value) => _corePath = value;

  /// Clears a lockdown that survived a crash, then reflects the current mode.
  ///
  /// If the restore fails (typically because this launch is not elevated) the
  /// flag is kept and the state stays `engaged`, so the UI can still offer a way
  /// out instead of claiming the network is open while it is not.
  Future<void> restoreAfterCrash() async {
    if (_prefs.lockdownActive && platformSupported) {
      final restored = await _restorePolicy();
      await _deleteRules();
      if (!restored) {
        _set(KillSwitchState.engaged, blocker: 'admin');
        return;
      }
      await _prefs.rememberLockdown(active: false);
    }
    await syncWithMode();
  }

  /// Aligns the reported state with the mode the user picked.
  Future<void> syncWithMode() async {
    if (_prefs.killSwitch == KillSwitchMode.off) {
      if (engaged) await release();
      _set(KillSwitchState.off, blocker: null);
      return;
    }
    if (!platformSupported) {
      _set(KillSwitchState.unavailable, blocker: 'platform');
      return;
    }
    if (!await _isElevated()) {
      _set(KillSwitchState.unavailable, blocker: 'admin');
      return;
    }
    if (!engaged) _set(KillSwitchState.armed, blocker: null);
  }

  /// Called when a connection attempt starts.
  Future<void> onConnecting() async {
    await syncWithMode();
    if (_prefs.killSwitch == KillSwitchMode.strict &&
        state == KillSwitchState.armed) {
      await engage();
    }
  }

  /// Called once the tunnel is up.
  Future<void> onConnected() async {
    if (_prefs.killSwitch == KillSwitchMode.strict &&
        state == KillSwitchState.armed) {
      await engage();
    }
  }

  /// Called when the tunnel dies without the user asking for it.
  Future<void> onUnexpectedDrop() async {
    if (_prefs.killSwitch == KillSwitchMode.off) return;
    await syncWithMode();
    if (state == KillSwitchState.armed) await engage();
  }

  /// Called when the user deliberately disconnects.
  Future<void> onUserDisconnect() async {
    if (engaged) await release();
    await syncWithMode();
  }

  /// Blocks everything except the client, the tunnel core and loopback.
  Future<void> engage() async {
    if (!platformSupported || engaged) return;
    if (!await _isElevated()) {
      _set(KillSwitchState.unavailable, blocker: 'admin');
      return;
    }
    final saved = await _readPolicy();
    await _prefs.rememberLockdown(active: true, policy: saved);
    await _deleteRules();
    await _addAllowRules();
    final ok = await _setPolicy('blockinbound,blockoutbound');
    if (!ok) {
      await _restorePolicy();
      await _deleteRules();
      await _prefs.rememberLockdown(active: false);
      _set(KillSwitchState.unavailable, blocker: 'firewall');
      return;
    }
    _set(KillSwitchState.engaged, blocker: null);
  }

  /// Lets traffic flow again and removes every rule we created.
  Future<void> release() async {
    if (!platformSupported) {
      _set(KillSwitchState.unavailable, blocker: 'platform');
      return;
    }
    final restored = await _restorePolicy();
    await _deleteRules();
    if (!restored) {
      _set(KillSwitchState.engaged, blocker: 'admin');
      return;
    }
    await _prefs.rememberLockdown(active: false);
    _set(
      _prefs.killSwitch == KillSwitchMode.off
          ? KillSwitchState.off
          : KillSwitchState.armed,
      blocker: null,
    );
  }

  /// Restarts the client with administrator rights so the lockdown can work.
  Future<bool> relaunchElevated() async {
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        "Start-Process -FilePath '${Platform.resolvedExecutable}' -Verb RunAs",
      ]);
      if (res.exitCode != 0) return false;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      exit(0);
    } catch (_) {
      return false;
    }
  }

  void _set(KillSwitchState value, {required String? blocker}) {
    if (state == value && this.blocker == blocker) return;
    state = value;
    this.blocker = blocker;
    notifyListeners();
  }

  Future<bool> _isElevated() async {
    if (!Platform.isWindows) return false;
    final cached = _elevated;
    if (cached != null) return cached;
    try {
      final res = await Process.run('net', ['session'], runInShell: true);
      return _elevated = res.exitCode == 0;
    } catch (_) {
      return _elevated = false;
    }
  }

  Future<Map<String, String>> _readPolicy() async {
    final out = <String, String>{};
    for (final profile in _profiles) {
      try {
        final res = await Process.run(
          'netsh',
          ['advfirewall', 'show', profile, 'firewallpolicy'],
          runInShell: true,
        );
        final text = '${res.stdout}';
        final match = RegExp(
          r'(Block|Allow)(?:Inbound[A-Za-z]*|inbound[A-Za-z]*),\s*(Block|Allow)(?:Outbound|outbound)',
        ).firstMatch(text.replaceAll(' ', ''));
        if (match != null) {
          out[profile] =
              '${match.group(1)!.toLowerCase()}inbound,${match.group(2)!.toLowerCase()}outbound';
        }
      } catch (_) {}
    }
    return out;
  }

  Future<bool> _setPolicy(String policy) async {
    var ok = true;
    for (final profile in _profiles) {
      ok = await _netsh([
            'advfirewall',
            'set',
            profile,
            'firewallpolicy',
            policy,
          ]) &&
          ok;
    }
    return ok;
  }

  Future<bool> _restorePolicy() async {
    final saved = _prefs.savedFirewallPolicy;
    var ok = true;
    for (final profile in _profiles) {
      final policy = saved[profile] ?? 'blockinbound,allowoutbound';
      ok = await _netsh([
            'advfirewall',
            'set',
            profile,
            'firewallpolicy',
            policy,
          ]) &&
          ok;
    }
    return ok;
  }

  Future<void> _addAllowRules() async {
    final client = Platform.resolvedExecutable;
    final core = _corePath;

    await _addRule(['program=$client'], 'Client');
    if (core != null && core.isNotEmpty) {
      await _addRule(['program=$core'], 'Core');
    }
    await _addRule(['remoteip=127.0.0.1'], 'Loopback');
    if (_prefs.allowLan) {
      await _addRule(['remoteip=LocalSubnet'], 'LAN');
      await _addRule(['remoteip=224.0.0.0-239.255.255.255'], 'Multicast');
    }
  }

  Future<void> _addRule(List<String> match, String suffix) async {
    for (final dir in ['out', 'in']) {
      await _netsh([
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=$_rulePrefix $suffix $dir',
        'dir=$dir',
        'action=allow',
        'enable=yes',
        'profile=any',
        ...match,
      ]);
    }
  }

  Future<void> _deleteRules() async {
    for (final suffix in const [
      'Client',
      'Core',
      'Loopback',
      'LAN',
      'Multicast',
    ]) {
      for (final dir in ['out', 'in']) {
        await _netsh([
          'advfirewall',
          'firewall',
          'delete',
          'rule',
          'name=$_rulePrefix $suffix $dir',
        ]);
      }
    }
  }

  Future<bool> _netsh(List<String> args) async {
    try {
      final res = await Process.run('netsh', args, runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
