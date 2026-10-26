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
    this.fromCommunityShield = false,
  });

  final String phoneNumber;
  final String normalizedDigits;
  final bool isSpam;
  final String category;
  final double confidence;
  final bool fromCommunityShield;
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
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (bytes.length >= 8) {
        loadFromBytes(bytes);
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

  /// Looks up [phoneNumber] in < 0.1 ms using:
  /// 1. Official Corporate Whitelist
  /// 2. Local Community Shield reported numbers
  /// 3. O(log N) Binary Search over `spam_numbers.bin` (50,000+ 8-byte ULong records)
  /// 4. High-risk prefix & pattern rules (+63, +234, +212, +359, unverified 0850, 0212 9xx)
  static CallerIdResult lookup(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    final digits = normalizePhoneDigits(trimmed);

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

    // 4. High-risk foreign scam prefixes (+63, +62, +234, +212, +359, +370, +375, +880, +254, +91, +92)
    var compact = trimmed.replaceAll(RegExp(r'[\s()\-./]'), '');
    if (compact.startsWith('00')) compact = '+${compact.substring(2)}';
    const scamPrefixes = [
      '+63',
      '+62',
      '+234',
      '+212',
      '+359',
      '+370',
      '+375',
      '+880',
      '+254',
      '+91',
      '+92',
      '+44',
    ];
    for (final p in scamPrefixes) {
      final pDigits = p.substring(1);
      if (compact.startsWith(p) ||
          (!compact.startsWith('+90') &&
              !compact.startsWith('0') &&
              digits.startsWith(pDigits) &&
              digits.length >= 10)) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: true,
          category: SpamCallerCategory.scam,
          confidence: 0.96,
        );
      }
    }

    // 5. Unverified 0850 / 90850 telemarketing & scam ranges
    if (digits.startsWith('90850') || digits.startsWith('850')) {
      final sub = digits.startsWith('90850')
          ? digits.substring(5)
          : digits.substring(3);
      if (sub.startsWith('480') ||
          sub.startsWith('532') ||
          sub.startsWith('302') ||
          sub.startsWith('303') ||
          sub.startsWith('304') ||
          sub.startsWith('305')) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: true,
          category: SpamCallerCategory.telesales,
          confidence: 0.93,
        );
      }
      if (sub.startsWith('901') || sub.startsWith('840')) {
        return CallerIdResult(
          phoneNumber: trimmed,
          normalizedDigits: digits,
          isSpam: true,
          category: SpamCallerCategory.robocall,
          confidence: 0.92,
        );
      }
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: true,
        category: SpamCallerCategory.telesales,
        confidence: 0.88,
      );
    }

    // 6. 0212 9xx / 0216 9xx automated robocall PBX blocks
    if (RegExp(r'^(90|0)?21[26]9\d{6}$').hasMatch(digits)) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: true,
        category: SpamCallerCategory.robocall,
        confidence: 0.91,
      );
    }

    // 7. Unknown foreign numbers outside +90
    if (compact.startsWith('+') && !compact.startsWith('+90')) {
      return CallerIdResult(
        phoneNumber: trimmed,
        normalizedDigits: digits,
        isSpam: true,
        category: SpamCallerCategory.unknown,
        confidence: 0.80,
      );
    }

    return CallerIdResult(
      phoneNumber: trimmed,
      normalizedDigits: digits,
      isSpam: false,
      category: SpamCallerCategory.clean,
      confidence: 0.95,
    );
  }
}
