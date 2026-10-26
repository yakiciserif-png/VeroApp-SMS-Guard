import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Data model representing a logged application crash or exception.
class VeroCrashRecord {
  const VeroCrashRecord({
    required this.timestamp,
    required this.errorMessage,
    required this.stackTrace,
    required this.deviceInfo,
    this.reason,
  });

  final DateTime timestamp;
  final String errorMessage;
  final String stackTrace;
  final String deviceInfo;
  final String? reason;

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'deviceInfo': deviceInfo,
        if (reason != null) 'reason': reason,
      };

  String toFormattedString() {
    return '''
========================================
TIMESTAMP: ${timestamp.toIso8601String()}
DEVICE: $deviceInfo
REASON: ${reason ?? 'Unhandled exception'}
ERROR: $errorMessage
STACK TRACE:
$stackTrace
========================================
''';
  }
}

/// 100% Offline Crash Logger for VeroApp SMS Guard.
///
/// Hooks into Flutter framework and platform error dispatchers to capture
/// unhandled errors and store them strictly on the local device filesystem.
/// ZERO telemetry, ZERO analytics, and ZERO internet requests.
class VeroCrashLogger {
  VeroCrashLogger._();
  static final VeroCrashLogger instance = VeroCrashLogger._();

  static final List<VeroCrashRecord> _records = [];
  static bool _initialized = false;

  static List<VeroCrashRecord> get records => List.unmodifiable(_records);
  static int get count => _records.length;

  /// Attaches error listeners without requiring network access.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      recordError(
        details.exceptionAsString(),
        details.stack,
        reason: details.context?.toDescription(),
      );
      // Retain original console output in debug/test mode
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error.toString(), stack, reason: 'PlatformDispatcher unhandled error');
      return true;
    };
  }

  /// Manually records an error locally.
  static void recordError(
    String errorMessage,
    StackTrace? stack, {
    String? reason,
  }) {
    final record = VeroCrashRecord(
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      stackTrace: stack?.toString() ?? 'No stack trace provided',
      deviceInfo: _getDeviceInfo(),
      reason: reason,
    );
    _records.add(record);
    if (_records.length > 100) {
      _records.removeAt(0); // keep rolling 100 entries
    }
  }

  /// Calculates error count within the last 7 days.
  static int getLogCountLast7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _records.where((r) => r.timestamp.isAfter(cutoff)).length;
  }

  /// Clears all local crash logs.
  static void clearLogs() {
    _records.clear();
  }

  /// Returns aggregated logs formatted for export or user-initiated email.
  static String exportLogsText() {
    if (_records.isEmpty) {
      return 'VeroApp SMS Guard - Temiz (Son 7 günde kaydedilmiş hata bulunamadı).';
    }
    final buffer = StringBuffer('=== VEROAPP SMS GUARD OFFLINE CRASH LOGS ===\n');
    for (final r in _records) {
      buffer.writeln(r.toFormattedString());
    }
    return buffer.toString();
  }

  /// Generates a standard mailto URL for user to review and send with their own mail app.
  static String generateMailtoUrl() {
    final subject = Uri.encodeComponent('VeroApp SMS Guard Crash Report');
    final body = Uri.encodeComponent(exportLogsText());
    return 'mailto:support@veroapp.com?subject=$subject&body=$body';
  }

  static String _getDeviceInfo() {
    try {
      return '${Platform.operatingSystem} (${Platform.operatingSystemVersion})';
    } catch (_) {
      return 'Generic Platform / Test Runtime';
    }
  }
}
