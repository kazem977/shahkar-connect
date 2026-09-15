import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shahkar_connect/core/device.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStore tokens,
    this.appVersion = '0.1.0',
  }) : _tokens = tokens {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _applyLabTls(dio, baseUrl);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-App-Platform'] = hostPlatformName();
          options.headers['X-App-Version'] = appVersion;
          try {
            options.headers['X-Device-Id'] = await _tokens.deviceId();
          } catch (_) {}
          final access = await _tokens.access;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthCall = path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/refresh');
          if (error.response?.statusCode == 401 &&
              !_refreshing &&
              !isAuthCall) {
            final ok = await _refreshTokens();
            if (ok) {
              final req = error.requestOptions;
              final access = await _tokens.access;
              req.headers['Authorization'] = 'Bearer $access';
              try {
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              } catch (_) {
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
  final String appVersion;
  final TokenStore _tokens;
  late final Dio dio;
  bool _refreshing = false;

  void _applyLabTls(Dio client, String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (InternetAddress.tryParse(host) == null) return;
    client.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final http = HttpClient();
        http.badCertificateCallback =
            (cert, hostName, port) => hostName == host;
        return http;
      },
    );
  }

  Future<bool> _refreshTokens() async {
    final refresh = await _tokens.refresh;
    if (refresh == null || refresh.isEmpty) return false;
    _refreshing = true;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      _applyLabTls(refreshDio, baseUrl);
      final res = await refreshDio.post(
        '/api/v2/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = res.data;
      if (data is! Map) return false;
      final access = data['access_token'] as String?;
      if (access == null || access.isEmpty) return false;
      final nextRefresh = data['refresh_token'] as String? ?? refresh;
      await _tokens.save(access: access, refresh: nextRefresh);
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
