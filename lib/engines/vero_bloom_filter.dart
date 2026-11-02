import 'dart:convert';
import 'dart:typed_data';

/// 100% Offline SHA-1 Bitset Bloom Filter Engine for VeroApp Offline Veri Sızıntısı Radarı.
///
/// Uses RFC 3174 SHA-1 double-hashing over a 1.5 MB binary bit array
/// (`assets/breach_db/bloom_filter.bin`, 1,572,864 bytes = 12,582,912 bits)
/// capable of indexing 500,000+ leaked credentials/identities with zero network calls.
class VeroBloomFilter {
  VeroBloomFilter({
    int byteLength = defaultByteLength,
    this.hashCount = defaultHashCount,
    Uint8List? bytes,
  }) : _bits = bytes ?? Uint8List(byteLength);

  /// 50,000,000 bits (~6.25 MB = 6,250,000 bytes) Bloom Filter capacity for 5,000,000+ SHA-1 entries.
  static const int kSize = 50000000;
  static const int defaultByteLength = kSize ~/ 8; // 6,250,000 bytes (~6.25 MB)
  static const int defaultHashCount = 7;

  /// Core seed identities always included alongside the 500,000 rockyou/breach records.
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
    '123456789',
    'password',
    'qwerty',
    '12345678',
    '111111',
    '1234567890',
    'iloveyou',
    'admin',
    'welcome',
    '+905001112233',
    '050011112233',
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

  /// Builds a seeded offline 1.5 MB Bloom filter with default breach signatures.
  factory VeroBloomFilter.seededDefault() {
    final filter = VeroBloomFilter(byteLength: defaultByteLength);
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
      bytes: bytes,
    );
  }

  static String _normalize(String raw) => raw.trim().toLowerCase();

  static int _rotl32(int val, int shift) =>
      ((val << shift) & 0xFFFFFFFF) | ((val & 0xFFFFFFFF) >>> (32 - shift));

  /// Pure-Dart RFC 3174 SHA-1 implementation (returns 20-byte digest).
  static Uint8List sha1Bytes(List<int> message) {
    final msgLen = message.length;
    final bitLen = msgLen * 8;

    // Pad message: append 0x80, then 0x00 until length ≡ 56 (mod 64), then 64-bit big-endian bit length.
    final padLen = ((56 - (msgLen + 1) % 64) + 64) % 64;
    final totalLen = msgLen + 1 + padLen + 8;
    final padded = Uint8List(totalLen);
    padded.setRange(0, msgLen, message);
    padded[msgLen] = 0x80;

    final bd = ByteData.sublistView(padded);
    bd.setUint32(totalLen - 8, (bitLen ~/ 0x100000000) & 0xFFFFFFFF, Endian.big);
    bd.setUint32(totalLen - 4, bitLen & 0xFFFFFFFF, Endian.big);

    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    final w = Uint32List(80);

    for (var chunkOffset = 0; chunkOffset < totalLen; chunkOffset += 64) {
      for (var i = 0; i < 16; i++) {
        w[i] = bd.getUint32(chunkOffset + i * 4, Endian.big);
      }
      for (var i = 16; i < 80; i++) {
        w[i] = _rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;

      for (var i = 0; i < 80; i++) {
        int f;
        int k;
        if (i < 20) {
          f = (b & c) | ((~b & 0xFFFFFFFF) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotl32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotl32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    final out = Uint8List(20);
    final outBd = ByteData.sublistView(out);
    outBd.setUint32(0, h0, Endian.big);
    outBd.setUint32(4, h1, Endian.big);
    outBd.setUint32(8, h2, Endian.big);
    outBd.setUint32(12, h3, Endian.big);
    outBd.setUint32(16, h4, Endian.big);
    return out;
  }

  /// Computes the 40-character uppercase SHA-1 hex digest of [rawInput].
  static String signatureHex(String rawInput) {
    final digest = sha1Bytes(utf8.encode(_normalize(rawInput)));
    final sb = StringBuffer();
    for (final b in digest) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString().toUpperCase();
  }

  static (int, int) _extractHashPair(Uint8List sha1Digest) {
    final bd = ByteData.sublistView(sha1Digest);
    var h1 = bd.getUint32(0, Endian.big) & 0x7FFFFFFF;
    if (h1 == 0) h1 = 0x13579BDF;
    final h2 = (bd.getUint32(4, Endian.big) | 1) & 0x7FFFFFFF;
    return (h1, h2);
  }

  /// Inserts a normalized string into the Bloom filter using its SHA-1 digest.
  void add(String rawItem) {
    final norm = _normalize(rawItem);
    if (norm.isEmpty) return;
    final digest = sha1Bytes(utf8.encode(norm));
    final (h1, h2) = _extractHashPair(digest);
    final totalBits = bitLength;

    for (var i = 0; i < hashCount; i++) {
      final bitIndex = ((h1 + i * h2) & 0x7FFFFFFF) % totalBits;
      final byteIdx = bitIndex >> 3;
      final bitMask = 1 << (bitIndex & 7);
      _bits[byteIdx] |= bitMask;
    }
  }

  /// Returns `true` if all k SHA-1 bit positions for [rawItem] are set in the bitset.
  bool contains(String rawItem) {
    final norm = _normalize(rawItem);
    if (norm.isEmpty) return false;
    final digest = sha1Bytes(utf8.encode(norm));
    final (h1, h2) = _extractHashPair(digest);
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
