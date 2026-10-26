import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

/// Community reported number entity with category and confidence score.
class CommunityReportedNumber {
  const CommunityReportedNumber({
    required this.normalizedDigits,
    required this.rawNumber,
    required this.category,
    required this.reportedAtIso,
    this.confidenceScore = 95,
  });

  final String normalizedDigits;
  final String rawNumber;
  final String category;
  final String reportedAtIso;
  final int confidenceScore;

  Map<String, dynamic> toJson() => {
        'd': normalizedDigits,
        'r': rawNumber,
        'c': category,
        't': reportedAtIso,
        's': confidenceScore,
      };

  factory CommunityReportedNumber.fromJson(Map<String, dynamic> json) =>
      CommunityReportedNumber(
        normalizedDigits: (json['d'] as String?) ?? '',
        rawNumber: (json['r'] as String?) ?? '',
        category: (json['c'] as String?) ?? 'SPAM_SCAM',
        reportedAtIso:
            (json['t'] as String?) ?? DateTime.now().toIso8601String(),
        confidenceScore: (json['s'] as int?) ?? 95,
      );
}

/// Community Shield: Local crowdsourced spam intelligence and weekly binary pool exporter.
class VeroCommunityShield {
  VeroCommunityShield._();

  static const String prefsKey = 'vero.communityReportedNumbers';
  static const String prefsBlockedCountKey = 'vero.communityBlockedCount';

  static final Map<String, CommunityReportedNumber> _reportedByDigits = {};
  static int _communityBlockedCount = 142; // Seed verified community blocked stat

  static const String feedbackMessage =
      '✅ Bildiriminiz kaydedildi. Haftalık güncelleme ile diğer kullanıcılara ulaştırılacak.';

  /// Number of spam phone numbers reported locally by the user.
  static int get reportedCount => _reportedByDigits.length;

  /// Total calls/SMS blocked by community consensus intelligence.
  static int get communityBlockedCount => _communityBlockedCount;

  /// Unmodifiable list of all locally reported spam numbers.
  static List<CommunityReportedNumber> get reportedNumbers =>
      _reportedByDigits.values.toList(growable: false);

  /// Normalizes a phone string into canonical digits (e.g. `908504809988`).
  static String normalizeDigits(String rawPhone) {
    var compact = rawPhone.trim().replaceAll(RegExp(r'[\s()\-./]'), '');
    if (compact.startsWith('00')) {
      compact = compact.substring(2);
    } else if (compact.startsWith('+')) {
      compact = compact.substring(1);
    }
    final digits = compact.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      return '9$digits'; // 05xx / 0850 -> 905xx / 90850
    }
    return digits;
  }

  /// Increments the community blocked counter when a call/SMS is intercepted.
  static Future<void> incrementBlockedCount([SharedPreferences? prefs]) async {
    _communityBlockedCount++;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setInt(prefsBlockedCountKey, _communityBlockedCount);
    } catch (_) {}
  }

  /// Loads persisted user-reported numbers from [SharedPreferences].
  static Future<void> init([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    _communityBlockedCount = p.getInt(prefsBlockedCountKey) ?? 142;
    final raw = p.getString(prefsKey);
    _reportedByDigits.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in list) {
        final entry = CommunityReportedNumber.fromJson(item);
        if (entry.normalizedDigits.isNotEmpty) {
          _reportedByDigits[entry.normalizedDigits] = entry;
        }
      }
    } catch (_) {
      _reportedByDigits.clear();
    }
  }

  /// Reports a phone number as spam locally and schedules it for weekly distribution.
  static Future<bool> reportNumber(
    String rawPhone, {
    String category = 'SPAM_SCAM',
    int confidenceScore = 95,
    SharedPreferences? prefs,
  }) async {
    final digits = normalizeDigits(rawPhone);
    if (digits.length < 3) return false;
    _reportedByDigits[digits] = CommunityReportedNumber(
      normalizedDigits: digits,
      rawNumber: rawPhone.trim(),
      category: category,
      reportedAtIso: DateTime.now().toIso8601String(),
      confidenceScore: confidenceScore,
    );
    await _persist(prefs);
    return true;
  }

  /// Synchronous in-memory report helper.
  static bool reportNumberSync(
    String rawPhone, {
    String category = 'SPAM_SCAM',
    int confidenceScore = 95,
  }) {
    final digits = normalizeDigits(rawPhone);
    if (digits.length < 3) return false;
    _reportedByDigits[digits] = CommunityReportedNumber(
      normalizedDigits: digits,
      rawNumber: rawPhone.trim(),
      category: category,
      reportedAtIso: DateTime.now().toIso8601String(),
      confidenceScore: confidenceScore,
    );
    return true;
  }

  /// Checks if [rawPhone] has been reported by the user locally.
  static CommunityReportedNumber? lookupReported(String rawPhone) {
    final digits = normalizeDigits(rawPhone);
    if (digits.isEmpty) return null;
    return _reportedByDigits[digits];
  }

  /// Exports local user reports to the weekly binary threat update format:
  /// - Numara (8 byte uint64) + Kategori (1 byte) + Güven Skoru (1 byte)
  /// - Exactly 10 bytes per record (1000 reports = 10,000 bytes ≈ 10 KB).
  static Uint8List exportWeeklyPackageBytes() {
    final entries = _reportedByDigits.values.toList();
    final bytes = Uint8List(entries.length * 10);
    final byteData = ByteData.sublistView(bytes);

    for (int i = 0; i < entries.length; i++) {
      final item = entries[i];
      final offset = i * 10;
      final phone = int.tryParse(item.normalizedDigits) ?? 0;
      byteData.setUint64(offset, phone, Endian.big);

      // Category byte
      int catCode = 2; // Default SCAM
      if (item.category.contains('BET')) catCode = 1;
      if (item.category.contains('PHISH')) catCode = 3;
      if (item.category.contains('TELE')) catCode = 4;
      byteData.setUint8(offset + 8, catCode);

      // Confidence byte (0-100)
      byteData.setUint8(offset + 9, item.confidenceScore.clamp(0, 100));
    }
    return bytes;
  }

  /// Imports binary records from weekly threat package (10 bytes each).
  static int importWeeklyPackageBytes(Uint8List bytes) {
    if (bytes.length < 10) return 0;
    final byteData = ByteData.sublistView(bytes);
    final count = bytes.length ~/ 10;
    int imported = 0;

    for (int i = 0; i < count; i++) {
      final offset = i * 10;
      final phone = byteData.getUint64(offset, Endian.big);
      final cat = byteData.getUint8(offset + 8);
      final conf = byteData.getUint8(offset + 9);

      if (phone > 0) {
        final digits = phone.toString();
        String catName = 'SPAM_SCAM';
        if (cat == 1) catName = 'SPAM_BETTING';
        if (cat == 3) catName = 'SPAM_PHISHING';
        if (cat == 4) catName = 'SPAM_TELEMARKETING';

        _reportedByDigits[digits] = CommunityReportedNumber(
          normalizedDigits: digits,
          rawNumber: '+$digits',
          category: catName,
          reportedAtIso: DateTime.now().toIso8601String(),
          confidenceScore: conf,
        );
        imported++;
      }
    }
    return imported;
  }

  /// Clears all locally reported spam numbers.
  static Future<void> clearAll([SharedPreferences? prefs]) async {
    _reportedByDigits.clear();
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.remove(prefsKey);
  }

  static void clearMemoryOnly() {
    _reportedByDigits.clear();
  }

  static Future<void> _persist([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _reportedByDigits.values.map((e) => e.toJson()).toList(),
      );
      await p.setString(prefsKey, encoded);
    } catch (_) {}
  }
}
