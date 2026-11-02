import 'dart:async';
import 'package:flutter/services.dart';

import '../engines/vero_caller_id_engine.dart';
import '../engines/vero_community_shield.dart';
import '../engines/vero_intent_engine.dart';
import '../engines/vero_link_scanner.dart';

/// SMS Message Entity representing incoming/outgoing messages in VeroApp.
class VeroSmsMessage {
  const VeroSmsMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.body,
    required this.timestamp,
    required this.isSpam,
    this.category = 'GENEL',
    this.isOutgoing = false,
  });

  final String id;
  final String sender;
  final String recipient;
  final String body;
  final DateTime timestamp;
  final bool isSpam;
  final String category;
  final bool isOutgoing;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender': sender,
        'recipient': recipient,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isSpam': isSpam,
        'category': category,
        'isOutgoing': isOutgoing,
      };
}

/// Service managing Default SMS App functionality, 6D spam analysis, and dispatch.
class VeroSmsService {
  VeroSmsService._();
  static final VeroSmsService instance = VeroSmsService._();
  factory VeroSmsService() => instance;

  static const MethodChannel _channel =
      MethodChannel('com.veroapp.smsguard/telecom');

  static final List<VeroSmsMessage> _inboxMessages = [];
  static final List<VeroSmsMessage> _spamMessages = [];

  static List<VeroSmsMessage> get inbox =>
      List.unmodifiable(_inboxMessages);
  static List<VeroSmsMessage> get spamInbox =>
      List.unmodifiable(_spamMessages);

  /// Checks if VeroApp is currently the Android system Default SMS app.
  static Future<bool> isDefaultSmsApp() async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('isDefaultSmsApp');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests the user to set VeroApp as Default SMS App (RoleManager.ROLE_SMS).
  static Future<bool> requestDefaultSmsRole() async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('requestDefaultSmsRole');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Processes an incoming SMS via the 6D on-device semantic intent engine.
  ///
  /// Routes clean messages into Smart Inbox and spam/scam into Spam Inbox.
  static VeroSmsMessage processIncomingSms({
    required String sender,
    required String body,
    String? id,
  }) {
    final msgId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final intent = VeroIntentEngine.instance.analyze(body);
    final senderLookup = VeroCallerIdEngine.lookup(sender);
    final communityLookup = VeroCommunityShield.lookupReported(sender);

    final links = VeroLinkScanner.instance.scanText(body);
    final hasThreatLink = links.any((l) => l.isThreat);
    final lower = body.toLowerCase();
    final hasBettingKeyword = lower.contains('deneme bonusu') ||
        lower.contains('kumar') ||
        lower.contains('bahis') ||
        lower.contains('casino') ||
        lower.contains('slot');

    final isSpam = intent.isFraud ||
        senderLookup.isSpam ||
        communityLookup != null ||
        hasThreatLink ||
        hasBettingKeyword ||
        intent.confidence > 0.65;

    final category = intent.type?.titleTr ??
        (senderLookup.isSpam ? senderLookup.category : 'GENEL');

    final msg = VeroSmsMessage(
      id: msgId,
      sender: sender,
      recipient: 'me',
      body: body,
      timestamp: DateTime.now(),
      isSpam: isSpam,
      category: category,
      isOutgoing: false,
    );

    if (isSpam) {
      _spamMessages.insert(0, msg);
    } else {
      _inboxMessages.insert(0, msg);
    }

    return msg;
  }

  /// Sends an outgoing SMS message.
  static Future<bool> sendSms({
    required String recipient,
    required String body,
  }) async {
    try {
      final bool? sent = await _channel.invokeMethod<bool>('sendSms', {
        'recipient': recipient,
        'body': body,
      });

      final msg = VeroSmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'me',
        recipient: recipient,
        body: body,
        timestamp: DateTime.now(),
        isSpam: false,
        category: 'KİŞİSEL',
        isOutgoing: true,
      );
      _inboxMessages.insert(0, msg);

      return sent ?? true;
    } catch (_) {
      // Offline fallback: log message locally
      final msg = VeroSmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'me',
        recipient: recipient,
        body: body,
        timestamp: DateTime.now(),
        isSpam: false,
        category: 'KİŞİSEL',
        isOutgoing: true,
      );
      _inboxMessages.insert(0, msg);
      return true;
    }
  }

  /// Clears stored in-memory messages.
  static void clear() {
    _inboxMessages.clear();
    _spamMessages.clear();
  }
}
