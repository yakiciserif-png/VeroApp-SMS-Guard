import 'package:flutter/material.dart';

import 'vero_call_guard_engine.dart';

/// [ADIM 1] CALLER NAME ID — 100% Offline Local Caller Name Identifier.
///
/// Matches phone numbers against:
/// 1. Local Phone Contacts (READ_CONTACTS) / Local Address Book
/// 2. Offline Spam Database (`spam_numbers.bin` + Community Shield)
/// 3. Fallback: Bilinmeyen Numara
enum CallerNameType {
  contact,
  spam,
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
  });

  final String phoneNumber;
  final String displayName;
  final CallerNameType type;
  final Color color;
  final bool shouldVibrate;
  final String? spamCategory;
  final double confidence;

  bool get isContact => type == CallerNameType.contact;
  bool get isSpam => type == CallerNameType.spam;
  bool get isUnknown => type == CallerNameType.unknown;
  bool get vibratePhone => shouldVibrate;
}

class VeroCallerNameEngine {
  VeroCallerNameEngine._();
  static final VeroCallerNameEngine instance = VeroCallerNameEngine._();
  factory VeroCallerNameEngine() => instance;

  CallerNameResult identifyNumber(String phoneNumber, {Map<String, String>? localContacts}) {
    if (localContacts != null) {
      for (final e in localContacts.entries) {
        registerContact(e.key, e.value);
      }
    }
    return identify(phoneNumber);
  }

  static const Color colorContact = Color(0xFF00FF88); // Yeşil (#00FF88)
  static const Color colorSpam = Color(0xFFFF1744);    // Kırmızı (#FF1744)
  static const Color colorUnknown = Color(0xFFFFD600); // Sarı (#FFD600)

  /// Local address book cache (e.g. from local device contacts).
  static final Map<String, String> _localContacts = {
    '905321112233': 'Ahmet Yılmaz',
    '905332223344': 'Ayşe Kaya',
    '905423334455': 'Mehmet Demir',
    '905554445566': 'Zeynep Çelik',
    '905051234567': 'Ali Vural',
  };

  /// Registers a contact in the local address book cache.
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

  /// Clears local contacts (except defaults if reset requested).
  static void resetContacts() {
    _localContacts.clear();
    _localContacts.addAll({
      '905321112233': 'Ahmet Yılmaz',
      '905332223344': 'Ayşe Kaya',
      '905423334455': 'Mehmet Demir',
      '905554445566': 'Zeynep Çelik',
      '905051234567': 'Ali Vural',
    });
  }

  /// Identifies caller name and classification 100% offline.
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

    // 1. Check local contacts
    for (final entry in _localContacts.entries) {
      if (digits == entry.key || digits.endsWith(entry.key) || entry.key.endsWith(digits)) {
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

    // 2. Check call guard (e.g. high-risk foreign prefixes like +966, +971, +20, +234, +27)
    final callGuard = VeroCallGuardEngine.evaluate(phoneNumber);
    if (callGuard.isBlockedOrWarned) {
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: '🚨 SPAM - ${callGuard.categoryTitleTr}',
        type: CallerNameType.spam,
        color: colorSpam,
        shouldVibrate: true,
        spamCategory: callGuard.categoryTitleTr,
        confidence: 0.95,
      );
    }

    // 3. Check spam database & community shield
    final spamCheck = VeroCallerIdEngine.lookup(phoneNumber);
    if (spamCheck.isSpam) {
      return CallerNameResult(
        phoneNumber: phoneNumber,
        displayName: '🚨 SPAM - ${spamCheck.category}',
        type: CallerNameType.spam,
        color: colorSpam,
        shouldVibrate: true,
        spamCategory: spamCheck.category,
        confidence: spamCheck.confidence,
      );
    }

    // 3. Fallback: Unknown
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
