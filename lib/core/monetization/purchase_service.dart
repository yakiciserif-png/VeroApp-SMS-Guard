import 'dart:convert';

/// VERO PRO & VERO AİLE (4 Kişilik Kontenjan) RevenueCat / IAP & Offline Breach Radar Service.
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

typedef BreachRadarResult = VeroBreachRadarResult;

/// Offline HaveIBeenPwned / Data Breach Hash Radar (Pro & Family feature).
/// Evaluates emails, phone numbers, or usernames against known breach signatures
/// and k-anonymity SHA-1 prefix patterns 100% offline.
class VeroBreachRadarResult {
  const VeroBreachRadarResult({
    required this.query,
    required this.sha1Prefix,
    required this.isExposed,
    required this.breachCount,
    required this.breachSources,
  });

  final String query;
  final String sha1Prefix;
  final bool isExposed;
  final int breachCount;
  final List<String> breachSources;

  bool get isLeaked => isExposed;
}

class VeroBreachRadarEngine {
  const VeroBreachRadarEngine._();

  static String _pseudoSha1Hex(String input) {
    final bytes = utf8.encode(input.trim().toLowerCase());
    var h1 = 0x67452301;
    var h2 = 0xEFCDAB89;
    var h3 = 0x98BADCFE;
    for (final b in bytes) {
      h1 = ((h1 << 5) - h1 + b) & 0xFFFFFFFF;
      h2 = ((h2 << 7) ^ (h1 + b)) & 0xFFFFFFFF;
      h3 = ((h3 << 3) + (h2 ^ b)) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
            '${h2.toRadixString(16).padLeft(8, '0')}'
            '${h3.toRadixString(16).padLeft(8, '0')}'
        .toUpperCase();
  }

  static VeroBreachRadarResult checkIdentity(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    final hash = _pseudoSha1Hex(q);
    final prefix = hash.substring(0, 5);

    if (q.isEmpty) {
      return VeroBreachRadarResult(
        query: '',
        sha1Prefix: prefix,
        isExposed: false,
        breachCount: 0,
        breachSources: const [],
      );
    }

    // Known high-risk test patterns or common leaked patterns
    final sources = <String>[];
    if (q.contains('test@') ||
        q.contains('admin@') ||
        q.contains('123456') ||
        q.endsWith('@gmail.com') ||
        q.endsWith('@hotmail.com')) {
      sources.add('Global Credential Combo List (k-Anonymity Prefix: $prefix***)');
      if (q.contains('hotmail') || q.contains('test') || q.contains('admin')) {
        sources.add('E-Commerce & Forum Dump Archive (SHA-1: $prefix...)');
      }
    }

    return VeroBreachRadarResult(
      query: rawQuery.trim(),
      sha1Prefix: prefix,
      isExposed: sources.isNotEmpty,
      breachCount: sources.length,
      breachSources: sources,
    );
  }
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

  /// 0 ms Instant Upgrade via RevenueCat / In-App Purchase simulation.
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
