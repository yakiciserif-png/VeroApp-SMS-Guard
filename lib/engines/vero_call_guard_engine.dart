/// [ADIM 4] VERO CALL GUARD ENGINE — Integrated with Offline Caller ID (`VeroCallerIdEngine`).
library;

import 'vero_caller_id_engine.dart';

export 'vero_caller_id_engine.dart';
export 'vero_community_shield.dart';

enum CallRiskLevel { safe, caution, critical }

class CallGuardResult {
  const CallGuardResult({
    required this.rawNumber,
    required this.normalizedNumber,
    required this.riskLevel,
    required this.isBlockedOrWarned,
    required this.categoryTitleTr,
    required this.categoryTitleEn,
    required this.detailTr,
    required this.detailEn,
    this.matchedPrefix,
    this.callerIdCategory,
    this.callerIdConfidence = 0.0,
  });

  final String rawNumber;
  final String normalizedNumber;
  final CallRiskLevel riskLevel;
  final bool isBlockedOrWarned;
  final String categoryTitleTr;
  final String categoryTitleEn;
  final String detailTr;
  final String detailEn;
  final String? matchedPrefix;
  final String? callerIdCategory;
  final double callerIdConfidence;

  bool get isSuspicious => isBlockedOrWarned;
  String get warningTitleTr => categoryTitleTr;
}

class VeroCallGuardEngine {
  const VeroCallGuardEngine._();

  /// High-risk foreign prefixes frequently used in CLI spoofing, Wangiri, and WhatsApp/SMS call scams.
  static const Map<String, String> highRiskForeignPrefixes = {
    '+63': 'Filipinler (+63) Sahte İş / Bahis Hattı',
    '+62': 'Endonezya (+62) Oltalama / Sahte Görev Hattı',
    '+234': 'Nijerya (+234) Finansal Dolandırıcılık Hattı',
    '+212': 'Fas (+212) Çağrı Tuzağı (Wangiri)',
    '+966': 'Suudi Arabistan (+966) Şüpheli / Absher Sahte Çağrı Hattı',
    '+971': 'Birleşik Arap Emirlikleri (+971) Sahte Ödül / Yatırım Hattı',
    '+20': 'Mısır (+20) Bakiye / Operatör Dolandırıcılık Hattı',
    '+27': 'Güney Afrika (+27) Wangiri / Finansal Oltalama Hattı',
    '+359': 'Bulgaristan (+359) Yasa Dışı Bahis Çağrı Merkezi',
    '+370': 'Litvanya (+370) Sanal SIM Oltalama Hattı',
    '+375': 'Belarus (+375) Çağrı Tuzağı',
    '+44': 'İngiltere (+44) Sanal Numara / Forex Tuzağı',
    '+91': 'Hindistan (+91) Teknik Destek Oltalaması',
    '+92': 'Pakistan (+92) Sahte Ödül Hattı',
    '+880': 'Bangladeş (+880) Yurt Dışı Spam Hattı',
    '+254': 'Kenya (+254) Çağrı Tuzağı',
  };

  /// Official verified corporate numbers (whitelist) so legitimate banks/couriers are never flagged.
  static const Map<String, String> verifiedCorporateNumbers = {
    '4440000': 'T.C. Ziraat Bankası Resmi Çağrı Merkezi',
    '08502200000': 'T.C. Ziraat Bankası',
    '08507240724': 'Türkiye İş Bankası Resmi Çağrı Merkezi',
    '4440333': 'Garanti BBVA Resmi Çağrı Merkezi',
    '4442525': 'Akbank Resmi Çağrı Merkezi',
    '4440444': 'Yapı Kredi Resmi Çağrı Merkezi',
    '08502220724': 'VakıfBank Resmi Çağrı Merkezi',
    '4449999': 'Yurtiçi Kargo Resmi Çağrı Merkezi',
    '4442552': 'Aras Kargo Resmi Çağrı Merkezi',
    '182': 'MHRS Resmi Randevu Hattı',
  };

  /// Evaluates an incoming or queried phone number 100% offline.
  static CallGuardResult evaluate(String rawInput) => inspectNumber(rawInput);

  /// First queries [VeroCallerIdEngine.lookup]; if flagged as spam, emits
  /// `"🚨 Bu numara spam olarak işaretlendi: [Kategori]"`.
  static CallGuardResult inspectNumber(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const CallGuardResult(
        rawNumber: '',
        normalizedNumber: '',
        riskLevel: CallRiskLevel.safe,
        isBlockedOrWarned: false,
        categoryTitleTr: 'Numara Girilmedi',
        categoryTitleEn: 'No Number Entered',
        detailTr: 'Analiz için bir telefon numarası girin.',
        detailEn: 'Enter a phone number to analyze.',
      );
    }

    var compact = trimmed.replaceAll(RegExp(r'[\s()\-./]'), '');
    if (compact.startsWith('00')) {
      compact = '+${compact.substring(2)}';
    }

    final digitsOnly = compact.replaceAll('+', '');
    for (final entry in verifiedCorporateNumbers.entries) {
      if (digitsOnly == entry.key || digitsOnly.endsWith(entry.key)) {
        return CallGuardResult(
          rawNumber: trimmed,
          normalizedNumber: compact,
          riskLevel: CallRiskLevel.safe,
          isBlockedOrWarned: false,
          callerIdCategory: SpamCallerCategory.clean,
          callerIdConfidence: 0.99,
          categoryTitleTr: 'Doğrulanmış Resmi Kurum (${entry.value})',
          categoryTitleEn: 'Verified Official Institution (${entry.value})',
          detailTr:
              'Bu numara resmi banka/kurum beyaz listesinde kayıtlıdır. Güvenle yanıtlayabilirsiniz.',
          detailEn:
              'This number is registered in the official corporate whitelist.',
        );
      }
    }

    // Detect matched foreign prefix if any
    String? detectedPrefix;
    for (final entry in highRiskForeignPrefixes.entries) {
      if (compact.startsWith(entry.key)) {
        detectedPrefix = entry.key;
        break;
      }
    }

    if (detectedPrefix != null) {
      final desc = highRiskForeignPrefixes[detectedPrefix]!;
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: CallRiskLevel.critical,
        isBlockedOrWarned: true,
        matchedPrefix: detectedPrefix,
        callerIdCategory: SpamCallerCategory.scam,
        callerIdConfidence: 0.95,
        categoryTitleTr: '🚨 $desc',
        categoryTitleEn: '🚨 High-Risk Foreign Call ($detectedPrefix)',
        detailTr: 'Yurt dışı yüksek riskli arama tuzağı: $desc. Açmayın ve geri aramayın!',
        detailEn: 'High-risk international scam call: $desc. Do not answer or call back!',
      );
    }

    // [ADIM 4] First consult Offline Caller ID Engine (`VeroCallerIdEngine.lookup`)
    final callerId = VeroCallerIdEngine.lookup(trimmed);
    if (callerId.isSpam) {
      final cat = callerId.category;
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: cat == SpamCallerCategory.unknown
            ? CallRiskLevel.caution
            : CallRiskLevel.critical,
        isBlockedOrWarned: true,
        matchedPrefix: detectedPrefix,
        callerIdCategory: cat,
        callerIdConfidence: callerId.confidence,
        categoryTitleTr: '🚨 Bu numara spam olarak işaretlendi: $cat',
        categoryTitleEn: '🚨 This number is flagged as spam: $cat',
        detailTr:
            'VERO Offline Caller ID (${SpamCallerCategory.labelTr(cat)}): Güven skoru %${(callerId.confidence * 100).toStringAsFixed(0)}. Geri aramayın ve kişisel bilgi paylaşmayın!',
        detailEn:
            'VERO Offline Caller ID (${SpamCallerCategory.labelEn(cat)}): Confidence ${(callerId.confidence * 100).toStringAsFixed(0)}%. Do not answer or call back!',
      );
    }

    if (callerId.isSuspicious) {
      final cat = callerId.category;
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: CallRiskLevel.caution,
        isBlockedOrWarned: true,
        matchedPrefix: detectedPrefix,
        callerIdCategory: cat,
        callerIdConfidence: callerId.confidence,
        categoryTitleTr: '⚠️ Şüpheli olabilir (${callerId.patternDescription ?? cat})',
        categoryTitleEn: '⚠️ May be suspicious (${callerId.patternDescription ?? cat})',
        detailTr:
            'Şüpheli numara kalıbı algılandı (${callerId.patternDescription ?? cat}). Tanımıyorsanız dikkatli olun.',
        detailEn:
            'Suspicious number pattern detected (${callerId.patternDescription ?? cat}). Exercise caution.',
      );
    }

    return CallGuardResult(
      rawNumber: trimmed,
      normalizedNumber: compact,
      riskLevel: CallRiskLevel.safe,
      isBlockedOrWarned: false,
      callerIdCategory: SpamCallerCategory.clean,
      callerIdConfidence: callerId.confidence,
      categoryTitleTr: 'Standart Yurtiçi Numara (Bilinen Tehdit Yok)',
      categoryTitleEn: 'Standard Domestic Number (No Known Threat)',
      detailTr:
          'VERO Call Guard çevrimdışı veritabanında bu numara için kayıtlı spam/yurt dışı riski görülmedi.',
      detailEn:
          'No foreign or 0850 scam signature found in VERO Call Guard offline database.',
    );
  }
}
