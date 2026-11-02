import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_service.dart';

/// Product IDs for Google Play Billing (Android) and StoreKit (iOS).
class VeroProductIds {
  VeroProductIds._();

  static const String proMonthly = 'vero_pro_monthly';
  static const String proYearly = 'vero_pro_yearly';
  static const String familyYearly = 'vero_family_yearly';
  static const String enterpriseMonthly = 'vero_enterprise_monthly';

  static const Set<String> allProducts = {
    proMonthly,
    proYearly,
    familyYearly,
    enterpriseMonthly,
  };
}

/// [ADIM 7] REAL GOOGLE PLAY BILLING & APPLE STOREKIT IN-APP PURCHASE SERVICE.
///
/// Connects to Google Play Billing (Google Play Store) and StoreKit (Apple App Store)
/// using official `in_app_purchase` plugin.
/// Includes offline & desktop graceful fallback when Store billing APIs are unavailable.
class VeroBillingService {
  VeroBillingService._();
  static final VeroBillingService instance = VeroBillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _initialized = false;

  bool get isAvailable => _isAvailable;
  bool get isInitialized => _initialized;
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Callback when a verified purchase or restore completes.
  void Function(VeroSubscriptionTier tier)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;

  /// Initializes the In-App Purchase stream and queries product catalog.
  Future<void> initialize({
    void Function(VeroSubscriptionTier tier)? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_initialized) return;
    onPurchaseSuccess = onSuccess;
    onPurchaseError = onError;

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile) {
      _isAvailable = false;
      _initialized = true;
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        _subscription = _iap.purchaseStream.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) {
            onPurchaseError?.call('Store purchase stream error: $error');
          },
        );

        final response = await _iap.queryProductDetails(VeroProductIds.allProducts);
        if (response.notFoundIDs.isEmpty) {
          _products = response.productDetails;
        } else {
          _products = response.productDetails;
        }
      }
    } catch (e) {
      _isAvailable = false;
    }
    _initialized = true;
  }

  /// Initiates buy flow for the requested product ID.
  Future<bool> buyProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('Mağaza ödeme servisi şu an kullanılamıyor.');
      return false;
    }

    ProductDetails? product;
    for (final p in _products) {
      if (p.id == productId) {
        product = p;
        break;
      }
    }

    if (product == null) {
      onPurchaseError?.call('Ürün mağazada bulunamadı: $productId');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      // Subscriptions use buyNonConsumable in in_app_purchase
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      onPurchaseError?.call('Satın alma başlatılamadı: $e');
      return false;
    }
  }

  /// Restores previous purchases (e.g. on new device or reinstall).
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Mağaza servisi aktif değil.');
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      onPurchaseError?.call('Satın alımları geri yükleme hatası: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Pending approval / carrier billing confirmation
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseError?.call(purchase.error?.message ?? 'Satın alma iptal edildi veya başarısız oldu.');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final tier = _mapProductToTier(purchase.productID);
        onPurchaseSuccess?.call(tier);

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  VeroSubscriptionTier _mapProductToTier(String productId) {
    switch (productId) {
      case VeroProductIds.proMonthly:
        return VeroSubscriptionTier.proMonthly;
      case VeroProductIds.proYearly:
        return VeroSubscriptionTier.proYearly;
      case VeroProductIds.familyYearly:
        return VeroSubscriptionTier.familyYearly;
      case VeroProductIds.enterpriseMonthly:
        return VeroSubscriptionTier.familyYearly;
      default:
        return VeroSubscriptionTier.proMonthly;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
