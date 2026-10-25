import 'dart:math' as math;

import 'classification.dart';
import 'otp_detector.dart';
import 'tokenizer.dart';

/// 6-Dimensional Semantic Intent Vector ("Dükkan & Hakan Abi" Architecture).
/// Each dimension is normalized to [0.0, 1.0].
class IntentVector {
  const IntentVector({
    required this.urgencyFear,
    required this.financialTrap,
    required this.rewardBetting,
    required this.actionLink,
    required this.corporateOtp,
    required this.personalChat,
  });

  /// ACİLİYET / KORKU ("son 24 saat", "hesabınız kapatılacak", "icra", "haciz")
  final double urgencyFear;

  /// FİNANSAL TUZAK ("para kazan", "borç kapatma", "yatırım fırsatı", "gümrük ücreti")
  final double financialTrap;

  /// ÖDÜL / BAHİS ("bonus", "bedava", "kazandınız", "freespin", "casino")
  final double rewardBetting;

  /// LİNK / EYLEM ("tıkla", link yönlendirmesi, kısaltılmış URL, şüpheli TLD)
  final double actionLink;

  /// KURUMSAL / OTP (banka/kargo kalıpları, tek kullanımlık doğrulama kodu)
  final double corporateOtp;

  /// KİŞİSEL / SOHBET ("Hakan abi", "dükkana bıraktım", günlük samimi konuşma dili)
  final double personalChat;

  static const zero = IntentVector(
    urgencyFear: 0,
    financialTrap: 0,
    rewardBetting: 0,
    actionLink: 0,
    corporateOtp: 0,
    personalChat: 0,
  );

  Map<String, double> toMap() => {
        'urgencyFear': double.parse(urgencyFear.toStringAsFixed(3)),
        'financialTrap': double.parse(financialTrap.toStringAsFixed(3)),
        'rewardBetting': double.parse(rewardBetting.toStringAsFixed(3)),
        'actionLink': double.parse(actionLink.toStringAsFixed(3)),
        'corporateOtp': double.parse(corporateOtp.toStringAsFixed(3)),
        'personalChat': double.parse(personalChat.toStringAsFixed(3)),
      };

  factory IntentVector.fromMap(Map<String, dynamic>? map) {
    if (map == null) return IntentVector.zero;
    return IntentVector(
      urgencyFear: (map['urgencyFear'] as num?)?.toDouble() ?? 0.0,
      financialTrap: (map['financialTrap'] as num?)?.toDouble() ?? 0.0,
      rewardBetting: (map['rewardBetting'] as num?)?.toDouble() ?? 0.0,
      actionLink: (map['actionLink'] as num?)?.toDouble() ?? 0.0,
      corporateOtp: (map['corporateOtp'] as num?)?.toDouble() ?? 0.0,
      personalChat: (map['personalChat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Output of [SemanticIntentEngine.analyze].
class SemanticIntentResult {
  const SemanticIntentResult({
    required this.vector,
    required this.ngramRiskScore,
    required this.comboMultiplier,
    required this.spamIntentScore,
    required this.transactionIntentScore,
    required this.normalIntentScore,
    required this.probabilities,
    required this.dominantCategory,
    this.suggestedSubCategory,
    this.signals = const [],
    this.whyReasons = const [],
  });

  final IntentVector vector;
  final double ngramRiskScore;
  final double comboMultiplier;
  final double spamIntentScore;
  final double transactionIntentScore;
  final double normalIntentScore;
  final Map<MessageCategory, double> probabilities;
  final MessageCategory dominantCategory;
  final MessageSubCategory? suggestedSubCategory;
  final List<String> signals;
  final List<String> whyReasons;
}

/// On-Device Local AI Semantic Intent Engine ("Dükkan & Hakan Abi" Architecture).
///
/// Instead of relying on simple keyword blocking, this engine reads the
/// underlying 6-dimensional semantic intent of a message after FAZ 2
/// de-obfuscation, combines it with 3-gram / 4-gram structural patterns,
/// and applies non-linear combo multipliers.
class SemanticIntentEngine {
  SemanticIntentEngine._();

  // 1. ACİLİYET / KORKU (Urgency & Fear)
  static const List<String> _urgencyPatterns = [
    'son 24 saat',
    'son gun',
    'son gün',
    'hesabiniz kapatilacak',
    'hesabınız kapatılacak',
    'hesabiniz askiya',
    'hesabınız askıya',
    'kartiniz bloke',
    'kartınız bloke',
    'bloke edilmistir',
    'bloke edilmiştir',
    'icra takibi',
    'icra dosyasi',
    'icra dosyası',
    'haciz islemi',
    'haciz işlemi',
    'uzlastirma dosyasi',
    'uzlaştırma dosyası',
    'ceza dosyasi',
    'ceza dosyası',
    'hukuk burosu',
    'hukuk bürosu',
    'avukatlik burosu',
    'mahkeme karari',
    'yasal islem',
    'yasal işlem',
    'derhal',
    'hemen dogrulayin',
    'vadesi gecmis',
    'vadesi geçmiş',
    'gecikme faizi',
    'son uyari',
    'son uyarı',
    'urgent',
    'immediately',
    'suspended',
    'account blocked',
    'final notice',
    'legal action',
  ];

  // 2. FİNANSAL TUZAK (Financial Trap & Smishing Fees)
  static const List<String> _financialTrapPatterns = [
    'para kazan',
    'borc kapatma',
    'borç kapatma',
    'yatirim firsati',
    'yatırım fırsatı',
    'gunluk kazanc',
    'günlük kazanç',
    'haftalik kazanc',
    'evden calisarak',
    'evden çalışarak',
    'ek gelir',
    'kefilsiz',
    'masrafsiz kredi',
    'masrafsız kredi',
    'faizsiz kredi',
    'aninda kredi',
    'anında kredi',
    'gumruk ucreti',
    'gümrük ücreti',
    'gumruk vergisi',
    'gümrük vergisi',
    'hgs borcu',
    'hgs gecis',
    'ogs borcu',
    'teslimat ucreti',
    'kargo ucreti',
    'adres guncelleme ucreti',
    'vergi iadesi',
    'aidat iadesi',
    'customs fee',
    'unpaid customs',
    'cheap loans',
    'no credit check',
    'earn money',
    'work from home',
    'part time is',
    'part-time is',
  ];

  // 3. ÖDÜL / BAHİS (Reward, Gambling & Illegal Casino)
  static const List<String> _rewardBettingPatterns = [
    'bonus',
    'deneme bonusu',
    'hosgeldin bonusu',
    'hoşgeldin bonusu',
    'cevrimsiz',
    'çevrimsiz',
    'yatirimsiz',
    'yatırımsız',
    'kayip bonusu',
    'kayıp bonusu',
    'nakit bonus',
    'freespin',
    'free spin',
    'bedava',
    'kazandiniz',
    'kazandınız',
    'hediye ceki',
    'hediye çeki',
    'odul',
    'ödül',
    'cekilis',
    'çekiliş',
    'bahis',
    'canli bahis',
    'canlı bahis',
    'casino',
    'slot',
    'sweet bonanza',
    'gates of olympus',
    'jackpot',
    'aviator',
    'rulet',
    'roulette',
    'blackjack',
    'yuksek oran',
    'yüksek oran',
    'aninda cekim',
    'anında çekim',
    'congratulations',
    'you have won',
    'gift card',
    'free prize',
  ];

  // 4. LİNK / EYLEM (Call-to-Action & Link Redirection)
  static const List<String> _actionCallPatterns = [
    'tikla',
    'tıkla',
    'tiklayin',
    'tıklayın',
    'tiklayiniz',
    'hemen tikla',
    'linke tikla',
    'baglantidan',
    'bağlantıdan',
    'giris yap',
    'giriş yap',
    'uye ol',
    'üye ol',
    'hemen katil',
    'hemen katıl',
    'aktif et',
    'aktiflestir',
    'talep et',
    'formu doldur',
    'hemen al',
    'hemen oyna',
    'click here',
    'claim now',
    'verify now',
    'tap here',
  ];

  // 5. KURUMSAL / OTP (Corporate, Banking & Legitimate Delivery)
  static const List<String> _corporateOtpPatterns = [
    'dogrulama kodu',
    'doğrulama kodu',
    'dogrulama kodunuz',
    'doğrulama kodunuz',
    'onay kodu',
    'onay kodunuz',
    'tek kullanimlik',
    'tek kullanımlık',
    'sifreniz',
    'şifreniz',
    'kimseyle paylasmayin',
    'kimseyle paylaşmayın',
    'kimseyle paylasmayiniz',
    'harcama yapilmistir',
    'harcama yapılmıştır',
    'kullanilabilir limit',
    'kullanılabilir limit',
    'hesabiniza havale',
    'fast islemi',
    'kargo takip',
    'teslimat kodunuz',
    'dagitima cikmistir',
    'dağıtıma çıkmıştır',
    'randevunuz',
    'faturaniz',
    'verification code',
    'one-time password',
    'do not share this code',
  ];

  // 6. KİŞİSEL / SOHBET ("Dükkan & Hakan Abi" Personal Context)
  static const List<String> _personalChatPatterns = [
    'abi',
    'abla',
    'kardesim',
    'kardeşim',
    'kanka',
    'canim',
    'canım',
    'anne',
    'annem',
    'baba',
    'babam',
    'merhaba',
    'selam',
    'nasilsin',
    'nasılsın',
    'naber',
    'neredesin',
    'dukkan',
    'dükkan',
    'dukkana',
    'dükkana',
    'emaneti',
    'biraktim',
    'bıraktım',
    'eve gelirken',
    'ekmek al',
    'aksam',
    'akşam',
    'yarin',
    'yarın',
    'oglen',
    'öğlen',
    'toplantiya',
    'toplantıya',
    'trafik',
    'gec kalacagim',
    'geç kalacağım',
    'gorusuruz',
    'görüşürüz',
    'haber ver',
    'musait olunca',
    'müsait olunca',
    'kahve',
    'cay icelim',
    'yemege',
    'yemeğe',
    'dogum gunun',
    'doğum günün',
    'hayirli isler',
    'hayırlı işler',
    'kolay gelsin',
    'lunch tomorrow',
    'on your way home',
    'happy birthday',
    'call her back',
  ];

  static final RegExp _turkishQuestionSuffix = RegExp(
    r'\b(misin|mısın|musun|müsün|miyiz|mıyız|muyuz|müyüz|miyim|mıyım)\b',
    caseSensitive: false,
  );

  /// Suspicious 3-gram and 4-gram character roots typical in Turkish betting/smishing
  /// brands & disguised payloads after normalization.
  static const List<String> _suspiciousNgrams = [
    'bah',
    'bhs',
    'bet',
    'cas',
    'csn',
    'spn',
    'fsp',
    'bns',
    'bnz',
    'jkp',
    'slt',
    'icr',
    'uzl',
    'hgs',
    'gmr',
    'bahi',
    'casi',
    'fres',
    'spin',
    'bonu',
    'bona',
    'jack',
    'ruol',
    'icra',
    'uzla',
    'gumr',
    'blke',
  ];

  /// Pattern for illegal betting brand + number domains/names (e.g. "casibom784", "jojobet912", "bet365", "onwin44").
  static final RegExp _brandNumberPattern = RegExp(
    r'\b(?:[a-z]*(?:bet|bahis|casino|slot|spin|win|pasha|king|bom|holigan|mars|jojo|sahabet|matador|merit|kral|vay)[a-z]*\d{2,4}|\d{2,4}(?:bet|bahis|casino|win))\b',
    caseSensitive: false,
  );

  /// Extracts character n-grams of size [n] from cleaned text.
  static Set<String> extractCharNgrams(String cleanedText, int n) {
    final compact = cleanedText.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (compact.length < n) return const {};
    final ngrams = <String>{};
    for (var i = 0; i <= compact.length - n; i++) {
      ngrams.add(compact.substring(i, i + n));
    }
    return ngrams;
  }

  /// Evaluates 3-gram and 4-gram structural risk on FAZ 2 normalized text.
  static double evaluateNgramRisk(String normalizedText, {required bool hasUrl}) {
    final ascii = Tokenizer.foldTurkishAscii(normalizedText);
    final strippedUrls = ascii.replaceAll(Tokenizer.urlPattern, ' ');
    final ngrams3 = extractCharNgrams(strippedUrls, 3);
    final ngrams4 = extractCharNgrams(strippedUrls, 4);

    var hits = 0;
    for (final ng in _suspiciousNgrams) {
      if (ng.length == 3 && ngrams3.contains(ng)) hits++;
      if (ng.length == 4 && ngrams4.contains(ng)) hits += 2;
    }

    var score = (hits / 8.0).clamp(0.0, 0.75);
    if (_brandNumberPattern.hasMatch(ascii)) {
      score = (score + (hasUrl ? 0.55 : 0.40)).clamp(0.0, 1.0);
    }
    return score;
  }

  static double _scoreDimension(
    String normalized,
    List<String> patterns, {
    double perHit = 0.38,
    double extraBoost = 0.0,
  }) {
    var hits = 0;
    for (final p in patterns) {
      if (normalized.contains(p)) hits++;
    }
    if (hits == 0 && extraBoost == 0) return 0.0;
    final raw = (hits * perHit) + extraBoost;
    return raw.clamp(0.0, 1.0);
  }

  /// Computes the full 6-dimensional semantic intent vector, N-gram analysis,
  /// dynamic combo multipliers, and human-readable X-Ray decision reasons.
  static SemanticIntentResult analyze(
    String text, {
    String? sender,
    BtkAnalysis? btk,
  }) {
    final combined = sender != null && sender.trim().isNotEmpty
        ? '$sender $text'
        : text;
    final normalized = Tokenizer.normalizeObfuscation(combined);
    final features = Tokenizer.features(text, sender: sender);
    final btkInfo = btk ?? Tokenizer.analyzeBtk(text, sender: sender);
    final otpInfo = OtpDetector.analyze(text);

    final hasUrl = features.contains(Tokenizer.urlToken);
    final hasShortUrl = features.contains(Tokenizer.shortUrlToken);
    final hasSuspiciousTld = features.contains(Tokenizer.suspiciousTldToken);
    final hasHomoglyph = features.contains(Tokenizer.homoglyphToken);
    final hasObfuscation = features.contains(Tokenizer.obfuscatedToken);

    // 1. Calculate 6 Intent Dimensions
    final urgencyFear = _scoreDimension(
      normalized,
      _urgencyPatterns,
      perHit: 0.42,
      extraBoost: normalized.contains('!') && normalized.contains('acil') ? 0.15 : 0.0,
    );

    final financialTrap = _scoreDimension(
      normalized,
      _financialTrapPatterns,
      perHit: 0.42,
      extraBoost: RegExp(r'\b\d+[.,]?\d*\s*(tl|usd|eur|₺|\$|€)\b').hasMatch(normalized) &&
              hasUrl
          ? 0.22
          : 0.0,
    );

    final rewardBetting = _scoreDimension(
      normalized,
      _rewardBettingPatterns,
      perHit: 0.40,
      extraBoost: _brandNumberPattern.hasMatch(normalized) ? 0.35 : 0.0,
    );

    var actionLinkBoost = 0.0;
    if (hasUrl) actionLinkBoost += 0.42;
    if (hasShortUrl) actionLinkBoost += 0.35;
    if (hasSuspiciousTld) actionLinkBoost += 0.30;
    final actionLink = _scoreDimension(
      normalized,
      _actionCallPatterns,
      perHit: 0.32,
      extraBoost: actionLinkBoost,
    );

    var otpBoost = 0.0;
    if (otpInfo.isTransaction && !hasUrl) {
      otpBoost += otpInfo.extractedCode != null ? 0.65 : 0.50;
    }
    final corporateOtp = _scoreDimension(
      normalized,
      _corporateOtpPatterns,
      perHit: 0.35,
      extraBoost: otpBoost,
    );

    var chatBoost = 0.0;
    if (_turkishQuestionSuffix.hasMatch(normalized) && !hasUrl) {
      chatBoost += 0.25;
    }
    if (text.trim().endsWith('?') && !hasUrl && rewardBetting == 0) {
      chatBoost += 0.18;
    }
    final personalChat = _scoreDimension(
      normalized,
      _personalChatPatterns,
      perHit: 0.36,
      extraBoost: chatBoost,
    );

    final vector = IntentVector(
      urgencyFear: urgencyFear,
      financialTrap: financialTrap,
      rewardBetting: rewardBetting,
      actionLink: actionLink,
      corporateOtp: corporateOtp,
      personalChat: personalChat,
    );

    // 2. Character 3-gram & 4-gram Risk Evaluation
    final ngramRisk = evaluateNgramRisk(normalized, hasUrl: hasUrl);

    // 3. Dynamic Combo Multiplier & Reason Extraction
    var comboMultiplier = 1.0;
    final signals = <String>[];
    final whyReasons = <String>[];

    if (urgencyFear >= 0.35) whyReasons.add('whyUrgencyFear');
    if (financialTrap >= 0.35) whyReasons.add('whyFinancialTrap');
    if (rewardBetting >= 0.35) whyReasons.add('whyRewardBetting');
    if (actionLink >= 0.35) whyReasons.add('whyActionLink');
    if (ngramRisk >= 0.40) {
      whyReasons.add('whyNgramBrandPattern');
      signals.add('signalSemanticNgram');
    }
    if (hasHomoglyph || hasObfuscation) {
      whyReasons.add('whyHomoglyphObfuscation');
    }
    if (btkInfo.hasFakeBCodeTrap) {
      whyReasons.add('whyFakeBCode');
    }
    if (btkInfo.isForeignSenderWithoutBCode) {
      whyReasons.add('whyBtkMissingForeign');
    }

    // Combo 1: Reward/Betting + Action/Link
    if (rewardBetting >= 0.30 && actionLink >= 0.30) {
      comboMultiplier *= 1.65;
      whyReasons.add('whyComboRewardLink');
      signals.add('signalIntentCombo');
    }
    // Combo 2: Urgency/Fear + Action/Link (Classic Smishing / İcra / Bank Phishing)
    if (urgencyFear >= 0.30 && actionLink >= 0.30) {
      comboMultiplier *= 1.70;
      whyReasons.add('whyComboUrgencyLink');
      if (!signals.contains('signalIntentCombo')) signals.add('signalIntentCombo');
    }
    // Combo 3: Financial Trap + (Link or Urgency)
    if (financialTrap >= 0.30 && (actionLink >= 0.25 || urgencyFear >= 0.25)) {
      comboMultiplier *= 1.60;
      whyReasons.add('whyComboFinancialTrap');
      if (!signals.contains('signalIntentCombo')) signals.add('signalIntentCombo');
    }
    // Combo 4: Obfuscated/Homoglyph + Any Spam Intent
    if ((hasHomoglyph || hasObfuscation) &&
        (rewardBetting >= 0.25 || urgencyFear >= 0.25 || financialTrap >= 0.25)) {
      comboMultiplier *= 1.45;
    }

    comboMultiplier = comboMultiplier.clamp(1.0, 2.5);

    // 4. Compute Composite Semantic Scores
    var rawSpamIntent = (urgencyFear * 0.65) +
        (financialTrap * 0.70) +
        (rewardBetting * 0.85) +
        (actionLink * 0.45) +
        (ngramRisk * 0.55);

    if (btkInfo.hasFakeBCodeTrap) rawSpamIntent += 0.85;
    if (btkInfo.isForeignSenderWithoutBCode) rawSpamIntent += 0.75;
    if (hasHomoglyph || hasObfuscation) rawSpamIntent += 0.45;

    final spamIntentScore = (rawSpamIntent * comboMultiplier).clamp(0.0, 3.0);

    final transactionIntentScore = (!hasUrl &&
            !btkInfo.hasFakeBCodeTrap &&
            !btkInfo.isForeignSenderWithoutBCode)
        ? (corporateOtp * 1.4).clamp(0.0, 2.0)
        : 0.0;

    // "Dükkan & Hakan Abi" personal conversation confidence
    final isCleanConversational = !hasUrl &&
        rewardBetting < 0.25 &&
        urgencyFear < 0.25 &&
        financialTrap < 0.25 &&
        !btkInfo.hasFakeBCodeTrap &&
        !btkInfo.isForeignSenderWithoutBCode;

    final normalIntentScore = isCleanConversational
        ? (0.45 + personalChat * 1.35).clamp(0.0, 2.2)
        : (0.20 + personalChat * 0.35).clamp(0.0, 1.0);

    if (corporateOtp >= 0.50 && transactionIntentScore > spamIntentScore) {
      whyReasons.add('whyOtpFastPath');
    } else if (isCleanConversational && personalChat >= 0.30) {
      whyReasons.add('whyPersonalChatContext');
    }

    // Softmax over intent logits
    final logits = <MessageCategory, double>{
      MessageCategory.normal: normalIntentScore * 2.2,
      MessageCategory.transaction: transactionIntentScore * 2.4 - (otpInfo.isTransaction ? 0.0 : 1.5),
      MessageCategory.spam: spamIntentScore * 2.4 - 0.35,
    };

    final maxLogit = logits.values.reduce(math.max);
    final exps = logits.map((k, v) => MapEntry(k, math.exp(v - maxLogit)));
    final sum = exps.values.fold(0.0, (a, b) => a + b);
    final probabilities = exps.map((k, v) => MapEntry(k, v / sum));

    final dominant = probabilities.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    MessageSubCategory? subCategory;
    if (dominant == MessageCategory.spam) {
      if (rewardBetting >= 0.35) {
        subCategory = MessageSubCategory.bettingGambling;
      } else if (urgencyFear >= 0.35 &&
          (normalized.contains('icra') ||
              normalized.contains('uzlas') ||
              normalized.contains('hgs') ||
              normalized.contains('ceza'))) {
        subCategory = MessageSubCategory.governmentScam;
      } else if (financialTrap >= 0.35 &&
          (normalized.contains('gumruk') || normalized.contains('kargo'))) {
        subCategory = MessageSubCategory.deliveryCustomsScam;
      } else if (urgencyFear >= 0.35 || financialTrap >= 0.35 || btkInfo.hasFakeBCodeTrap) {
        subCategory = MessageSubCategory.phishingScam;
      } else if (hasUrl || hasShortUrl) {
        subCategory = MessageSubCategory.suspiciousLink;
      } else {
        subCategory = MessageSubCategory.generalSpam;
      }
    } else if (dominant == MessageCategory.transaction) {
      subCategory = otpInfo.extractedCode != null
          ? MessageSubCategory.otpCode
          : MessageSubCategory.bankTransaction;
    } else {
      subCategory = MessageSubCategory.personal;
    }

    return SemanticIntentResult(
      vector: vector,
      ngramRiskScore: ngramRisk,
      comboMultiplier: comboMultiplier,
      spamIntentScore: spamIntentScore,
      transactionIntentScore: transactionIntentScore,
      normalIntentScore: normalIntentScore,
      probabilities: probabilities,
      dominantCategory: dominant,
      suggestedSubCategory: subCategory,
      signals: signals,
      whyReasons: whyReasons,
    );
  }
}
