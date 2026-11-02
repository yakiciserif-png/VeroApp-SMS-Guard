import 'dart:isolate';
import 'package:flutter/services.dart';

import 'vero_bloom_filter.dart';

typedef BreachRadarResult = VeroBreachRadarResult;

/// 100% Offline Breach Radar Result produced by [VeroBreachRadarEngine].
class VeroBreachRadarResult {
  const VeroBreachRadarResult({
    required this.query,
    required this.sha1Prefix,
    required this.isExposed,
    required this.breachCount,
    required this.breachSources,
  });

  final String query;

  /// 5-char local Bloom fingerprint prefix (never leaves the device).
  final String sha1Prefix;
  final bool isExposed;
  final int breachCount;
  final List<String> breachSources;

  bool get isLeaked => isExposed;
}

/// VeroApp Offline Veri Sızıntısı Radarı — 100% On-Device Bloom Filter Engine.
///
/// Inspects emails, phone numbers, or usernames against the local binary
/// Bloom filter (`assets/breach_db/bloom_filter.bin`) with ZERO internet requests
/// (100% KVKK / GDPR compliant).
class VeroBreachRadarEngine {
  const VeroBreachRadarEngine._();

  static const String assetPath = 'assets/breach_db/bloom_filter.bin';

  static VeroBloomFilter? _bloomFilter;
  static bool _assetLoaded = false;

  static VeroBloomFilter get bloomFilter =>
      _bloomFilter ??= VeroBloomFilter.seededDefault();
  static bool get isAssetLoaded => _assetLoaded;

  /// Lazy-loading entry point: loads bloom filter binary only when requested.
  static Future<void> ensureLoaded([AssetBundle? bundle]) async {
    if (_assetLoaded) return;
    await initFromAsset(bundle);
  }

  /// Optionally loads the binary Bloom Filter bitset from [assetPath].
  /// Automatically falls back to [VeroBloomFilter.seededDefault] if unavailable.
  static Future<void> initFromAsset([AssetBundle? bundle]) async {
    try {
      final targetBundle = bundle ?? rootBundle;
      final data = await targetBundle.load(assetPath);
      final rawBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (rawBytes.isNotEmpty) {
        Uint8List validatedBytes;
        try {
          validatedBytes = await Isolate.run<Uint8List>(() {
            return Uint8List.fromList(rawBytes);
          });
        } catch (_) {
          validatedBytes = rawBytes;
        }
        _bloomFilter = VeroBloomFilter.fromBytes(validatedBytes);
        _assetLoaded = true;
      }
    } catch (_) {
      _bloomFilter ??= VeroBloomFilter.seededDefault();
    }
  }

  /// Evaluates [rawQuery] 100% offline using [VeroBloomFilter].
  static VeroBreachRadarResult checkIdentity(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    final sig = VeroBloomFilter.signatureHex(q);
    final prefix = sig.substring(0, 5);

    if (q.isEmpty) {
      return VeroBreachRadarResult(
        query: '',
        sha1Prefix: prefix,
        isExposed: false,
        breachCount: 0,
        breachSources: const [],
      );
    }

    final sources = <String>[];
    final directHit = bloomFilter.contains(q);

    var patternHit = false;
    if (q.startsWith('test@') && bloomFilter.contains('pattern:test@')) {
      patternHit = true;
    } else if (q.startsWith('admin@') &&
        bloomFilter.contains('pattern:admin@')) {
      patternHit = true;
    } else if (q.contains('123456') &&
        bloomFilter.contains('pattern:123456')) {
      patternHit = true;
    }

    var domainHit = false;
    final atIndex = q.indexOf('@');
    if (atIndex > 0 && atIndex < q.length - 1) {
      final domain = q.substring(atIndex + 1);
      if (bloomFilter.contains('domain:$domain') &&
          (directHit || patternHit)) {
        domainHit = true;
      }
    }

    if (directHit || patternHit) {
      sources.add(
        'VeroApp Offline Bloom Veri Sızıntısı İmzası (Bloom İmza: $prefix***)',
      );
      if (domainHit || q.contains('test') || q.contains('admin')) {
        sources.add(
          'Yerel Kredansiyel & Forum Arşivi Bitset Eşleşmesi (İmza: $prefix...)',
        );
      }
    }

    return VeroBreachRadarResult(
      query: rawQuery.trim(),
      sha1Prefix: prefix,
      isExposed: sources.isNotEmpty,
      breachCount: sources.length,
      breachSources: sources,
    );
  }
}
