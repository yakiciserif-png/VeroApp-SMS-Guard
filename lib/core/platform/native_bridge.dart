import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Captured message forwarded by the native Android NotificationListener / SMS Receiver.
class PendingMessage {
  const PendingMessage({
    required this.text,
    required this.timestamp,
    this.sender,
    this.packageName,
    this.dismissed = false,
  });

  final String text;
  final DateTime timestamp;
  final String? sender;
  final String? packageName;

  /// True when the native filter already removed the notification as spam.
  final bool dismissed;

  factory PendingMessage.fromMap(Map<dynamic, dynamic> m) => PendingMessage(
        text: m['text'] as String? ?? '',
        sender: m['sender'] as String?,
        packageName: m['package'] as String?,
        dismissed: m['dismissed'] as bool? ?? false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (m['timestamp'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
}

/// Status of OS-level real-time SMS/Notification interception hooks (FAZ 4).
class SystemHooksStatus {
  const SystemHooksStatus({
    this.notificationAccess = false,
    this.smsPermissionGranted = false,
    this.isDefaultSmsRoleHeld = false,
    this.lastInterceptLatencyMs = 0.0,
  });

  final bool notificationAccess;
  final bool smsPermissionGranted;
  final bool isDefaultSmsRoleHeld;
  final double lastInterceptLatencyMs;

  bool get isAnyRealTimeHookActive =>
      notificationAccess || smsPermissionGranted || isDefaultSmsRoleHeld;

  factory SystemHooksStatus.fromMap(Map<dynamic, dynamic> m) =>
      SystemHooksStatus(
        notificationAccess: m['notificationAccess'] as bool? ?? false,
        smsPermissionGranted: m['smsPermissionGranted'] as bool? ?? false,
        isDefaultSmsRoleHeld: m['isDefaultSmsRoleHeld'] as bool? ?? false,
        lastInterceptLatencyMs:
            (m['lastInterceptLatencyMs'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Thin, crash-free wrapper over the `com.veroapp.smsguard/native` method channel
/// implemented in `MainActivity.kt` (Android TFLite & Notification/SMS hooks)
/// and `AppDelegate.swift` (iOS CoreML & IdentityLookup App Group).
///
/// Every call is wrapped in try-catch so the Dart layer degrades gracefully
/// on any platform (Windows, Web, Android, iOS, unit tests) without crashing.
class NativeBridge {
  const NativeBridge({this.enabled = true, this.forceAndroidUi = false});

  final bool enabled;
  final bool forceAndroidUi;

  static const MethodChannel _channel =
      MethodChannel('com.veroapp.smsguard/native');

  bool get isAndroid =>
      (enabled || forceAndroidUi) &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;
  bool get isIOS =>
      enabled && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    if (!enabled) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('NativeBridge.$method failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('NativeBridge.$method unexpected error: $e');
      return null;
    }
  }

  Future<bool> isNotificationAccessGranted() async =>
      isAndroid && (await _invoke<bool>('isNotificationAccessGranted') ?? false);

  Future<void> openNotificationAccessSettings() async {
    if (isAndroid) await _invoke<void>('openNotificationAccessSettings');
  }

  /// Queries all OS-level real-time SMS/Notification hook statuses without crashing.
  Future<SystemHooksStatus> getSystemHooksStatus() async {
    if (!isAndroid) return const SystemHooksStatus();
    final raw = await _invoke<Map<dynamic, dynamic>>('getSystemHooksStatus');
    if (raw != null) {
      return SystemHooksStatus.fromMap(raw);
    }
    final notif = await isNotificationAccessGranted();
    return SystemHooksStatus(notificationAccess: notif);
  }

  /// Requests Android runtime `RECEIVE_SMS`, `READ_SMS`, and `POST_NOTIFICATIONS`
  /// permissions gracefully. Returns `false` if denied or on non-Android platforms.
  Future<bool> requestSmsPermissions() async {
    if (!isAndroid) return false;
    return await _invoke<bool>('requestSmsPermissions') ?? false;
  }

  /// Requests Android 10+ (API 29+) `RoleManager.ROLE_SMS` / Default SMS Filter
  /// role gracefully. Returns `false` if cancelled/denied.
  Future<bool> requestSpamRole() async {
    if (!isAndroid) return false;
    return await _invoke<bool>('requestSpamRole') ?? false;
  }

  /// Pushes rules + exported model weights + semantic intent config to the
  /// native real-time filter (Android NotificationListener/SMSReceiver and
  /// iOS MessageFilter extension via App Group).
  Future<bool> syncFilterConfig(String configJson) async =>
      await _invoke<bool>('syncFilterConfig', configJson) ?? false;

  /// Optional on-device TFLite (Android) / CoreML (iOS) accelerator query.
  /// Gracefully returns `null` if the hardware accelerator or `.tflite`/`.mlmodel`
  /// file is unavailable, allowing the Semantic Intent Engine + Naive Bayes to
  /// run standalone without ever crashing.
  Future<Map<String, double>?> evaluateHardwareAccelerator(
    String text, {
    String? sender,
  }) async {
    if (!isAndroid && !isIOS) return null;
    final res = await _invoke<Map<dynamic, dynamic>>(
      'evaluateAccelerator',
      {'text': text, 'sender': sender},
    );
    if (res == null) return null;
    return res.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0),
    );
  }

  Future<List<PendingMessage>> fetchPendingMessages() async {
    if (!isAndroid) return const [];
    final raw = await _invoke<List<dynamic>>('fetchPendingMessages');
    if (raw == null) return const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(PendingMessage.fromMap)
        .where((m) => m.text.trim().isNotEmpty)
        .toList();
  }

  /// Fetches real device call logs via native Android CallLog provider.
  Future<List<Map<dynamic, dynamic>>> fetchCallLogs() async {
    if (!isAndroid) return const [];
    final raw = await _invoke<List<dynamic>>('fetchCallLogs');
    if (raw == null) return const [];
    return raw.whereType<Map<dynamic, dynamic>>().toList();
  }

  /// Requests `READ_CALL_LOG` runtime permission gracefully.
  Future<bool> requestCallLogPermission() async {
    if (!isAndroid) return false;
    return await _invoke<bool>('requestCallLogPermission') ?? false;
  }

  /// Checks if `READ_CALL_LOG` runtime permission is granted.
  Future<bool> isCallLogPermissionGranted() async {
    if (!isAndroid) return false;
    return await _invoke<bool>('isCallLogPermissionGranted') ?? false;
  }
}
