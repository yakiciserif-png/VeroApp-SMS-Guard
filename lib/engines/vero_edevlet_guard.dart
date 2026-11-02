import 'vero_bloom_filter.dart';
import 'vero_breach_radar_engine.dart';

/// Represents the offline evaluation result of an e-Devlet password.
class VeroEDevletAuditResult {
  const VeroEDevletAuditResult({
    required this.passwordLength,
    required this.isWeak,
    required this.weaknessReasons,
    required this.isExposed,
    required this.breachCount,
    required this.sha1Prefix,
    required this.securityScore,
    required this.recommendation,
  });

  final int passwordLength;
  final bool isWeak;
  final List<String> weaknessReasons;
  final bool isExposed;
  final int breachCount;
  final String sha1Prefix;

  /// Score from 0 (compromised / very weak) to 100 (fully secure).
  final int securityScore;
  final String recommendation;

  bool get isSafe => !isExposed && !isWeak;

  String localizedStatus(bool isTr) {
    if (isExposed) {
      return isTr
          ? 'e-Devlet şifreniz $breachCount veri sızıntısında bulundu!'
          : 'Your e-Devlet password was found in $breachCount data breach(es)!';
    }
    if (isWeak) {
      return isTr
          ? 'e-Devlet şifreniz zayıf: ${weaknessReasons.join(", ")}.'
          : 'Your e-Devlet password is weak: ${weaknessReasons.join(", ")}.';
    }
    return isTr
        ? 'e-Devlet şifreniz güvenli ve hiçbir sızıntıda bulunamadı.'
        : 'Your e-Devlet password is secure and not found in any breach.';
  }
}

/// 100% Offline e-Devlet Password Security Engine.
///
/// Analyzes password strength and cross-checks against the on-device
/// Bloom filter database with zero network activity (100% KVKK/GDPR compliant).
class VeroEDevletGuard {
  const VeroEDevletGuard._();

  static const List<String> _predictableSequences = [
    '123456',
    '12345678',
    'password',
    'qwerty',
    'edevlet',
    'turkiye',
    'admin',
  ];

  /// Audits [password] locally without storing the raw plaintext.
  static VeroEDevletAuditResult auditPassword(String password) {
    final trimmed = password.trim();
    final weaknesses = <String>[];

    if (trimmed.length < 8) {
      weaknesses.add('8 karakterden kısa');
    }
    if (!RegExp(r'[A-Z]').hasMatch(trimmed)) {
      weaknesses.add('büyük harf içermiyor');
    }
    if (!RegExp(r'[a-z]').hasMatch(trimmed)) {
      weaknesses.add('küçük harf içermiyor');
    }
    if (!RegExp(r'[0-9]').hasMatch(trimmed)) {
      weaknesses.add('rakam içermiyor');
    }
    final lower = trimmed.toLowerCase();
    for (final seq in _predictableSequences) {
      if (lower.contains(seq)) {
        weaknesses.add('tahmin edilebilir içerik ($seq)');
        break;
      }
    }

    final isWeak = weaknesses.isNotEmpty;

    // Breach check via offline Bloom filter
    final breachResult = VeroBreachRadarEngine.checkIdentity(trimmed);
    final isExposed = breachResult.isExposed;
    final breachCount = breachResult.breachCount;

    // Calculate security score
    var score = 100;
    if (isExposed) {
      score -= 60;
    }
    if (trimmed.length < 8) score -= 30;
    if (!RegExp(r'[A-Z]').hasMatch(trimmed)) score -= 15;
    if (!RegExp(r'[0-9]').hasMatch(trimmed)) score -= 15;
    if (weaknesses.any((w) => w.startsWith('tahmin'))) score -= 25;
    if (score < 0) score = 0;

    String recommendation;
    if (isExposed) {
      recommendation =
          'Bu şifre sızdırılmış veritabanlarında yer alıyor! Derhal e-Devlet Kapısı üzerinden yeni ve benzersiz bir şifre belirleyin.';
    } else if (isWeak) {
      recommendation =
          'e-Devlet şifreniz 8 karakterden kısa, büyük harf ve rakam içermiyor. Güçlendirin.';
    } else {
      recommendation =
          'Harika! Şifreniz güçlü kriterlere uyuyor ve yerel sızıntı arşivlerinde bulunamadı.';
    }

    return VeroEDevletAuditResult(
      passwordLength: trimmed.length,
      isWeak: isWeak,
      weaknessReasons: weaknesses,
      isExposed: isExposed,
      breachCount: breachCount,
      sha1Prefix: breachResult.sha1Prefix,
      securityScore: score,
      recommendation: recommendation,
    );
  }

  /// Calculates a local salted SHA-1 fingerprint for encrypted verification.
  static String calculateFingerprint(String password, [String salt = 'veroapp_salt']) {
    return VeroBloomFilter.signatureHex('$salt:$password');
  }
}
