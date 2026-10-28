import 'package:flutter/material.dart';

import 'vero_call_guard_engine.dart';

/// CALLER NAME ID — 100% Offline Local Caller Name Identifier.
///
/// Matches incoming/history phone numbers in priority order:
/// 1. Device Contacts (READ_CONTACTS) -> "Ahmet Yılmaz (Rehber)" [Yeşil]
/// 2. Spam Database (Exact verified hit) -> "🚨 SPAM: [Kategori]" [Kırmızı]
/// 3. Community Shield (User/crowdsourced report) -> "Topluluk: [Kategori] (Bildirildi)" [Turuncu]
/// 4. Heuristic Pattern (0850, high-risk foreign) -> "⚠️ Şüpheli olabilir: [Açıklama]" [Turuncu/Sarı]
/// 5. Fallback -> "Bilinmeyen Numara" [Sarı]
enum CallerNameType {
  contact,
  spam,
  community,
  unknown,
}

class CallerNameResult {
  const CallerNameResult({
    required this.phoneNumber,
    required this.displayName,
    required this.type,
    required this.color,
    this.shouldVibrate = false,
    this.spamCategory,
    this.confidence = 1.0,
    this.reportCount = 0,
  });

  final String phoneNumber;
  final String displayName;
  final CallerNameType type;
  final Color color;
  final bool shouldVibrate;
  final String? spamCategory;
  final double confidence;
  final int reportCount;

  bool get isContact => type == CallerNameType.contact;
  bool get isSpam => type == CallerNameType.spam;
  bool get isCommunity => type == CallerNameType.community;
  bool get isUnknown => type == CallerNameType.unknown;
  bool get vibratePhone => shouldVibrate;
}

class VeroCallerNameEngine {
  VeroCallerNameEngine._();
  static final VeroCallerNameEngine instance = VeroCallerNameEngine._();
  factory VeroCallerNameEngine() => instance;

  static const Color colorContact = Color(0xFF00E676);   // Yeşil (#00E676)
  static const Color colorSpam = Color(0xFFFF1744);      // Kırmızı (#FF1744)
  static const Color colorCommunity = Color(0xFFFF9100); // Turuncu (#FF9100)
  static const Color colorUnknown = Color(0xFFFFD600);   // Sarı (#FFD600)

  /// Local address book index (Normalized digits -> Name).
  static final Map<String, String> _localContacts = {};

  /// Asynchronously / bulk sync contacts into the local indexed map.
  static Future<int> syncContacts(List<Map<String, String>> contacts) async {
    int count = 0;
    for (final contact in contacts) {
      final phone = contact['phone'] ?? contact['number'] ?? '';
      final name = contact['name'] ?? '';
      if (phone.isNotEmpty && name.isNotEmpty) {
        final digits = VeroCommunityShield.normalizeDigits(phone);
        if (digits.isNotEmpty) {
          _localContacts[digits] = name.trim();
          count++;
        }
      }
    }
    return count;
  }

  /// Registers a single contact into the local address book cache.
  static void registerContact(String phoneNumber, String name) {
    final digits = VeroCommunityShield.normalizeDigits(phoneNumber);
    if (digits.isNotEmpty) {
      _localContacts[digits] = name.trim();
    }
  }

  /// Removes a contact from local address book cache.
  static void removeContact(String phoneNumber) {
    final digits = VeroCommunityShield.normalizeDigits(phoneNumber);
    _localContacts.remove(digits);
  }

  /// Clears local contacts cache.
  static void resetContacts() {
    _localContacts.clear();
  }

  /// Total cached contacts count.
  static int get contactsCount => _localContacts.length;

  CallerNameResult identifyNumber(String phoneNumber,
      {Map<String, String>? localContacts}) {
    if (localContacts != null) {
      for (final e in localContacts.entries) {
        registerContact(e.key, e.value);
      }
    }
    return identify(phoneNumber);
  }

  /// Identifies caller name and classification 100% offline.
  /// Execution time is <1ms via hashmap and binary lookup.
  static CallerNameResult identify(String phoneNumber) {
    final digits = VeroCommunityShield.normalizeDigits(phoneNumber);
    if (digits.isEmpty) {
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: 'Bilinmeyen Numara',
        type: CallerNameType.unknown,
        color: colorUnknown,
      );
    }

    // 1. Check Rehber (Local device contacts) -> "Ahmet Yılmaz (Rehber)" [Yeşil]
    for (final entry in _localContacts.entries) {
      if (digits == entry.key ||
          digits.endsWith(entry.key) ||
          entry.key.endsWith(digits)) {
        return CallerNameResult(
          phoneNumber: phoneNumber,
          displayName: '${entry.value} (Rehber)',
          type: CallerNameType.contact,
          color: colorContact,
          shouldVibrate: false,
          confidence: 1.0,
        );
      }
    }

    // 2. Check Exact Verified Spam Database Match -> "🚨 SPAM: [Kategori]" [Kırmızı]
    final spamCheck = VeroCallerIdEngine.lookup(phoneNumber);
    if (spamCheck.isSpam && !spamCheck.fromCommunityShield) {
      final friendly = SpamCallerCategory.friendlyTitleTr(spamCheck.category);
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: friendly,
        type: CallerNameType.spam,
        color: colorSpam,
        shouldVibrate: true,
        spamCategory: friendly,
        confidence: spamCheck.confidence,
      );
    }

    // 3. Check Community Shield -> "Topluluk: [Kategori] (Bildirildi)" [Turuncu]
    final communityReport = VeroCommunityShield.lookupReported(phoneNumber);
    if (communityReport != null) {
      final friendly = SpamCallerCategory.friendlyTitleTr(communityReport.category);
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: 'Topluluk: $friendly (Bildirildi)',
        type: CallerNameType.community,
        color: colorCommunity,
        shouldVibrate: false,
        spamCategory: friendly,
        confidence: 0.90,
        reportCount: 1,
      );
    }

    // 4. Check Call Guard & Heuristic Patterns (0850, high-risk foreign prefixes)
    final callGuard = VeroCallGuardEngine.evaluate(phoneNumber);
    if (callGuard.isBlockedOrWarned) {
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: callGuard.categoryTitleTr.startsWith('🚨') || callGuard.categoryTitleTr.startsWith('⚠️')
            ? callGuard.categoryTitleTr
            : '⚠️ Şüpheli: ${callGuard.categoryTitleTr}',
        type: CallerNameType.spam,
        color: colorSpam,
        shouldVibrate: true,
        spamCategory: callGuard.categoryTitleTr,
        confidence: 0.95,
      );
    }

    if (spamCheck.isSuspicious) {
      final desc = spamCheck.patternDescription ?? SpamCallerCategory.friendlyTitleTr(spamCheck.category);
      final display = desc.startsWith('⚠️') || desc.startsWith('🚨') ? desc : '⚠️ $desc';
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: display,
        type: CallerNameType.spam,
        color: colorCommunity,
        shouldVibrate: false,
        spamCategory: desc,
        confidence: spamCheck.confidence,
      );
    }

    // 5. Hiçbiri -> "Bilinmeyen Numara" [Sarı]
    return CallerNameResult(
      phoneNumber: phoneNumber,
      displayName: 'Bilinmeyen Numara',
      type: CallerNameType.unknown,
      color: colorUnknown,
      shouldVibrate: false,
      confidence: 0.5,
    );
  }
}
