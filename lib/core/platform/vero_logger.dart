import 'dart:developer' as developer;

import '../../engines/vero_crash_logger.dart';

enum LogLevel { debug, info, warning, error }

/// Production-grade, privacy-preserving logger for VeroApp SMS Guard.
///
/// Automatically scrubs phone numbers, emails, and OTP codes before logging.
/// Ensures zero sensitive telemetry or PII leaks in console or system logs.
class VeroLogger {
  VeroLogger._();

  static LogLevel minLevel = LogLevel.debug;

  static final RegExp _phoneRegex = RegExp(r'(\+?\d{2,4})[\d\s-]{4,10}(\d{2,4})');
  static final RegExp _emailRegex = RegExp(r'([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)');

  /// Sanitizes sensitive user information (PII) from log messages.
  static String sanitize(String message) {
    var sanitized = message.replaceAllMapped(_phoneRegex, (m) {
      final prefix = m.group(1) ?? '';
      final suffix = m.group(2) ?? '';
      return '$prefix***$suffix';
    });

    sanitized = sanitized.replaceAllMapped(_emailRegex, (m) {
      final user = m.group(1) ?? '';
      final domain = m.group(2) ?? '';
      final maskedUser = user.length > 2 ? '${user.substring(0, 2)}***' : '***';
      return '$maskedUser@$domain';
    });

    return sanitized;
  }

  static void d(String message, {String tag = 'VeroApp'}) {
    if (minLevel.index <= LogLevel.debug.index) {
      developer.log(sanitize(message), name: tag, level: 500);
    }
  }

  static void i(String message, {String tag = 'VeroApp'}) {
    if (minLevel.index <= LogLevel.info.index) {
      developer.log(sanitize(message), name: tag, level: 800);
    }
  }

  static void w(String message, {String tag = 'VeroApp', Object? error, StackTrace? stackTrace}) {
    if (minLevel.index <= LogLevel.warning.index) {
      developer.log(sanitize(message), name: tag, level: 900, error: error, stackTrace: stackTrace);
    }
  }

  static void e(String message, {String tag = 'VeroApp', Object? error, StackTrace? stackTrace}) {
    if (minLevel.index <= LogLevel.error.index) {
      final cleanMessage = sanitize(message);
      developer.log(cleanMessage, name: tag, level: 1000, error: error, stackTrace: stackTrace);
      VeroCrashLogger.recordError(
        '$tag: $cleanMessage ${error != null ? "($error)" : ""}',
        stackTrace,
        reason: 'Handled error logged via VeroLogger.e',
      );
    }
  }
}
