import 'vero_caller_id_engine.dart';
import 'vero_community_shield.dart';
import 'vero_intent_engine.dart';
import 'vero_link_scanner.dart';

/// WhatsApp / Messenger message safety classification.
enum WhatsAppSafetyLevel {
  safe,
  suspicious,
  dangerous,
}

/// Detailed scan outcome for a scanned WhatsApp message.
class WhatsAppScanResult {
  const WhatsAppScanResult({
    required this.originalText,
    required this.safetyLevel,
    required this.riskScore,
    required this.threatSummary,
    required this.reasons,
    required this.detectedUrls,
    required this.detectedPhoneNumbers,
    required this.recommendedAction,
    this.fraudCategory,
  });

  final String originalText;
  final WhatsAppSafetyLevel safetyLevel;
  final double riskScore; // 0.0 - 100.0
  final String threatSummary;
  final List<String> reasons;
  final List<String> detectedUrls;
  final List<String> detectedPhoneNumbers;
  final String recommendedAction;
  final String? fraudCategory;

  bool get isSafe => safetyLevel == WhatsAppSafetyLevel.safe;
  bool get isSuspicious => safetyLevel == WhatsAppSafetyLevel.suspicious;
  bool get isDangerous => safetyLevel == WhatsAppSafetyLevel.dangerous;

  String get badgeText => switch (safetyLevel) {
        WhatsAppSafetyLevel.safe => '✅ GÜVENLİ',
        WhatsAppSafetyLevel.suspicious => '⚠️ ŞÜPHELİ',
        WhatsAppSafetyLevel.dangerous => '🚨 TEHLİKELİ (DOLANDIRICILIK)',
      };
}

/// WhatsApp & Telegram Message Scanner (100% Offline, Zero Internet).
///
/// Analyzes forwarded text, shared messages, and clipboard text for:
/// 1. Malicious / Phishing Links (via VeroLinkScanner)
/// 2. Known Spam / Scam Phone Numbers (via VeroCallerIdEngine & VeroCommunityShield)
/// 3. Fraud Intent Patterns (via VeroIntentEngine 6D engine)
class VeroWhatsAppScanner {
  VeroWhatsAppScanner._();

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9.\-]+\.(?:com|net|org|xyz|top|click|tk|ml|app|biz|info|site|online|live)[^\s]*)',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?[0-9]{1,4}[\s-]?)?(?:\(?0?[0-9]{3}\)?[\s-]?)?[0-9]{3}[\s-]?[0-9]{2}[\s-]?[0-9]{2}',
  );

  /// Scans a message text synchronously and returns a comprehensive [WhatsAppScanResult].
  static WhatsAppScanResult scanMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const WhatsAppScanResult(
        originalText: '',
        safetyLevel: WhatsAppSafetyLevel.safe,
        riskScore: 0.0,
        threatSummary: 'Metin boş',
        reasons: [],
        detectedUrls: [],
        detectedPhoneNumbers: [],
        recommendedAction: 'Taranacak bir metin girilmedi.',
      );
    }

    final reasons = <String>[];
    double riskScore = 0.0;
    String? detectedFraud;

    // 1. Extract & Scan URLs
    final foundUrls = <String>[];
    for (final match in _urlRegex.allMatches(trimmed)) {
      final raw = match.group(0);
      if (raw != null && raw.length > 3) {
        foundUrls.add(raw);
        final linkResult = VeroLinkScanner.instance.scanUrl(raw);
        if (linkResult.isThreat) {
          reasons.add('Zararlı/Oltalama Bağlantısı: ${linkResult.domain} (${linkResult.reasons.join(", ")})');
          riskScore += (linkResult.riskLevel == LinkRiskLevel.dangerous ? 50.0 : 25.0);
        }
      }
    }

    // 2. Extract & Scan Phone Numbers
    final foundPhones = <String>[];
    for (final match in _phoneRegex.allMatches(trimmed)) {
      final rawPhone = match.group(0);
      if (rawPhone != null && rawPhone.replaceAll(RegExp(r'\D'), '').length >= 7) {
        foundPhones.add(rawPhone);
        final digits = VeroCommunityShield.normalizeDigits(rawPhone);
        final spamLookup = VeroCallerIdEngine.lookup(digits);
        final communityLookup = VeroCommunityShield.lookupReported(digits);

        if (spamLookup.isSpam) {
          reasons.add('Spam/Dolandırıcı Numara: $rawPhone (${spamLookup.category})');
          riskScore += 45.0;
        } else if (communityLookup != null) {
          reasons.add('Topluluk Bildirilen Numara: $rawPhone');
          riskScore += 35.0;
        } else if (spamLookup.isSuspicious) {
          reasons.add('Şüpheli Numara Kalıbı: $rawPhone (${spamLookup.patternDescription})');
          riskScore += 20.0;
        }
      }
    }

    // 3. 6D Fraud Pattern Analysis
    final fraudAnalysis = VeroIntentEngine.instance.analyze(trimmed);
    if (fraudAnalysis.isFraud) {
      detectedFraud = fraudAnalysis.type?.titleTr ?? 'Bilinmeyen Dolandırıcılık Kalıbı';
      reasons.add('Dolandırıcılık Tespiti: $detectedFraud (Güven: %${(fraudAnalysis.confidence * 100).toInt()})');
      riskScore += (fraudAnalysis.confidence * 50.0);
    }

    // Keyword heuristics for typical WhatsApp scams (evden çalışma, yatırım, günlük görev vb.)
    final lower = trimmed.toLowerCase();
    if (lower.contains('günlük görev') ||
        lower.contains('gunluk gorev') ||
        lower.contains('görev') ||
        lower.contains('gorev') ||
        lower.contains('evden paketleme') ||
        lower.contains('evden para') ||
        lower.contains('beğen ve kazan') ||
        lower.contains('begen ve kazan') ||
        lower.contains('telegram kanalı') ||
        lower.contains('telegram kanali') ||
        lower.contains('kripto kazanç') ||
        lower.contains('kripto kazanc') ||
        lower.contains('hesabınız bloke') ||
        lower.contains('hesabiniz bloke') ||
        lower.contains('haciz başlatıldı') ||
        lower.contains('haciz baslatildi')) {
      if (!reasons.any((r) => r.contains('Kalıbı'))) {
        reasons.add('Yüksek riskli sosyal mühendislik / görev dolandırıcılığı anahtar kelimeleri.');
        riskScore += 30.0;
      }
    }

    riskScore = riskScore.clamp(0.0, 100.0);

    WhatsAppSafetyLevel safety;
    String summary;
    String action;

    if (riskScore >= 60.0) {
      safety = WhatsAppSafetyLevel.dangerous;
      summary = '🚨 Yüksek Dolandırıcılık Tehdidi!';
      action = 'Bu mesaja ASLA yanıt vermeyin, hiçbir linke tıklamayın ve göndereni engelleyin.';
    } else if (riskScore >= 25.0) {
      safety = WhatsAppSafetyLevel.suspicious;
      summary = '⚠️ Şüpheli İçerik Tespit Edildi';
      action = 'Bilinmeyen kaynaklardan gelen teklif veya linklere karşı dikkatli olun.';
    } else {
      safety = WhatsAppSafetyLevel.safe;
      summary = '✅ Güvenli Görünüyor';
      action = 'Mesajda bilinen herhangi bir tehdit veya zararlı bağlantı saptanmadı.';
    }

    return WhatsAppScanResult(
      originalText: trimmed,
      safetyLevel: safety,
      riskScore: riskScore,
      threatSummary: summary,
      reasons: reasons,
      detectedUrls: foundUrls,
      detectedPhoneNumbers: foundPhones,
      recommendedAction: action,
      fraudCategory: detectedFraud,
    );
  }
}
