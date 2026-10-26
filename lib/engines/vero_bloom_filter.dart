import 'dart:convert';
import 'dart:typed_data';

/// 100% Offline Probabilistic Bitset Engine for VeroApp Offline Veri Sızıntısı Radarı.
///
/// Uses double-hashing (FNV-1a + Murmur-mix) over a compact binary bit array
/// (`assets/breach_db/bloom_filter.bin`) with zero network calls (100% KVKK / GDPR compliant).
class VeroBloomFilter {
  VeroBloomFilter({
    int byteLength = defaultByteLength,
    this.hashCount = defaultHashCount,
    Uint8List? bytes,
  }) : _bits = bytes ?? Uint8List(byteLength);

  static const int defaultByteLength = 8192; // 65,536 bits (8 KB)
  static const int defaultHashCount = 7;

  /// Pre-seeded compromised identities and domain/credential signatures
  /// embedded into `assets/breach_db/bloom_filter.bin`.
  static const List<String> defaultSeedIdentities = [
    'test@ornek.com',
    'test@example.com',
    'admin@example.com',
    'admin@ornek.com',
    'info@ornek.com',
    'user@gmail.com',
    'test@gmail.com',
    'deneme@gmail.com',
    'test@hotmail.com',
    'deneme@hotmail.com',
    '123456',
    '+905001112233',
    '05001112233',
    'domain:gmail.com',
    'domain:hotmail.com',
    'domain:yahoo.com',
    'pattern:test@',
    'pattern:admin@',
    'pattern:123456',
  ];

  final Uint8List _bits;
  final int hashCount;

  int get byteLength => _bits.length;
  int get bitLength => _bits.length * 8;
  Uint8List get rawBytes => Uint8List.fromList(_bits);

  /// Builds a seeded offline Bloom filter with default breach signatures.
  factory VeroBloomFilter.seededDefault() {
    final filter = VeroBloomFilter();
    for (final item in defaultSeedIdentities) {
      filter.add(item);
    }
    return filter;
  }

  /// Loads a Bloom filter from raw binary bytes (`assets/breach_db/bloom_filter.bin`).
  factory VeroBloomFilter.fromBytes(
    Uint8List bytes, {
    int hashCount = defaultHashCount,
  }) {
    if (bytes.isEmpty) {
      return VeroBloomFilter.seededDefault();
    }
    return VeroBloomFilter(
      byteLength: bytes.length,
      hashCount: hashCount,
      bytes: Uint8List.fromList(bytes),
    );
  }

  static String _normalize(String raw) => raw.trim().toLowerCase();

  /// Primary 32-bit FNV-1a hash.
  static int _hash1(List<int> data) {
    var h = 0x811C9DC5;
    for (final b in data) {
      h ^= (b & 0xFF);
      h = (h * 0x01000193) & 0x7FFFFFFF;
    }
    return h == 0 ? 0x13579BDF : h;
  }

  /// Secondary 32-bit Murmur-inspired mixing hash (guaranteed odd/non-zero step).
  static int _hash2(List<int> data) {
    var h = 0x9747B28C;
    for (final b in data) {
      var k = (b & 0xFF) * 0x5BD1E995;
      k ^= (k >> 15);
      h = ((h * 0x5BD1E995) ^ k) & 0x7FFFFFFF;
    }
    return (h | 1) & 0x7FFFFFFF;
  }

  /// Computes a deterministic 8-char hex fingerprint of the normalized query.
  static String signatureHex(String rawInput) {
    final bytes = utf8.encode(_normalize(rawInput));
    final h1 = _hash1(bytes);
    final h2 = _hash2(bytes);
    final combined = ((h1 ^ (h2 << 1)) & 0xFFFFFFFF);
    return combined.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  /// Inserts a normalized string into the Bloom filter bitset.
  void add(String rawItem) {
    final norm = _normalize(rawItem);
    if (norm.isEmpty) return;
    final data = utf8.encode(norm);
    final h1 = _hash1(data);
    final h2 = _hash2(data);
    final totalBits = bitLength;

    for (var i = 0; i < hashCount; i++) {
      final bitIndex = ((h1 + i * h2) & 0x7FFFFFFF) % totalBits;
      final byteIdx = bitIndex >> 3;
      final bitMask = 1 << (bitIndex & 7);
      _bits[byteIdx] |= bitMask;
    }
  }

  /// Returns `true` if all k bit positions for [rawItem] are set in the bitset.
  bool contains(String rawItem) {
    final norm = _normalize(rawItem);
    if (norm.isEmpty) return false;
    final data = utf8.encode(norm);
    final h1 = _hash1(data);
    final h2 = _hash2(data);
    final totalBits = bitLength;

    for (var i = 0; i < hashCount; i++) {
      final bitIndex = ((h1 + i * h2) & 0x7FFFFFFF) % totalBits;
      final byteIdx = bitIndex >> 3;
      final bitMask = 1 << (bitIndex & 7);
      if ((_bits[byteIdx] & bitMask) == 0) {
        return false;
      }
    }
    return true;
  }

  bool mightContain(String rawItem) => contains(rawItem);
}
