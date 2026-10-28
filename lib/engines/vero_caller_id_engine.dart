import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'vero_community_shield.dart';

/// [ADIM 3] OFFLINE CALLER ID — 100% On-Device Binary Search Spam Number Database.
///
/// Format of `assets/spam_db/spam_numbers.bin`:
/// - Packed array of sorted 8-byte unsigned 64-bit integers (`ULong`, little-endian).
/// - Each 64-bit word encodes: `(phoneNumberInt << 2) | (categoryCode & 0x3)`.
/// - Because records are sorted by `phoneNumberInt`, binary search completes in
///   at most 16 comparisons (< 0.05 ms) for 50,000+ entries.
class SpamCallerCategory {
  SpamCallerCategory._();

  static const String robocall = 'SPAM_ROBOCALL';
  static const String scam = 'SPAM_SCAM';
  static const String telesales = 'SPAM_TELESALES';
  static const String unknown = 'SPAM_UNKNOWN';
  static const String clean = 'CLEAN';

  static String fromCode(int code) => switch (code & 0x3) {
        0 => robocall,
        1 => scam,
        2 => telesales,
        _ => unknown,
      };

  static int toCode(String category) => switch (category) {
        robocall => 0,
        scam => 1,
        telesales => 2,
        _ => 3,
      };

  static String labelTr(String category) => switch (category) {
        robocall => 'SPAM_ROBOCALL (Otomatik Arama)',
        scam => 'SPAM_SCAM (Dolandırıcılık)',
        telesales => 'SPAM_TELESALES (Telefon Satışı)',
        unknown => 'SPAM_UNKNOWN (Şüpheli)',
        _ => 'GÜVENLİ NUMARA',
      };

  static String labelEn(String category) => switch (category) {
        robocall => 'SPAM_ROBOCALL (Automated Call)',
        scam => 'SPAM_SCAM (Scam / Fraud)',
        telesales => 'SPAM_TELESALES (Telemarketing)',
        unknown => 'SPAM_UNKNOWN (Suspicious)',
        _ => 'SAFE NUMBER',
      };
}

class CallerIdResult {
  const CallerIdResult({
    required this.phoneNumber,
    required this.normalizedDigits,
    required this.isSpam,
    required this.category,
    required this.confidence,
    this.isSuspicious = false,
    this.isPatternMatch = false,
    this.patternDescription,
    this.fromCommunityShield = false,
  });

  final String phoneNumber;
  final String normalizedDigits;

  /// True ONLY when exact hit in verified blacklist or user's Community Shield.
  final bool isSpam;

  /// True for heuristic/pattern matches (0850, high-risk foreign prefix, PBX block).
  final bool isSuspicious;
  final bool isPatternMatch;
  final String? patternDescription;

  final String category;
  final double confidence;
  final bool fromCommunityShield;

  bool get hasThreat => isSpam || isSuspicious;

  String get uiBadgeTextTr =>
      isSpam ? '🚨 SPAM' : (isSuspicious ? '⚠️ Şüpheli olabilir' : '✅ Güvenli');

  String get uiBadgeTextEn =>
      isSpam ? '🚨 SPAM' : (isSuspicious ? '⚠️ May be suspicious' : '✅ Safe');
}

class VeroCallerIdEngine {
  VeroCallerIdEngine._();

  static const String assetPath = 'assets/spam_db/spam_numbers.bin';

  static ByteData _sortedRecords = _buildDefaultSeedTable();
  static int _recordCount = _sortedRecords.lengthInBytes ~/ 8;
  static bool _assetLoaded = false;

  static int get recordCount => _recordCount;
  static bool get isAssetLoaded => _assetLoaded;

  /// Verified corporate whitelist (banks, MHRS, couriers) that must never be flagged as spam.
  static const Set<String> _verifiedWhitelist = {
    '4440000',
    '908502200000',
    '08502200000',
    '908507240724',
    '08507240724',
    '4440333',
    '4442525',
    '4440444',
    '908502220724',
    '08502220724',
    '4449999',
    '4442552',
    '182',
  };

  /// Loads `assets/spam_db/spam_numbers.bin` (sorted 8-byte ULong records).
  static Future<void> initFromAsset([AssetBundle? bundle]) async {
    try {
      final targetBundle = bundle ?? rootBundle;
      final data = await targetBundle.load(assetPath);
      final rawBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (rawBytes.length >= 8) {
        Uint8List processed;
        try {
          processed = await Isolate.run<Uint8List>(() {
            final alignedLen = (rawBytes.length ~/ 8) * 8;
            return Uint8List.fromList(rawBytes.sublist(0, alignedLen));
          });
        } catch (_) {
          final alignedLen = (rawBytes.length ~/ 8) * 8;
          processed = Uint8List.fromList(rawBytes.sublist(0, alignedLen));
        }
        _sortedRecords = ByteData.sublistView(processed);
        _recordCount = processed.lengthInBytes ~/ 8;
        _assetLoaded = true;
      }
    } catch (_) {
      // Keep default seeded table if asset bundle is unavailable in unit test.
    }
  }

  /// Loads sorted 8-byte ULong binary buffer directly into memory.
  static void loadFromBytes(Uint8List bytes) {
    final alignedLen = (bytes.length ~/ 8) * 8;
    final copy = Uint8List.fromList(bytes.sublist(0, alignedLen));
    _sortedRecords = ByteData.sublistView(copy);
    _recordCount = alignedLen ~/ 8;
  }

  static ByteData _buildDefaultSeedTable() {
    final seeds = <(int, int)>[
      (908504800000, 2), // SPAM_TELESALES
      (908504809988, 2), // SPAM_TELESALES
      (908505320000, 1), // SPAM_SCAM
      (908509010000, 0), // SPAM_ROBOCALL
      (902129010000, 0), // SPAM_ROBOCALL
      (902129220000, 0), // SPAM_ROBOCALL
      (902169010000, 0), // SPAM_ROBOCALL
      (639170001122, 1), // SPAM_SCAM (+63)
      (628120001122, 1), // SPAM_SCAM (+62)
      (2348030001122, 1), // SPAM_SCAM (+234)
      (212600001122, 1), // SPAM_SCAM (+212)
      (359880001122, 1), // SPAM_SCAM (+359)
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final bd = ByteData(seeds.length * 8);
    for (var i = 0; i < seeds.length; i++) {
      final encoded = (seeds[i].$1 << 2) | (seeds[i].$2 & 0x3);
      bd.setUint64(i * 8, encoded, Endian.little);
    }
    return bd;
  }

  /// Normalizes a phone number string into canonical unsigned integer digits.
  static String normalizePhoneDigits(String rawPhone) =>
      VeroCommunityShield.normalizeDigits(rawPhone);

  /// Performs O(log N) binary search (< 0.1 ms) over the sorted 8-byte ULong buffer.
  static int? _binarySearchCategoryCode(int targetPhoneInt) {
    var low = 0;
    var high = _recordCount - 1;
    while (low <= high) {
      final mid = (low + high) >>> 1;
      final packed = _sortedRecords.getUint64(mid * 8, Endian.little);
      final phoneVal = packed >>> 2;
      if (phoneVal == targetPhoneInt) {
        return packed & 0x3;
      } else if (phoneVal < targetPhoneInt) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  /// Pre-compiled FAZA 7 Regex Pattern Engine (<0.1ms execution).
  /// 8 Dedicated high-risk & localized rules:
  static final RegExp _regex0850 = RegExp(r'^(?:90|0)?850[2-9]\d{6}$');
  static final RegExp _regexNigeria = RegExp(r'^(?:\+?234|00234)\d{10}$');
  static final RegExp _regexPhilippines = RegExp(r'^(?:\+?63|0063)\d{10}$');
  static final RegExp _regexMorocco = RegExp(r'^(?:\+?212|00212)[5-7]\d{8}$');
  static final RegExp _regexBulgaria = RegExp(r'^(?:\+?359|00359)\d{9}$');
  static final RegExp _regexUkMobile = RegExp(r'^(?:\+?44|0044)7\d{9}$');
  static final RegExp _regexUsTollFree = RegExp(r'^(?:\+?1|001)[89]\d{9}$');
  static final RegExp _regexTrMobile = RegExp(r'^(?:\+?90|0)?5\d{9}$');

  static const List<String> regexPatternRules = [
    r'0850[2-9]\d{6} → ⚠️ 0850 Yönlendirme',
    r'\+234\d{10} → ⚠️ Nijerya',
    r'\+63\d{10} → ⚠️ Filipinler',
    r'\+212[5-7]\d{8} → ⚠️ Fas',
    r'\+359\d{9} → ⚠️ Bulgaristan',
    r'\+447[0-9]{9} → ⚠️ İngiltere Mobil',
    r'\+1[89]\d{9} → ⚠️ ABD/Canada Toll-Free',
    r'\+905[0-9]{9} → ⚠️ Türkiye Mobil (bilinmeyen)',
  ];

  /// Looks up [phoneNumber] in < 0.1 ms using:
  /// 1. Official Corporate Whitelist
  /// 2. Local Community Shield reported numbers
  /// 3. O(log N) Binary Search over `spam_numbers.bin` (60,000+ 8-byte ULong records)
  /// 4. Prefix match layer (+63, +234, +212, +359, unverified 0850)
  /// 5. FAZA 7 Pre-compiled 8 Regex Pattern Rules
  /// 6. Clean / Unknown default
  static CallerIdResult lookup(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    final digits = normalizePhoneDigits(trimmed);
    var compact = trimmed.replaceAll(RegExp(r'[\s()\-./]'), '');
    if (compact.startsWith('00')) compact = '+${compact.substring(2)}';

    if (digits.isEmpty) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: '',
        isSpam: false,
        category: SpamCallerCategory.clean,
        confidence: 0.0,
      );
    }

    // 1. Check verified corporate whitelist
    for (final safe in _verifiedWhitelist) {
      if (digits == safe || digits.endsWith(safe)) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: false,
          category: SpamCallerCategory.clean,
          confidence: 0.99,
        );
      }
    }

    // 2. Check user-reported numbers in VeroCommunityShield
    final reported = VeroCommunityShield.lookupReported(trimmed);
    if (reported != null) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: true,
        category: reported.category,
        confidence: 0.99,
        fromCommunityShield: true,
      );
    }

    // 3. Binary search in sorted 8-byte ULong database (`spam_numbers.bin`)
    final phoneInt = int.tryParse(digits);
    if (phoneInt != null && _recordCount > 0) {
      final exactCode = _binarySearchCategoryCode(phoneInt);
      if (exactCode != null) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: true,
          category: SpamCallerCategory.fromCode(exactCode),
          confidence: 0.98,
        );
      }
    }

    // 4. Pre-compiled 8 Regex Pattern Rules & High-Risk Country Rules (FAZA 7)
    // Rule 2: \+234\d{10} → "⚠️ Nijerya"
    if (_regexNigeria.hasMatch(compact) || (digits.startsWith('234') && digits.length >= 10)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ Nijerya',
        category: SpamCallerCategory.scam,
        confidence: 0.85,
      );
    }

    // Rule 3: \+63\d{10} → "⚠️ Filipinler"
    if (_regexPhilippines.hasMatch(compact) || (digits.startsWith('63') && digits.length >= 10)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ Filipinler',
        category: SpamCallerCategory.scam,
        confidence: 0.85,
      );
    }

    // Rule 4: \+212[5-7]\d{8} → "⚠️ Fas"
    if (_regexMorocco.hasMatch(compact) || (digits.startsWith('212') && digits.length >= 10)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ Fas',
        category: SpamCallerCategory.scam,
        confidence: 0.85,
      );
    }

    // Rule 5: \+359\d{9} → "⚠️ Bulgaristan"
    if (_regexBulgaria.hasMatch(compact) || (digits.startsWith('359') && digits.length >= 10)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ Bulgaristan',
        category: SpamCallerCategory.scam,
        confidence: 0.85,
      );
    }

    // Rule 6: \+447[0-9]{9} → "⚠️ İngiltere Mobil"
    if (_regexUkMobile.hasMatch(compact) || (digits.startsWith('447') && digits.length >= 11)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ İngiltere Mobil',
        category: SpamCallerCategory.scam,
        confidence: 0.80,
      );
    }

    // Rule 7: \+1[89]\d{9} → "⚠️ ABD/Canada Toll-Free"
    if (_regexUsTollFree.hasMatch(compact) || ((digits.startsWith('18') || digits.startsWith('19')) && digits.length == 11)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ ABD/Canada Toll-Free',
        category: SpamCallerCategory.robocall,
        confidence: 0.80,
      );
    }

    // Other high-risk foreign prefixes
    const otherScamPrefixes = [
      '+62',
      '+370',
      '+375',
      '+880',
      '+254',
      '+91',
      '+92',
      '+44',
    ];
    for (final p in otherScamPrefixes) {
      final pDigits = p.substring(1);
      if (compact.startsWith(p) ||
          (!compact.startsWith('+90') &&
              !compact.startsWith('0') &&
              digits.startsWith(pDigits) &&
              digits.length >= 10)) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: false,
          isSuspicious: true,
          isPatternMatch: true,
          patternDescription: 'Yüksek riskli yurt dışı ön eki ($p)',
          category: SpamCallerCategory.scam,
          confidence: 0.85,
        );
      }
    }

    // 0850 sub-patterns & Rule 1: 0850[2-9]\d{6} → "⚠️ 0850 Yönlendirme"
    if (_regex0850.hasMatch(compact) ||
        digits.startsWith('90850') ||
        digits.startsWith('850') ||
        compact.startsWith('0850')) {
      final sub = digits.startsWith('90850')
          ? digits.substring(5)
          : (digits.startsWith('850') ? digits.substring(3) : digits);
      if (sub.startsWith('532') || sub.startsWith('549')) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: false,
          isSuspicious: true,
          isPatternMatch: true,
          patternDescription: '0850 şüpheli sahte GSM bloğu',
          category: SpamCallerCategory.scam,
          confidence: 0.85,
        );
      }
      if (sub.startsWith('480') ||
          sub.startsWith('302') ||
          sub.startsWith('303') ||
          sub.startsWith('304') ||
          sub.startsWith('305')) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: false,
          isSuspicious: true,
          isPatternMatch: true,
          patternDescription: '0850 tele-pazarlama şablonu',
          category: SpamCallerCategory.telesales,
          confidence: 0.80,
        );
      }
      if (sub.startsWith('901') || sub.startsWith('840')) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: false,
          isSuspicious: true,
          isPatternMatch: true,
          patternDescription: '0850 otomatik robocall şablonu',
          category: SpamCallerCategory.robocall,
          confidence: 0.80,
        );
      }
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: '⚠️ 0850 Yönlendirme',
        category: SpamCallerCategory.telesales,
        confidence: 0.80,
      );
    }

    // Rule 8: \+905[0-9]{9} → "⚠️ Türkiye Mobil (bilinmeyen)"
    if (_regexTrMobile.hasMatch(compact) || _regexTrMobile.hasMatch(digits)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: false,
        isPatternMatch: true,
        patternDescription: '⚠️ Türkiye Mobil (bilinmeyen)',
        category: SpamCallerCategory.clean,
        confidence: 0.60,
      );
    }

    // 6. 0212 9xx / 0216 9xx automated robocall PBX blocks
    if (RegExp(r'^(90|0)?21[26]9\d{6}$').hasMatch(digits)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: 'Otomatik santral PBX şablonu',
        category: SpamCallerCategory.robocall,
        confidence: 0.80,
      );
    }

    // 7. Unknown foreign numbers outside +90
    if (compact.startsWith('+') && !compact.startsWith('+90')) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: false,
        isSuspicious: true,
        isPatternMatch: true,
        patternDescription: 'Bilinmeyen yurt dışı arama şablonu',
        category: SpamCallerCategory.unknown,
        confidence: 0.70,
      );
    }

    // 8. Default: Clean
    return CallerIdResult(
      phoneNumber: trimmed,
      normalizedDigits: digits,
      isSpam: false,
      isSuspicious: false,
      patternDescription: '✅ Bilinmeyen (temiz)',
      category: SpamCallerCategory.clean,
      confidence: 0.95,
    );
  }
}
