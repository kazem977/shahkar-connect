import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahkar_connect/core/device.dart';

class TokenStore {
  TokenStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _device = 'device_id';

  Future<SharedPreferences> _ready() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> save({required String access, required String refresh}) async {
    final prefs = await _ready();
    await prefs.setString(_access, access);
    await prefs.setString(_refresh, refresh);
  }

  Future<String?> get access async => (await _ready()).getString(_access);
  Future<String?> get refresh async => (await _ready()).getString(_refresh);

  Future<String> deviceId() async {
    final prefs = await _ready();
    final existing = prefs.getString(_device);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = newDeviceId();
    await prefs.setString(_device, created);
    return created;
  }

  Future<bool> hasSession() async {
    final token = await access;
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await _ready();
    await prefs.remove(_access);
    await prefs.remove(_refresh);
  }
}
