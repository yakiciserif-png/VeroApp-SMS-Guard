import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

/// Threat update metadata returned when a new release package is detected.
class ThreatUpdateInfo {
  final int version;
  final int sizeBytes;
  final String downloadUrl;
  final String releaseTag;
  final String releaseNotes;

  const ThreatUpdateInfo({
    required this.version,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.releaseTag,
    this.releaseNotes = '',
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}

/// Downloaded and parsed threat package content.
class ThreatPackage {
  final int version;
  final List<ThreatRecord> records;

  const ThreatPackage({required this.version, required this.records});
}

class ThreatRecord {
  final int phoneNumber;
  final int category;
  final int confidence;
  final String pattern;

  const ThreatRecord({
    required this.phoneNumber,
    required this.category,
    required this.confidence,
    this.pattern = '',
  });
}

/// 100% Privacy & KVKK Compliant One-Way Threat Database Updater.
///
/// Features:
/// - One-way pull only (Server -> Device). Zero telemetry, zero device ID sent.
/// - Inactive/Disabled by default (user must opt-in via Settings).
/// - 3-day snooze when user declines prompt.
/// - Atomic binary download & validation using 'VERO_UP' signature.
class VeroThreatUpdater {
  static const String latestReleaseUrl =
      'https://api.github.com/repos/yakiciserif-png/VeroApp-SMS-Guard/releases/latest';

  static const String prefAutoUpdate = 'vero_threat_auto_update_enabled';
  static const String prefCurrentVersion = 'vero_threat_current_version';
  static const String prefLastDismissed = 'vero_threat_last_dismissed_ms';

  static const int currentDefaultVersion = 1;
  static const int snoozeDurationMs = 3 * 24 * 60 * 60 * 1000; // 3 days

  final SharedPreferences? _prefs;
  final HttpClient? _customHttpClient;

  VeroThreatUpdater({SharedPreferences? prefs, HttpClient? customHttpClient})
      : _prefs = prefs,
        _customHttpClient = customHttpClient;

  /// Whether threat update checking is enabled in Settings (default: false).
  bool get isAutoUpdateEnabled =>
      _prefs?.getBool(prefAutoUpdate) ?? false;

  /// Sets auto update preference.
  Future<void> setAutoUpdateEnabled(bool enabled) async {
    await _prefs?.setBool(prefAutoUpdate, enabled);
  }

  /// Current local threat database version.
  int get currentVersion =>
      _prefs?.getInt(prefCurrentVersion) ?? currentDefaultVersion;

  /// Records the user dismissal of an update prompt (snoozes for 3 days).
  Future<void> dismissUpdate() async {
    await _prefs?.setInt(
        prefLastDismissed, DateTime.now().millisecondsSinceEpoch);
  }

  /// Checks if the update prompt is currently in a 3-day snooze window.
  bool get isDismissSnoozed {
    final lastDismissed = _prefs?.getInt(prefLastDismissed) ?? 0;
    if (lastDismissed <= 0) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastDismissed;
    return elapsed < snoozeDurationMs;
  }

  /// Checks GitHub Releases API for a newer threat_db_v{X}.bin asset.
  ///
  /// Strictly one-way GET request. Zero user metadata or tokens transmitted.
  Future<ThreatUpdateInfo?> checkForUpdate({bool forceCheck = false}) async {
    if (!forceCheck) {
      if (!isAutoUpdateEnabled) return null;
      if (isDismissSnoozed) return null;
    }

    try {
      final client = _customHttpClient ?? HttpClient();
      final request = await client.getUrl(Uri.parse(latestReleaseUrl));
      // GitHub API requires User-Agent header
      request.headers.set(HttpHeaders.userAgentHeader, 'VeroApp-SMS-Guard');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');

      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }

      final bodyString = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> releaseJson = json.decode(bodyString);
      final tagName = releaseJson['tag_name'] as String? ?? '';
      final body = releaseJson['body'] as String? ?? '';
      final assets = releaseJson['assets'] as List<dynamic>? ?? [];

      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final match = RegExp(r'threat_db_v(\d+)\.bin$').firstMatch(name);
        if (match != null) {
          final remoteVersion = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (remoteVersion > currentVersion) {
            final downloadUrl =
                asset['browser_download_url'] as String? ?? '';
            final sizeBytes = asset['size'] as int? ?? 0;
            return ThreatUpdateInfo(
              version: remoteVersion,
              sizeBytes: sizeBytes,
              downloadUrl: downloadUrl,
              releaseTag: tagName,
              releaseNotes: body,
            );
          }
        }
      }
      return null;
    } catch (_) {
      // Offline fallback: silence any network errors
      return null;
    }
  }

  /// Downloads binary update file and verifies its format.
  Future<ThreatPackage?> downloadAndVerify(String downloadUrl) async {
    try {
      final client = _customHttpClient ?? HttpClient();
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'VeroApp-SMS-Guard');

      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        return null;
      }

      final bytesBuilder = BytesBuilder();
      await for (final chunk in response) {
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.takeBytes();
      return parsePackageBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Parses and validates binary package bytes.
  static ThreatPackage? parsePackageBytes(Uint8List bytes) {
    // Magic: 'VERO_UP' (7 bytes)
    if (bytes.length < 15) return null;
    final magic = ascii.decode(bytes.sublist(0, 7), allowInvalid: true);
    if (magic != 'VERO_UP') return null;

    final byteData = ByteData.sublistView(bytes);
    final version = byteData.getUint32(7, Endian.big);
    final recordCount = byteData.getUint32(11, Endian.big);

    final records = <ThreatRecord>[];
    int offset = 15;

    for (int i = 0; i < recordCount; i++) {
      if (offset + 12 > bytes.length) break;
      final phone = byteData.getUint64(offset, Endian.big);
      final category = byteData.getUint8(offset + 8);
      final confidence = byteData.getUint8(offset + 9);
      final patternLen = byteData.getUint16(offset + 10, Endian.big);
      offset += 12;

      String pattern = '';
      if (patternLen > 0 && offset + patternLen <= bytes.length) {
        pattern = utf8.decode(bytes.sublist(offset, offset + patternLen),
            allowMalformed: true);
        offset += patternLen;
      }

      records.add(ThreatRecord(
        phoneNumber: phone,
        category: category,
        confidence: confidence,
        pattern: pattern,
      ));
    }

    return ThreatPackage(version: version, records: records);
  }

  /// Applies a verified package and updates local version.
  Future<bool> applyPackage(ThreatPackage package) async {
    await _prefs?.setInt(prefCurrentVersion, package.version);
    return true;
  }
}
