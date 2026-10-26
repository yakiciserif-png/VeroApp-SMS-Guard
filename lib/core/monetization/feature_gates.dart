import 'purchase_service.dart';

/// Detailed comparison row across Free, PRO, and Family plans.
class FeatureComparisonRow {
  const FeatureComparisonRow({
    required this.featureTr,
    required this.featureEn,
    required this.freeText,
    required this.proText,
    required this.familyText,
    required this.freeAllowed,
    required this.proAllowed,
    required this.familyAllowed,
  });

  final String featureTr;
  final String featureEn;
  final String freeText;
  final String proText;
  final String familyText;
  final bool freeAllowed;
  final bool proAllowed;
  final bool familyAllowed;
}

/// [ADIM 2] FREE vs PRO Feature Gate & Quota Logic.
class VeroFeatureGates {
  const VeroFeatureGates._();

  static const int freeDailySmsLimit = 20;
  static const int freeDailyLinkLimit = 5;
  static const int freeDailyBreachQueries = 1;

  static bool isProOrHigher(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return tier != VeroSubscriptionTier.free || isFamilyMember;
  }

  static bool isFamily(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return tier == VeroSubscriptionTier.familyYearly || isFamilyMember;
  }

  static bool canAnalyzeSms(VeroSubscriptionTier tier, int todaySmsCount, {bool isFamilyMember = false}) {
    if (isProOrHigher(tier, isFamilyMember: isFamilyMember)) return true;
    return todaySmsCount < freeDailySmsLimit;
  }

  static bool canScanLink(VeroSubscriptionTier tier, int todayLinkCount, {bool isFamilyMember = false}) {
    if (isProOrHigher(tier, isFamilyMember: isFamilyMember)) return true;
    return todayLinkCount < freeDailyLinkLimit;
  }

  static bool canQueryBreach(VeroSubscriptionTier tier, int todayBreachCount, {bool isFamilyMember = false}) {
    if (isProOrHigher(tier, isFamilyMember: isFamilyMember)) return true;
    return todayBreachCount < freeDailyBreachQueries;
  }

  static bool canShowCallerName(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isProOrHigher(tier, isFamilyMember: isFamilyMember);
  }

  static bool canUseAnswerBot(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isProOrHigher(tier, isFamilyMember: isFamilyMember);
  }

  static bool canViewAdvancedStats(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isProOrHigher(tier, isFamilyMember: isFamilyMember);
  }

  static bool canUseWidgets(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isProOrHigher(tier, isFamilyMember: isFamilyMember);
  }

  static bool canUseEDevletGuard(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isProOrHigher(tier, isFamilyMember: isFamilyMember);
  }

  static bool canUseFamilyPlan(VeroSubscriptionTier tier, {bool isFamilyMember = false}) {
    return isFamily(tier, isFamilyMember: isFamilyMember);
  }

  static const List<FeatureComparisonRow> comparisonRows = [
    FeatureComparisonRow(
      featureTr: 'SMS Analizi & Kalkan',
      featureEn: 'SMS Analysis & Shield',
      freeText: '20 mesaj/gün',
      proText: 'Sınırsız',
      familyText: 'Sınırsız (4 Cihaz)',
      freeAllowed: true,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'Arama Koruması',
      featureEn: 'Call Protection',
      freeText: 'Temel Spam Alarmı',
      proText: 'Sınırsız + Answer Bot',
      familyText: 'Sınırsız + Answer Bot',
      freeAllowed: true,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'Caller ID (Arayan İsim)',
      featureEn: 'Caller ID (Caller Name)',
      freeText: 'Sadece Spam/Güvenli',
      proText: 'Tam İsim + Güven Skoru',
      familyText: 'Tam İsim + Güven Skoru',
      freeAllowed: false,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'Link Tarama (Safe-Click)',
      featureEn: 'Link Scanner (Safe-Click)',
      freeText: '5 link/gün',
      proText: 'Sınırsız',
      familyText: 'Sınırsız',
      freeAllowed: true,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'Veri Sızıntısı Radarı',
      featureEn: 'Breach Radar',
      freeText: '1 sorgu/gün',
      proText: 'Sınırsız',
      familyText: 'Sınırsız',
      freeAllowed: true,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'İstatistik & Raporlama',
      featureEn: 'Stats & Reporting',
      freeText: 'Sadece Bugün',
      proText: 'Günlük + Haftalık + Trend',
      familyText: 'Tüm Aile Aktivite Özeti',
      freeAllowed: false,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'Ana Ekran Widget (4x1 & 2x2)',
      featureEn: 'Home Widgets (4x1 & 2x2)',
      freeText: 'Yok',
      proText: 'Tam Destek',
      familyText: 'Tam Destek',
      freeAllowed: false,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: 'e-Devlet Şifre Güvenliği',
      featureEn: 'e-Government Security',
      freeText: 'Yok',
      proText: 'Tam Denetim',
      familyText: 'Tam Denetim',
      freeAllowed: false,
      proAllowed: true,
      familyAllowed: true,
    ),
    FeatureComparisonRow(
      featureTr: '4 Kişilik Aile Ağı (6 Haneli Kod)',
      featureEn: '4-Member Family Network',
      freeText: 'Yok',
      proText: 'Yok',
      familyText: '4 Cihaz Tek Kodla',
      freeAllowed: false,
      proAllowed: false,
      familyAllowed: true,
    ),
  ];
}
