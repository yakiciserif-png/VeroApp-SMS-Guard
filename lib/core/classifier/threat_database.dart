/// Pre-built Threat & Spam Intelligence Database for VeroApp SMS Guard's
/// Threat Filters, upgraded with Homoglyph/Leetspeak de-obfuscation,
/// BTK B-Code parser, and sub-categories.
library;

import 'classification.dart';
import 'otp_detector.dart';
import 'tokenizer.dart';

/// Configuration for the 4 built-in threat protection shields.
class ThreatShieldConfig {
  const ThreatShieldConfig({
    this.bettingShield = true,
    this.phishingShield = true,
    this.linkShield = true,
    this.marketingShield = false,
  });

  /// Blocks illegal betting, casino, slot, freespin & bonus spam.
  final bool bettingShield;

  /// Blocks fake legal/icra/uzlaştırma, HGS toll, customs fee & bank phishing.
  final bool phishingShield;

  /// Penalizes shortened URLs, suspicious TLDs, and fake OTP+Link traps.
  final bool linkShield;

  /// Blocks commercial promotions (MERSIS, B001/B002 codes, RET/STOP opt-out).
  final bool marketingShield;

  ThreatShieldConfig copyWith({
    bool? bettingShield,
    bool? phishingShield,
    bool? linkShield,
    bool? marketingShield,
  }) =>
      ThreatShieldConfig(
        bettingShield: bettingShield ?? this.bettingShield,
        phishingShield: phishingShield ?? this.phishingShield,
        linkShield: linkShield ?? this.linkShield,
        marketingShield: marketingShield ?? this.marketingShield,
      );

  Map<String, dynamic> toJson() => {
        'bettingShield': bettingShield,
        'phishingShield': phishingShield,
        'linkShield': linkShield,
        'marketingShield': marketingShield,
      };

  factory ThreatShieldConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ThreatShieldConfig();
    return ThreatShieldConfig(
      bettingShield: json['bettingShield'] as bool? ?? true,
      phishingShield: json['phishingShield'] as bool? ?? true,
      linkShield: json['linkShield'] as bool? ?? true,
      marketingShield: json['marketingShield'] as bool? ?? false,
    );
  }
}

class ThreatAssessment {
  const ThreatAssessment({
    required this.isThreat,
    required this.score,
    this.subCategory,
    this.shieldName,
    this.signals = const [],
    this.btkAnalysis,
  });

  final bool isThreat;
  final double score;
  final MessageSubCategory? subCategory;
  final String? shieldName;
  final List<String> signals;
  final BtkAnalysis? btkAnalysis;

  static const clean = ThreatAssessment(isThreat: false, score: 0);
}

class ThreatDatabase {
  ThreatDatabase._();

  /// High-confidence betting / gambling phrases (Turkish + Multilingual + ASCII-folded).
  static const List<String> bettingPhrases = [
    'deneme bonusu',
    'hoşgeldin bonusu',
    'hosgeldin bonusu',
    'yatırımsız bonus',
    'yatirimsiz bonus',
    'çevrimsiz bonus',
    'cevrimsiz bonus',
    'kayıp bonusu',
    'kayip bonusu',
    'freespin',
    'free spin',
    'sweet bonanza',
    'gates of olympus',
    'canlı bahis',
    'canli bahis',
    'yasal bahis',
    'bahis sitesi',
    'casino bonusu',
    'slot oyun',
    'nakit bonus',
    'anında çekim',
    'aninda cekim',
    'yüksek oran',
    'yuksek oran',
  ];

  static const List<String> bettingTokens = [
    'bahis',
    'casino',
    'freespin',
    'bonanza',
    'jackpot',
    'roulette',
    'blackjack',
    'aviator',
    'betting',
    'wagering',
  ];

  /// Fake legal / government / HGS / customs phishing patterns.
  static const List<String> govAndLegalScamPhrases = [
    'uzlaştırma dosyası',
    'uzlastirma dosyasi',
    'icra dosyası',
    'icra dosyasi',
    'icra takibi',
    'ceza dosyası',
    'ceza dosyasi',
    'ceza dosyanız',
    'ceza dosyaniz',
    'hgs borcu',
    'hgs geçiş',
    'hgs gecis',
    'ogs borcu',
    'uzlaşma bürosu',
    'uzlasma burosu',
    'hukuk bürosundan',
    'hukuk burosundan',
    'son gününüzdür',
    'son gununuzdur',
    'haciz işlemi',
    'haciz islemi',
  ];

  static const List<String> deliveryScamPhrases = [
    'gümrük ücreti',
    'gumruk ucreti',
    'gümrük vergisi',
    'gumruk vergisi',
    'customs fee',
    'unpaid customs',
    'tasas de aduana',
    'zollgebühren',
    'frais de douane',
    'dazi doganali',
    'таможенный сбор',
    '未缴关税',
    'رسوم جمركية',
    'taxa alfandegária',
  ];

  static const List<String> accountPhishingPhrases = [
    'hesabınız askıya',
    'hesabiniz askiya',
    'account has been suspended',
    'verify your details immediately',
    'cuenta ha sido bloqueada',
    'konto wurde gesperrt',
    'compte a été suspendu',
    'conto è stato bloccato',
    'карта заблокирована',
    '账户已被冻结',
    'تم إيقاف حسابك',
    'conta foi bloqueada',
  ];

  static const List<String> marketingPhrases = [
    'mersis',
    'ret yaz',
    'iptal yaz',
    'reply stop',
    '退订',
  ];

  static ThreatAssessment evaluate(
    String text, {
    String? sender,
    ThreatShieldConfig config = const ThreatShieldConfig(),
  }) {
    final combined = sender != null && sender.trim().isNotEmpty
        ? '$sender $text'
        : text;
    final normalized = Tokenizer.normalizeObfuscation(combined);
    final features = Tokenizer.features(text, sender: sender);
    final btk = Tokenizer.analyzeBtk(text, sender: sender);

    final hasUrl = features.contains(Tokenizer.urlToken);
    final hasShortUrl = features.contains(Tokenizer.shortUrlToken);
    final hasSuspiciousTld = features.contains(Tokenizer.suspiciousTldToken);
    final hasBCode = btk.hasValidBCode || btk.hasMersis || features.contains(Tokenizer.bCodeToken);
    final hasFakeBCode = btk.hasFakeBCodeTrap || features.contains(Tokenizer.fakeBCodeToken);
    final hasForeignNoBCode = btk.isForeignSenderWithoutBCode || features.contains(Tokenizer.foreignNoBCodeToken);
    final hasHomoglyph = features.contains(Tokenizer.homoglyphToken);
    final hasObfuscation = features.contains(Tokenizer.obfuscatedToken);

    final signals = <String>[];

    if (hasShortUrl) signals.add('signalShortUrl');
    if (hasSuspiciousTld) signals.add('signalSuspiciousTld');
    if (hasUrl) signals.add('signalContainsUrl');
    if (hasBCode) signals.add('signalCommercialCode');
    if (hasFakeBCode) signals.add('signalFakeBCode');
    if (hasForeignNoBCode) signals.add('signalForeignNoBCode');
    if (hasHomoglyph) signals.add('signalHomoglyphAttack');
    if (hasObfuscation) signals.add('signalObfuscatedText');

    // 1. Betting & Gambling Shield
    if (config.bettingShield) {
      final hasBettingPhrase = bettingPhrases.any(normalized.contains);
      final bettingTokenHits =
          bettingTokens.where((t) => features.contains(t) || normalized.contains(t)).length;

      if (hasBettingPhrase ||
          bettingTokenHits >= 2 ||
          (bettingTokenHits >= 1 &&
              (hasUrl ||
                  normalized.contains('bonus') ||
                  hasObfuscation ||
                  hasHomoglyph ||
                  hasFakeBCode ||
                  hasForeignNoBCode))) {
        signals.add('signalBettingPattern');
        return ThreatAssessment(
          isThreat: true,
          score: 0.98,
          subCategory: MessageSubCategory.bettingGambling,
          shieldName: 'shieldBetting',
          signals: signals,
          btkAnalysis: btk,
        );
      }
    }

    // 2. Phishing, Fake Gov/Legal, Fake Delivery, Fake B-Code & Foreign No-BCode Shield
    if (config.phishingShield) {
      if (govAndLegalScamPhrases.any(normalized.contains)) {
        signals.add('signalGovLegalScam');
        return ThreatAssessment(
          isThreat: true,
          score: 0.96,
          subCategory: MessageSubCategory.governmentScam,
          shieldName: 'shieldPhishing',
          signals: signals,
          btkAnalysis: btk,
        );
      }

      if (deliveryScamPhrases.any(normalized.contains)) {
        signals.add('signalDeliveryScam');
        return ThreatAssessment(
          isThreat: true,
          score: 0.96,
          subCategory: MessageSubCategory.deliveryCustomsScam,
          shieldName: 'shieldPhishing',
          signals: signals,
          btkAnalysis: btk,
        );
      }

      if (accountPhishingPhrases.any(normalized.contains)) {
        signals.add('signalAccountPhishing');
        return ThreatAssessment(
          isThreat: true,
          score: 0.97,
          subCategory: MessageSubCategory.phishingScam,
          shieldName: 'shieldPhishing',
          signals: signals,
          btkAnalysis: btk,
        );
      }

      // Spoofed/Fake B-Code trap (e.g. "B.0.0.1", "B O O 1", Cyrillic "В001")
      if (hasFakeBCode) {
        return ThreatAssessment(
          isThreat: true,
          score: 0.96,
          subCategory: MessageSubCategory.phishingScam,
          shieldName: 'shieldPhishing',
          signals: signals,
          btkAnalysis: btk,
        );
      }

      // Unknown foreign sender (+63, +62, etc.) without a valid BTK B-Code
      if (hasForeignNoBCode) {
        return ThreatAssessment(
          isThreat: true,
          score: 0.94,
          subCategory: hasUrl
              ? MessageSubCategory.phishingScam
              : MessageSubCategory.generalSpam,
          shieldName: 'shieldPhishing',
          signals: signals,
          btkAnalysis: btk,
        );
      }
    }

    // 3. Suspicious Link & Fake OTP+Link Trap Shield
    if (config.linkShield) {
      final otp = OtpDetector.analyze(text);
      if (otp.isTransaction && hasUrl) {
        signals.add('signalOtpWithLinkTrap');
        return ThreatAssessment(
          isThreat: true,
          score: 0.95,
          subCategory: MessageSubCategory.phishingScam,
          shieldName: 'shieldLink',
          signals: signals,
          btkAnalysis: btk,
        );
      }
    }

    // 4. Optional Commercial / Marketing Promotion Shield
    if (config.marketingShield) {
      if (hasBCode || marketingPhrases.any(normalized.contains)) {
        signals.add('signalMarketing');
        return ThreatAssessment(
          isThreat: true,
          score: 0.90,
          subCategory: MessageSubCategory.marketingPromotion,
          shieldName: 'shieldMarketing',
          signals: signals,
          btkAnalysis: btk,
        );
      }
    }

    return ThreatAssessment(
      isThreat: false,
      score: 0,
      signals: signals,
      btkAnalysis: btk,
    );
  }
}
