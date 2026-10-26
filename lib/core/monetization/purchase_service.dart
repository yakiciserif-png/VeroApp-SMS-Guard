export '../../engines/vero_bloom_filter.dart';
export '../../engines/vero_breach_radar_engine.dart';

/// VERO PRO & VERO AİLE (4 Kişilik Kontenjan) Offline Subscription & Plan Service.
enum VeroSubscriptionTier {
  free,
  proMonthly,
  proYearly,
  familyYearly,
}

class VeroPlanCatalog {
  const VeroPlanCatalog._();

  static const String proMonthlyPriceTr = '149,99 TL / Ay';
  static const String proYearlyPriceTr = '1.199,99 TL / Yıl';
  static const String familyYearlyPriceTr = '3.600 TL / Yıl (4 Kişilik Kontenjan)';

  static const String proMonthlyPriceEn = '149.99 TL / Month';
  static const String proYearlyPriceEn = '1,199.99 TL / Year';
  static const String familyYearlyPriceEn = '3,600 TL / Year (4-Member Quota)';

  static const String proMonthlyPriceText = proMonthlyPriceTr;
  static const String proYearlyPriceText = proYearlyPriceTr;
  static const String familyYearlyPriceText = familyYearlyPriceTr;
}

class PurchaseService {
  PurchaseService({
    this.tier = VeroSubscriptionTier.free,
    this.isFamilyOwner = true,
    this.isFamilyMember = false,
    this.familyCode = '892341',
    this.connectedFamilyMembers = 4,
  });

  VeroSubscriptionTier tier;
  bool isFamilyOwner;
  bool isFamilyMember;
  String familyCode;
  int connectedFamilyMembers;
  final int maxFamilyMembers = 4;

  /// True when user holds VERO PRO, VERO AİLE, or joined a Family via 6-digit code.
  bool get isProOrFamily =>
      tier != VeroSubscriptionTier.free || isFamilyMember;

  /// Formatted 6-digit family code (e.g., `8 9 2  3 4 1`).
  String get formattedFamilyCode {
    final clean = familyCode.replaceAll(RegExp(r'\D'), '').padRight(6, '0');
    return '${clean[0]} ${clean[1]} ${clean[2]}  ${clean[3]} ${clean[4]} ${clean[5]}';
  }

  /// 0 ms Instant Upgrade via In-App Purchase state transition.
  void upgradeTo(VeroSubscriptionTier newTier) {
    tier = newTier;
    if (newTier == VeroSubscriptionTier.familyYearly) {
      isFamilyOwner = true;
      isFamilyMember = false;
      connectedFamilyMembers = 4;
    } else if (newTier == VeroSubscriptionTier.free) {
      isFamilyOwner = false;
      isFamilyMember = false;
    } else {
      isFamilyOwner = false;
    }
  }

  /// Validates a 6-digit numeric Family Code and activates Family Member protection in 0 ms.
  bool joinFamilyWithCode(String rawCode) {
    final digits = rawCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return false;
    familyCode = digits;
    tier = VeroSubscriptionTier.familyYearly;
    isFamilyOwner = false;
    isFamilyMember = true;
    connectedFamilyMembers = 4;
    return true;
  }
}
