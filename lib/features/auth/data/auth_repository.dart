import 'package:dio/dio.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';
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
      '/api/v1/auth/login',
      data: {'username': username, 'password': password},
    );
    await _save(res.data as Map<String, dynamic>);
  }

  Future<void> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final res = await _api.dio.post(
      '/api/v1/auth/register',
      data: {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    await _save(res.data as Map<String, dynamic>);
  }

  Future<Entitlement> me() async {
    final res = await _api.dio.get('/api/v1/entitlement/me');
    return Entitlement.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() => _tokens.clear();

  Future<void> _save(Map<String, dynamic> data) {
    return _tokens.save(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }

  String describeError(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 404) {
        return 'سرویس اپ هنوز روی پنل فعال نشده است.';
      }
      if (code == 401) {
        return 'نام کاربری یا رمز نادرست است.';
      }
      final detail = error.response?.data;
      if (detail is Map && detail['detail'] != null) {
        return detail['detail'].toString();
      }
    }
    return 'ارتباط با سرور برقرار نشد.';
  }
}
