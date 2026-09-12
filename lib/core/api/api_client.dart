import 'package:dio/dio.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required TokenStore tokens}) : _tokens = tokens {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokens.access;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_refreshing) {
            final ok = await _refreshTokens();
            if (ok) {
              final req = error.requestOptions;
              final access = await _tokens.access;
              req.headers['Authorization'] = 'Bearer $access';
              try {
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final String baseUrl;
  final TokenStore _tokens;
  late final Dio dio;
  bool _refreshing = false;

  Future<bool> _refreshTokens() async {
    final refresh = await _tokens.refresh;
    if (refresh == null || refresh.isEmpty) return false;
    _refreshing = true;
    try {
      final res = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final access = res.data['access_token'] as String?;
      if (access == null) return false;
      await _tokens.save(access: access, refresh: refresh);
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
