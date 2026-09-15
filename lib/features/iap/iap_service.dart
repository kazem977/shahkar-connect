import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';

class IapUnavailableException implements Exception {
  IapUnavailableException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// StoreKit / Play Billing on mobile; redeem still goes to the panel.
class IapService {
  IapService(this._api) {
    if (_storeSupported) {
      _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchases,
        onError: (_) {},
      );
    }
  }

  final ApiClient _api;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<PurchaseDetails>? _pending;

  static bool get _storeSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<Entitlement> buy(PlanOffer plan) async {
    final productId = defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? plan.appleProductId
        : plan.googleProductId;
    if (productId == null || productId.isEmpty) {
      throw IapUnavailableException(
        'این پلن در استور ثبت نشده است. از پشتیبانی بخواهید حساب را فعال کند.',
      );
    }
    if (!_storeSupported) {
      throw IapUnavailableException(
        'خرید داخل‌برنامه‌ای روی این پلتفرم نیست. از پشتیبانی بخواهید حساب را فعال کند.',
      );
    }
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      throw IapUnavailableException('فروشگاه روی این دستگاه در دسترس نیست.');
    }
    final queried = await iap.queryProductDetails({productId});
    if (queried.productDetails.isEmpty) {
      throw IapUnavailableException(
        'این پلن در استور ثبت نشده است. از پشتیبانی بخواهید حساب را فعال کند.',
      );
    }
    _pending = Completer<PurchaseDetails>();
    final param = PurchaseParam(productDetails: queried.productDetails.first);
    var started = false;
    try {
      started = await iap.buyConsumable(
        purchaseParam: param,
        autoConsume: false,
      );
    } catch (_) {
      started = await iap.buyNonConsumable(purchaseParam: param);
    }
    if (!started) {
      _pending = null;
      throw IapUnavailableException('خرید شروع نشد.');
    }
    final purchase = await _pending!.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () {
        throw IapUnavailableException('خرید زمان‌دار شد.');
      },
    );
    if (purchase.status == PurchaseStatus.canceled) {
      throw IapUnavailableException('خرید لغو شد.');
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      throw IapUnavailableException(
          purchase.error?.message ?? 'خرید انجام نشد.');
    }
    final provider =
        defaultTargetPlatform == TargetPlatform.android ? 'google' : 'apple';
    final proof = purchase.verificationData.serverVerificationData.isNotEmpty
        ? purchase.verificationData.serverVerificationData
        : purchase.verificationData.localVerificationData;
    try {
      final entitlement = await redeem(
        provider: provider,
        receipt: proof,
        planId: plan.id,
        productId: productId,
      );
      if (purchase.pendingCompletePurchase) {
        await iap.completePurchase(purchase);
      }
      return entitlement;
    } finally {
      _pending = null;
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      pending.complete(purchase);
      return;
    }
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
    if (error is TimeoutException) return 'خرید زمان‌دار شد.';
    if (error is DioException && error.response?.statusCode == 503) {
      return 'اعتبارسنجی استور روی پنل پیکربندی نشده است.';
    }
    return 'خرید انجام نشد.';
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
  }
}
