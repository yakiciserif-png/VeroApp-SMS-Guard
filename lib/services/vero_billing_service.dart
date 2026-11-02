import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/monetization/billing_service.dart';
import '../core/monetization/purchase_service.dart';

export '../core/monetization/billing_service.dart';

/// VeroApp High-Level Billing & Subscription Controller.
///
/// Handles:
/// 1. Google Play Billing (Android) & Apple StoreKit (iOS)
/// 2. Product ID catalog resolution
/// 3. Offline Ed25519 license activation and status persistence
/// 4. Startup subscription validity check
class VeroBillingController {
  VeroBillingController._();
  static final VeroBillingController instance = VeroBillingController._();

  static const String proMonthlyId = VeroProductIds.proMonthly;
  static const String proYearlyId = VeroProductIds.proYearly;
  static const String familyYearlyId = VeroProductIds.familyYearly;
  static const String enterpriseMonthlyId = VeroProductIds.enterpriseMonthly;

  /// Price labels in 100% accordance with VeroApp pricing guidelines:
  /// - PRO Aylık: 39,99 TL
  /// - PRO Yıllık: 299,99 TL
  /// - AİLE Yıllık: 799,99 TL
  /// - KURUMSAL Aylık: 19,99 TL/çalışan
  static const Map<String, String> productPrices = {
    proMonthlyId: '39,99 TL/ay',
    proYearlyId: '299,99 TL/yıl',
    familyYearlyId: '799,99 TL/yıl',
    enterpriseMonthlyId: '19,99 TL/çalışan/ay',
  };

  /// Initializes store billing and registers callbacks.
  Future<void> init() async {
    await VeroBillingService.instance.initialize(
      onSuccess: _onStorePurchaseSuccess,
      onError: _onStorePurchaseError,
    );
    await checkSubscriptionRenewal();
  }

  /// Initiates buy flow for a specific subscription product.
  Future<bool> purchase(String productId) async {
    return VeroBillingService.instance.buyProduct(productId);
  }

  /// Restores previous purchases across devices.
  Future<void> restore() async {
    await VeroBillingService.instance.restorePurchases();
  }

  /// Checks subscription validity on startup.
  Future<bool> checkSubscriptionRenewal() async {
    // If user has an active signed license or store subscription
    return PurchaseService.instance.isProOrFamily;
  }

  void _onStorePurchaseSuccess(VeroSubscriptionTier tier) {
    debugPrint('[VeroBilling] Purchase confirmed for tier: $tier');
    PurchaseService.instance.upgradeTo(tier);
  }

  void _onStorePurchaseError(String error) {
    debugPrint('[VeroBilling] Purchase error: $error');
  }
}
