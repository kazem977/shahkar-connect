import 'package:dio/dio.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/api_errors.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStore tokens})
      : _api = api,
        _tokens = tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/api/v2/auth/login',
      data: {'username': username, 'password': password},
    );
    await _saveTokens(res.data as Map<String, dynamic>);
  }

  Future<void> register({
    required String username,
    required String password,
    String? email,
  }) async {
    await _api.dio.post(
      '/api/public/register',
      data: {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'contact': email,
      },
    );
    // Public register returns a portal JWT only. App session needs v2 tokens.
    await login(username: username, password: password);
  }

  Future<Entitlement> me() async {
    final res = await _api.dio.get('/api/v2/client/config');
    return Entitlement.fromClientConfig(res.data as Map<String, dynamic>);
  }

  Future<void> logout() => _tokens.clear();

  Future<void> _saveTokens(Map<String, dynamic> data) {
    final access = data['access_token'] as String? ?? '';
    final refresh = data['refresh_token'] as String? ?? '';
    if (access.isEmpty) {
      throw StateError('missing access_token');
    }
    return _tokens.save(access: access, refresh: refresh);
  }

  String describeError(Object error, S s) {
    if (error is DioException && error.response?.statusCode == 401) {
      return s.badCredentials;
    }
    return describeApiError(error, s: s);
  }
}
