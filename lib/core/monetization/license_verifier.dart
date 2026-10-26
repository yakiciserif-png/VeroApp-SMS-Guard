import 'dart:convert';
import 'package:cryptography/cryptography.dart';

import 'purchase_service.dart';

/// Result of offline Ed25519 license verification.
class LicenseVerificationResult {
  const LicenseVerificationResult({
    required this.isValid,
    this.tier = VeroSubscriptionTier.free,
    this.seats = 0,
    this.expiresAt,
    this.licenseId,
    this.errorMessage,
  });

  final bool isValid;
  final VeroSubscriptionTier tier;
  final int seats;
  final DateTime? expiresAt;
  final String? licenseId;
  final String? errorMessage;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  String toString() =>
      'LicenseVerificationResult(valid: $isValid, tier: $tier, seats: $seats, error: $errorMessage)';
}

/// [ADIM 2] OFFLINE ED25519 SIGNED LICENSE VERIFIER
///
/// Verifies cryptographically signed license keys without ANY internet connection.
/// The private key exists ONLY in developer tools (never in the app).
/// The app contains ONLY the Ed25519 public key.
class VeroLicenseVerifier {
  VeroLicenseVerifier._();
  static final VeroLicenseVerifier instance = VeroLicenseVerifier._();

  /// Embedded Ed25519 Public Key (32 bytes raw, Base64).
  static const String masterPublicKeyBase64 =
      'caWKaSFI2a/+uP26ieWTB/lq8DSWg4WYZXfpaQARgkQ=';

  final Ed25519 _algorithm = Ed25519();
  PublicKey? _cachedPublicKey;

  Future<PublicKey> _getPublicKey() async {
    if (_cachedPublicKey != null) return _cachedPublicKey!;
    final rawBytes = base64.decode(masterPublicKeyBase64);
    _cachedPublicKey = SimplePublicKey(rawBytes, type: KeyPairType.ed25519);
    return _cachedPublicKey!;
  }

  static List<int> _decodeBase64Url(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final pad = normalized.length % 4;
    if (pad > 0) {
      normalized += '=' * (4 - pad);
    }
    return base64.decode(normalized);
  }

  /// Verifies [licenseCode] 100% offline using asymmetric Ed25519 signature.
  Future<LicenseVerificationResult> verifyCode(String licenseCode) async {
    final trimmed = licenseCode.trim();
    if (!trimmed.startsWith('VERO-')) {
      return const LicenseVerificationResult(
        isValid: false,
        errorMessage: 'Geçersiz lisans kodu formatı (VERO- ön eki bulunamadı).',
      );
    }

    final firstDash = trimmed.indexOf('-');
    final secondDash = trimmed.indexOf('-', firstDash + 1);
    if (secondDash == -1) {
      return const LicenseVerificationResult(
        isValid: false,
        errorMessage: 'Eksik veya hatalı lisans yapısı.',
      );
    }

    final body = trimmed.substring(secondDash + 1);
    final dotIndex = body.indexOf('.');
    if (dotIndex == -1) {
      return const LicenseVerificationResult(
        isValid: false,
        errorMessage: 'İmza bloğu bulunamadı.',
      );
    }

    final payloadB64 = body.substring(0, dotIndex);
    final sigB64 = body.substring(dotIndex + 1);

    List<int> payloadBytes;
    List<int> sigBytes;
    try {
      payloadBytes = _decodeBase64Url(payloadB64);
      sigBytes = _decodeBase64Url(sigB64);
    } catch (_) {
      return const LicenseVerificationResult(
        isValid: false,
        errorMessage: 'Kod çözme hatası (Geçersiz Base64 verisi).',
      );
    }

    if (sigBytes.length != 64) {
      return const LicenseVerificationResult(
        isValid: false,
        errorMessage: 'Geçersiz imza uzunluğu (Ed25519 imzası 64 bayt olmalıdır).',
      );
    }

    try {
      final publicKey = await _getPublicKey();
      final signature = Signature(
        sigBytes,
        publicKey: publicKey,
      );

      final isSignatureValid = await _algorithm.verify(
        payloadBytes,
        signature: signature,
      );

      if (!isSignatureValid) {
        return const LicenseVerificationResult(
          isValid: false,
          errorMessage: 'Kriptografik imza doğrulaması başarısız (Kod sahte veya değiştirilmiş).',
        );
      }

      final payloadJson = utf8.decode(payloadBytes);
      final map = json.decode(payloadJson) as Map<String, dynamic>;

      final expSec = (map['exp'] as num?)?.toInt() ?? 0;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expSec * 1000);
      if (DateTime.now().isAfter(expiresAt)) {
        return LicenseVerificationResult(
          isValid: false,
          expiresAt: expiresAt,
          errorMessage: 'Lisans süresi dolmuş ($expiresAt).',
        );
      }

      final tierStr = (map['tier'] as String?)?.toLowerCase() ?? 'family';
      final seats = (map['seats'] as num?)?.toInt() ?? 4;
      final licId = map['id'] as String? ?? 'VERO-LIC';

      final tier = tierStr == 'enterprise'
          ? VeroSubscriptionTier.familyYearly // or enterprise tier mapping
          : VeroSubscriptionTier.familyYearly;

      return LicenseVerificationResult(
        isValid: true,
        tier: tier,
        seats: seats,
        expiresAt: expiresAt,
        licenseId: licId,
      );
    } catch (e) {
      return LicenseVerificationResult(
        isValid: false,
        errorMessage: 'Doğrulama hatası: $e',
      );
    }
  }
}
