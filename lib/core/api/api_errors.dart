import 'package:dio/dio.dart';
import 'package:shahkar_connect/core/l10n/s.dart';

String describeApiError(Object error, {S? s, String? fallback}) {
  final t = s ?? const S('en');
  if (error is DioException) {
    final code = error.response?.statusCode;
    final detail = _extractDetail(error.response?.data);
    if (detail != null && detail.isNotEmpty) {
      final lower = detail.toLowerCase();
      if (lower.contains('already exists') || lower.contains('already taken')) {
        return t.usernameTaken;
      }
      if (lower.contains('username only') ||
          lower.contains('a-z') ||
          lower.contains('underscores')) {
        return t.usernameInvalid;
      }
      return detail;
    }
    if (code == 404) return t.apiOff;
    if (code == 401) return t.sessionExpired;
    if (code == 403) return t.forbidden;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return t.offline;
    }
  }
  return fallback ?? t.offline;
}

String? _extractDetail(Object? data) {
  if (data is! Map) return null;
  final detail = data['detail'];
  if (detail == null) return null;
  if (detail is String) return detail;
  if (detail is Map) {
    final parts = <String>[];
    for (final entry in detail.entries) {
      parts.add(entry.value.toString());
    }
    return parts.join(' ');
  }
  if (detail is List) {
    final parts = <String>[];
    for (final item in detail) {
      if (item is Map && item['msg'] != null) {
        parts.add(item['msg'].toString());
      } else {
        parts.add(item.toString());
      }
    }
    return parts.join(' ');
  }
  return detail.toString();
}
