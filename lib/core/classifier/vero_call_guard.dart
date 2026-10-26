/// VERO CALL GUARD (Spam Arama Kalkanı) — 100% Offline Foreign & 0850 Scam Call Detector.
library;

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
          categoryTitleTr: 'Doğrulanmış Resmi Kurum (${entry.value})',
          categoryTitleEn: 'Verified Official Institution (${entry.value})',
          detailTr:
              'Bu numara resmi banka/kurum beyaz listesinde kayıtlıdır. Güvenle yanıtlayabilirsiniz.',
          detailEn:
              'This number is registered in the official corporate whitelist.',
        );
      }
    }

    // 1. Check high-risk foreign prefixes (+63, +62, etc.)
    for (final entry in highRiskForeignPrefixes.entries) {
      if (compact.startsWith(entry.key)) {
        return CallGuardResult(
          rawNumber: trimmed,
          normalizedNumber: compact,
          riskLevel: CallRiskLevel.critical,
          isBlockedOrWarned: true,
          matchedPrefix: entry.key,
          categoryTitleTr: 'TEHLİKELİ YURT DIŞI SPAM ARAMA: ${entry.value}',
          categoryTitleEn: 'CRITICAL FOREIGN SCAM CALL: ${entry.key}',
          detailTr:
              'VERO Call Guard: ${entry.key} kodlu yurt dışı dolandırıcılık/bahis hattı tespit edildi. Geri aramayın ve açmayın!',
          detailEn:
              'VERO Call Guard: High-risk foreign scam/betting prefix (${entry.key}) detected. Do not answer or call back!',
        );
      }
    }

    // Any other non-Turkish international number (+...)
    if (compact.startsWith('+') && !compact.startsWith('+90')) {
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: CallRiskLevel.caution,
        isBlockedOrWarned: true,
        categoryTitleTr: 'Yurt Dışı Bilinmeyen Numara ($compact)',
        categoryTitleEn: 'Unknown Foreign Number ($compact)',
        detailTr:
            'VERO Call Guard: Türkiye (+90) dışı uluslararası arama tespit edildi. Tanımıyorsanız itibar etmeyin.',
        detailEn:
            'VERO Call Guard: International call outside +90 detected. Proceed with caution.',
      );
    }

    // 2. Check unverified 0850 / +90850 telemarketing & fake ISP/legal lines
    if (compact.startsWith('0850') ||
        compact.startsWith('+90850') ||
        compact.startsWith('90850') ||
        compact.startsWith('850')) {
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: CallRiskLevel.critical,
        isBlockedOrWarned: true,
        categoryTitleTr: 'ŞÜPHELİ 0850 ÇAĞRI MERKEZİ / TELE-PAZARLAMA',
        categoryTitleEn: 'UNVERIFIED 0850 TELEMARKETING / SCAM LINE',
        detailTr:
            'VERO Call Guard: Doğrulanmış banka listesinde yer almayan 0850\'li hat. Sahte internet taahhüdü, bahis veya icra araması olabilir!',
        detailEn:
            'VERO Call Guard: Unverified 0850 number. Potential fake ISP subscription, betting, or legal scam call!',
      );
    }

    // 3. Check 0212 9.. / +902129.. automated robocall blocks
    if (RegExp(r'^(\+?90|0)?21[26]9\d{6}$').hasMatch(compact)) {
      return CallGuardResult(
        rawNumber: trimmed,
        normalizedNumber: compact,
        riskLevel: CallRiskLevel.caution,
        isBlockedOrWarned: true,
        categoryTitleTr: 'Şüpheli Otomatik Arama (Robocall) Bloğu',
        categoryTitleEn: 'Suspicious Automated Robocall Block',
        detailTr:
            'VERO Call Guard: Sanal santral üzerinden toplu arama yapan numara bloğu tespit edildi.',
        detailEn:
            'VERO Call Guard: Virtual PBX bulk robocall number range detected.',
      );
    }

    return CallGuardResult(
      rawNumber: trimmed,
      normalizedNumber: compact,
      riskLevel: CallRiskLevel.safe,
      isBlockedOrWarned: false,
      categoryTitleTr: 'Standart Yurtiçi Numara (Bilinen Tehdit Yok)',
      categoryTitleEn: 'Standard Domestic Number (No Known Threat)',
      detailTr:
          'VERO Call Guard çevrimdışı veritabanında bu numara için kayıtlı spam/yurt dışı riski görülmedi.',
      detailEn:
          'No foreign or 0850 scam signature found in VERO Call Guard offline database.',
    );
  }
}
