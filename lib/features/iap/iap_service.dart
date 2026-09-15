import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';

class IapUnavailableException implements Exception {
  IapUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Store purchase. Real StoreKit / Play Billing is wired on a laptop with
/// developer accounts (phase 7). This layer still posts receipts to redeem-iap.
class IapService {
  IapService(this._api);
  final ApiClient _api;

  Future<void> buy(PlanOffer plan) async {
    final productId =
        defaultTargetPlatform == TargetPlatform.iOS
            ? plan.appleProductId
            : plan.googleProductId;
    if (productId == null || productId.isEmpty) {
      throw IapUnavailableException(
        'این پلن در استور ثبت نشده است. از پشتیبانی بخواهید حساب را فعال کند.',
      );
    }
    throw IapUnavailableException(
      'خرید استور روی این بیلد فعال نیست. حساب دولوپر اپل/گوگل را روی لپ‌تاپ وصل کنید.',
    );
  }

  Future<Entitlement> redeem({
    required String provider,
    required String receipt,
    int? planId,
    String? productId,
  }) async {
    final res = await _api.dio.post(
      '/api/v1/entitlement/redeem-iap',
      data: {
        'provider': provider,
        'receipt': receipt,
        if (planId != null) 'plan_id': planId,
        if (productId != null) 'product_id': productId,
      },
    );
    return Entitlement.fromJson(res.data as Map<String, dynamic>);
  }

  String describeError(Object error) {
    if (error is IapUnavailableException) return error.message;
    if (error is DioException && error.response?.statusCode == 503) {
      return 'اعتبارسنجی استور روی پنل پیکربندی نشده است.';
    }
    return 'خرید انجام نشد.';
  }
}
