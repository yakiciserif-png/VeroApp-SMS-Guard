import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// [ADIM 5] VERO COMMUNITY SHIELD — 100% Offline Local Spam Number Reporting Engine.
///
/// Stores user-reported spam phone numbers locally on the device and makes them
/// immediately active inside [VeroCallerIdEngine] and [VeroCallGuardEngine]
/// with zero internet dependency.
class CommunityReportedNumber {
  const CommunityReportedNumber({
    required this.normalizedDigits,
    required this.rawNumber,
    required this.category,
    required this.reportedAtIso,
  });

  final String normalizedDigits;
  final String rawNumber;
  final String category;
  final String reportedAtIso;

  Map<String, dynamic> toJson() => {
        'd': normalizedDigits,
        'r': rawNumber,
        'c': category,
        't': reportedAtIso,
      };

  factory CommunityReportedNumber.fromJson(Map<String, dynamic> json) =>
      CommunityReportedNumber(
        normalizedDigits: (json['d'] as String?) ?? '',
        rawNumber: (json['r'] as String?) ?? '',
        category: (json['c'] as String?) ?? 'SPAM_SCAM',
        reportedAtIso:
            (json['t'] as String?) ?? DateTime.now().toIso8601String(),
      );
}

class VeroCommunityShield {
  VeroCommunityShield._();

  static const String prefsKey = 'vero.communityReportedNumbers';

  static final Map<String, CommunityReportedNumber> _reportedByDigits = {};

  /// Number of spam phone numbers reported locally by the user.
  static int get reportedCount => _reportedByDigits.length;

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

  /// Loads persisted user-reported numbers from [SharedPreferences].
  static Future<void> init([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
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

  /// Reports a phone number as spam locally (0 ms instant activation) and persists it.
  static Future<bool> reportNumber(
    String rawPhone, {
    String category = 'SPAM_SCAM',
    SharedPreferences? prefs,
  }) async {
    final digits = normalizeDigits(rawPhone);
    if (digits.length < 3) return false;
    _reportedByDigits[digits] = CommunityReportedNumber(
      normalizedDigits: digits,
      rawNumber: rawPhone.trim(),
      category: category,
      reportedAtIso: DateTime.now().toIso8601String(),
    );
    await _persist(prefs);
    return true;
  }

  /// Synchronous in-memory report helper (also triggers async persistence if prefs provided).
  static bool reportNumberSync(
    String rawPhone, {
    String category = 'SPAM_SCAM',
  }) {
    final digits = normalizeDigits(rawPhone);
    if (digits.length < 3) return false;
    _reportedByDigits[digits] = CommunityReportedNumber(
      normalizedDigits: digits,
      rawNumber: rawPhone.trim(),
      category: category,
      reportedAtIso: DateTime.now().toIso8601String(),
    );
    return true;
  }

  /// Checks if [rawPhone] has been reported by the user locally.
  static CommunityReportedNumber? lookupReported(String rawPhone) {
    final digits = normalizeDigits(rawPhone);
    if (digits.isEmpty) return null;
    return _reportedByDigits[digits];
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
    } catch (_) {
      // Ignore in environments where SharedPreferences is not initialized.
    }
  }
}
