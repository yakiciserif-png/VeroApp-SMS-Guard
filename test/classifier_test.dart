import 'package:flutter_test/flutter_test.dart';
import 'package:veroapp_sms_guard/core/classifier/classification.dart';
import 'package:veroapp_sms_guard/core/classifier/naive_bayes.dart';
import 'package:veroapp_sms_guard/core/classifier/otp_detector.dart';
import 'package:veroapp_sms_guard/core/classifier/semantic_intent_engine.dart';
import 'package:veroapp_sms_guard/core/classifier/smart_classifier.dart';
import 'package:veroapp_sms_guard/core/classifier/threat_database.dart';
import 'package:veroapp_sms_guard/core/classifier/tokenizer.dart';
import 'package:veroapp_sms_guard/core/rules/rule_engine.dart';

void main() {
  group('Tokenizer & Anti-Evasion Tests', () {
    test('detects full URLs and shortened URLs', () {
      const text = 'Claim your prize at https://example.com/win and bit.ly/prize';
      final tokens = Tokenizer.features(text);

      expect(tokens.contains(Tokenizer.urlToken), isTrue);
      expect(tokens.contains(Tokenizer.shortUrlToken), isTrue);
    });

    test('categorizes numbers as codes (4-8 digits) or generic numbers', () {
      const text = 'Your code is 482913. Price was 250000000.';
      final tokens = Tokenizer.tokenize(text);

      expect(tokens.contains(Tokenizer.codeToken), isTrue);
      expect(tokens.contains(Tokenizer.numToken), isTrue);
    });

    test('extracts CJK character bigrams correctly', () {
      const text = '验证码输入';
      final tokens = Tokenizer.tokenize(text);

      expect(tokens.contains('验'), isTrue);
      expect(tokens.contains('证'), isTrue);
      expect(tokens.contains('验证'), isTrue);
      expect(tokens.contains('证码'), isTrue);
    });

    test('de-obfuscates spaced letters and leetspeak tokens', () {
      const text = 'Special B O N U S and f.r.e.e.s.p.i.n with b0nus!';
      final tokens = Tokenizer.features(text);

      expect(tokens.contains('bonus'), isTrue);
      expect(tokens.contains('freespin'), isTrue);
    });

    test('FAZ 2: cleans Homoglyph (Cyrillic/Greek/Full-width) attacks', () {
      // Cyrillic В, а, о, е, с + Greek Β, α, ο + Full-width ＢＯＮＵＳ
      const cyrillicText = 'В.а.h.!.s ve f*r*е*е*s*p*i*n ile сasino ＢＯＮＵＳ';
      expect(Tokenizer.hasHomoglyphAttack(cyrillicText), isTrue);

      final normalized = Tokenizer.normalizeObfuscation(cyrillicText);
      expect(normalized, contains('bahis'));
      expect(normalized, contains('freespin'));
      expect(normalized, contains('casino'));
      expect(normalized, contains('bonus'));

      final tokens = Tokenizer.features(cyrillicText);
      expect(tokens.contains(Tokenizer.homoglyphToken), isTrue);
      expect(tokens.contains(Tokenizer.obfuscatedToken), isTrue);
      expect(tokens.contains('bahis'), isTrue);
      expect(tokens.contains('freespin'), isTrue);
    });

    test('FAZ 2: cleans symbol & space injections (B.a.h.!.s, f*r*e*e*s*p*i*n, f r e e s p i n)', () {
      const obfuscated = 'Özel B.a.h.!.s f*r*e*e*s*p*i*n ve f r e e s p i n b@h!s fırsatı!';
      final normalized = Tokenizer.normalizeObfuscation(obfuscated);
      expect(normalized, contains('bahis'));
      expect(normalized, contains('freespin'));

      final tokens = Tokenizer.features(obfuscated);
      expect(tokens.contains('bahis'), isTrue);
      expect(tokens.contains('freespin'), isTrue);
    });

    test('FAZ 2: maps Turkish diacritics (ı,ş,ğ,ü,ö,ç -> i,s,g,u,o,c) seamlessly', () {
      const trText = 'Çevrimsiz hoşgeldin ödülü şansı ğüöçşı';
      final folded = Tokenizer.foldTurkishAscii(trText.toLowerCase());
      expect(folded, equals('cevrimsiz hosgeldin odulu sansi guocsi'));

      final tokens = Tokenizer.features('Çevrimsiz hoşgeldin');
      expect(tokens.contains('çevrimsiz'), isTrue);
      expect(tokens.contains('cevrimsiz'), isTrue);
      expect(tokens.contains('hoşgeldin'), isTrue);
      expect(tokens.contains('hosgeldin'), isTrue);
    });

    test('FAZ 2: BTK B-Code parser detects valid B-codes, fake B-code traps, and foreign senders', () {
      // 1. Valid B-Code at the end of the message
      final validBtk = Tokenizer.analyzeBtk(
        'Mağazamızda %50 indirim fırsatı! MERSIS: 0123456789012345 Ret: İPTAL B002',
        sender: 'MAGAZA',
      );
      expect(validBtk.hasValidBCode, isTrue);
      expect(validBtk.bCode, equals('B002'));
      expect(validBtk.hasMersis, isTrue);
      expect(validBtk.hasFakeBCodeTrap, isFalse);

      // 2. Fake B-Code trap ("B.0.0.1" and "B O O 1")
      final fakeBtk1 = Tokenizer.analyzeBtk('1000 TL deneme bonusu aktif! B.0.0.1');
      expect(fakeBtk1.hasFakeBCodeTrap, isTrue);

      final fakeBtk2 = Tokenizer.analyzeBtk('Yatırımsız şans için tıkla B O O 1');
      expect(fakeBtk2.hasFakeBCodeTrap, isTrue);

      // 3. Mid-message B-Code injection trap followed by URL
      final midBtk = Tokenizer.analyzeBtk(
        'Kampanya B001 kodu ile hemen kazanmak için http://bet-bonus.xyz adresine girin!',
      );
      expect(midBtk.hasFakeBCodeTrap, isTrue);
      expect(midBtk.hasValidBCode, isFalse);

      // 4. Foreign sender without BTK B-Code (+63 Philippines, +62 Indonesia)
      final foreignBtk = Tokenizer.analyzeBtk(
        'Merhaba, uzaktan çalışma fırsatı için WhatsApp hattımıza yazın.',
        sender: '+639171234567',
      );
      expect(foreignBtk.isForeignSender, isTrue);
      expect(foreignBtk.foreignCountryCode, equals('+63'));
      expect(foreignBtk.isForeignSenderWithoutBCode, isTrue);

      // 5. Domestic Turkish sender (+90) is not flagged as foreign
      final trBtk = Tokenizer.analyzeBtk(
        'Akşam eve gelirken ekmek alır mısın?',
        sender: '+905321234567',
      );
      expect(trBtk.isForeignSender, isFalse);
      expect(trBtk.isForeignSenderWithoutBCode, isFalse);
    });
  });

  group('NaiveBayesModel Tests', () {
    late NaiveBayesModel model;

    setUp(() {
      model = NaiveBayesModel();
      model.train('win free cash lottery prize', MessageCategory.spam);
      model.train('urgent account suspended verify link', MessageCategory.spam);
      model.train('hey are we having lunch tomorrow', MessageCategory.normal);
      model.train('mom asked if you can buy milk', MessageCategory.normal);
      model.train('your verification code is 123456', MessageCategory.transaction);
    });

    test('classifies spam and ham accurately on trained vocabulary', () {
      final spamPred = model.predict('free cash lottery');
      expect(spamPred[MessageCategory.spam]!, greaterThan(spamPred[MessageCategory.normal]!));

      final hamPred = model.predict('lunch tomorrow with mom');
      expect(hamPred[MessageCategory.normal]!, greaterThan(hamPred[MessageCategory.spam]!));
    });

    test('serializes and deserializes correctly via JSON', () {
      final json = model.toJson();
      final restored = NaiveBayesModel.fromJson(json);

      expect(restored.vocabularySize, equals(model.vocabularySize));
      expect(restored.documentCount, equals(model.documentCount));

      final pred1 = model.predict('free cash');
      final pred2 = restored.predict('free cash');
      expect(pred1[MessageCategory.spam], closeTo(pred2[MessageCategory.spam]!, 0.001));
    });

    test('exports spam weights correctly for native background engine', () {
      final weights = model.exportSpamWeights(limit: 10);
      expect(weights.isNotEmpty, isTrue);
      expect(weights.containsKey('cash') || weights.containsKey('free') || weights.containsKey('lottery'), isTrue);
    });
  });

  group('OtpDetector Tests (Multilingual & Code Extraction)', () {
    test('detects English OTPs and extracts verification code', () {
      final res = OtpDetector.analyze('Your verification code is 884129. Do not share.');
      expect(res.isTransaction, isTrue);
      expect(res.score, greaterThanOrEqualTo(0.85));
      expect(res.extractedCode, equals('884129'));
    });

    test('detects Turkish OTPs and transactions', () {
      final otp = OtpDetector.analyze('Giriş için onay kodunuz: 551209. Şifre 3 dk geçerlidir.');
      expect(otp.isTransaction, isTrue);
      expect(otp.extractedCode, equals('551209'));

      final txn = OtpDetector.analyze('4421 ile biten kartınızdan 250,00 TL harcama yapılmıştır.');
      expect(txn.isTransaction, isTrue);
    });

    test('detects Spanish and German OTPs', () {
      final es = OtpDetector.analyze('Tu código de verificación es 991823.');
      expect(es.isTransaction, isTrue);

      final de = OtpDetector.analyze('Ihr Bestätigungscode lautet 394812.');
      expect(de.isTransaction, isTrue);
    });

    test('detects Chinese and Arabic OTPs', () {
      final zh = OtpDetector.analyze('您的动态密码为 482913，请在5分钟内输入。');
      expect(zh.isTransaction, isTrue);

      final ar = OtpDetector.analyze('رمز التحقق الخاص بك هو 902114.');
      expect(ar.isTransaction, isTrue);
    });

    test('does not misclassify casual messages with words like pin or balance', () {
      final casual = OtpDetector.analyze('I lost my bowling pin yesterday, let us play again.');
      expect(casual.isTransaction, isFalse);
    });
  });

  group('RuleEngine Tests', () {
    test('keyword rules match substring case-insensitively by default', () {
      final rule = FilterRule(
        id: '1',
        name: 'Casino Block',
        pattern: 'casino, slot, bet',
        action: MessageCategory.spam,
      );
      expect(rule.matches('Join our new CASINO table now!'), isTrue);
      expect(rule.matches('Hello friend, how are you?'), isFalse);
    });

    test('regex rules match complex patterns including inline (?i) flag', () {
      final rule = FilterRule(
        id: '2',
        name: 'Urgent Alert Block',
        pattern: r'(?i)(urgent|acil).*(verify|hesap|dogrula)',
        type: RuleType.regex,
        action: MessageCategory.spam,
      );
      expect(rule.matches('URGENT: Please verify your bank account'), isTrue);
      expect(rule.matches('ACİL: banka hesap bilgilerinizi doğrulayın'), isTrue);
      expect(rule.matches('This is a normal friendly letter'), isFalse);
    });

    test('supports Sender vs Body rule targeting', () {
      final senderRule = FilterRule(
        id: 's1',
        name: 'Block 0850 Numbers',
        pattern: '+90850',
        target: RuleTarget.sender,
        action: MessageCategory.spam,
      );
      expect(senderRule.matches('Merhaba nasılsınız', sender: '+908501234567'), isTrue);
      expect(senderRule.matches('Numaram +908501234567', sender: 'Arkadaşım'), isFalse);
    });

    test('rule engine respects rule order (first match wins)', () {
      final allowRule = FilterRule(
        id: 'allow-1',
        name: 'My Bank Allow',
        pattern: 'Garanti BBVA',
        action: MessageCategory.normal,
      );
      final blockRule = FilterRule(
        id: 'block-1',
        name: 'Block Loans',
        pattern: 'kredi, kampanya',
        action: MessageCategory.spam,
      );

      final engine = RuleEngine([allowRule, blockRule]);
      final match = engine.firstMatch('Garanti BBVA kampanya kredisi hakkında bilgilendirme');
      expect(match, isNotNull);
      expect(match!.action, equals(MessageCategory.normal));
    });
  });

  group('ThreatDatabase & SmartClassifier Full Pipeline Tests', () {
    late SmartClassifier classifier;

    setUp(() {
      final model = NaiveBayesModel();
      model.train('win free cash lottery prize reward', MessageCategory.spam);
      model.train('urgent account suspended verify immediately', MessageCategory.spam);
      model.train('are we still meeting for lunch today', MessageCategory.normal);
      model.train('your verification code is 482913', MessageCategory.transaction);

      final rule = FilterRule(
        id: 'rule-vip',
        name: 'VIP Boss Rule',
        pattern: 'CEO Office',
        action: MessageCategory.normal,
      );

      classifier = SmartClassifier(model: model, rules: RuleEngine([rule]));
    });

    test('user rule overrides everything', () {
      final res = classifier.classify('Message from CEO Office: urgent verify link lottery');
      expect(res.category, equals(MessageCategory.normal));
      expect(res.source, equals(DecisionSource.userRule));
      expect(res.ruleName, equals('VIP Boss Rule'));
    });

    test('OTP messages without suspicious links are classified as transaction', () {
      final res = classifier.classify('Your verification code is 482913. Do not share.');
      expect(res.category, equals(MessageCategory.transaction));
      expect(res.source, equals(DecisionSource.otpDetector));
      expect(res.otpCode, equals('482913'));
    });

    test('phishing messages claiming to be OTP but containing links get evaluated by AI/heuristic', () {
      final res = classifier.classify('Your verification code is 482913. Verify at bit.ly/fake');
      expect(res.category, equals(MessageCategory.spam));
    });

    test('ThreatDatabase catches Turkish betting & fake legal/icra scams', () {
      final betting = classifier.classify(
        'Hesabınıza 1000 TL çevrimsiz deneme bonusu ve 250 freespin tanımlandı!',
      );
      expect(betting.category, equals(MessageCategory.spam));
      expect(betting.subCategory, equals(MessageSubCategory.bettingGambling));

      final icra = classifier.classify(
        'Sayın ilgili, hakkınızda açılmış uzlaştırma dosyası bulunmaktadır. Son gün bugün.',
      );
      expect(icra.category, equals(MessageCategory.spam));
      expect(icra.subCategory, equals(MessageSubCategory.governmentScam));
    });

    test('Marketing shield can be toggled on to block MERSIS / B-code messages', () {
      classifier.shieldConfig = const ThreatShieldConfig(marketingShield: true);
      final promo = classifier.classify(
        'Büyük indirim başladı! İptal için RET yaz gönder MERSIS: 012345 B002',
      );
      expect(promo.category, equals(MessageCategory.spam));
      expect(promo.subCategory, equals(MessageSubCategory.marketingPromotion));
    });

    test('FAZ 2: SmartClassifier catches obfuscated B.a.h.!.s, Fake B-Code, and +63 Foreign Spam', () {
      // 1. Obfuscated Cyrillic + Symbol betting SMS
      final obfBet = classifier.classify(
        'Hesabınıza 500 TL В.а.h.!.s ve f*r*e*e*s*p*i*n b.o.n.u.s tanımlandı!',
      );
      expect(obfBet.category, equals(MessageCategory.spam));
      expect(obfBet.subCategory, equals(MessageSubCategory.bettingGambling));
      expect(obfBet.signals, contains('signalHomoglyphAttack'));
      expect(obfBet.signals, contains('signalObfuscatedText'));

      // 2. Spoofed B-Code trap ("B.0.0.1")
      final fakeBCodeRes = classifier.classify(
        'Hemen özel ödülünüzü talep edin B.0.0.1',
      );
      expect(fakeBCodeRes.category, equals(MessageCategory.spam));
      expect(fakeBCodeRes.signals, contains('signalFakeBCode'));

      // 3. Unknown foreign number (+63) without BTK B-Code
      final foreignRes = classifier.classify(
        'Günlük 3500 TL kazanç için mesaj atın',
        sender: '+639159876543',
      );
      expect(foreignRes.category, equals(MessageCategory.spam));
      expect(foreignRes.signals, contains('signalForeignNoBCode'));
    });

    test('FAZ 3.1: 6D Intent Vector detects Urgency/Fear in fake icra & court threats', () {
      final intent = SemanticIntentEngine.analyze(
        'Sayın ilgili, hakkınızda açılmış icra dosyası ve haciz işlemi için son 24 saat!',
      );
      expect(intent.vector.urgencyFear, greaterThanOrEqualTo(0.40));
      expect(intent.whyReasons, contains('whyUrgencyFear'));
    });

    test('FAZ 3.2: 6D Intent Vector detects Financial Trap in easy-money / loan / customs smishing', () {
      final intent = SemanticIntentEngine.analyze(
        'Evden çalışarak günlük kazanç ve kefilsiz masrafsız kredi fırsatı!',
      );
      expect(intent.vector.financialTrap, greaterThanOrEqualTo(0.40));
      expect(intent.whyReasons, contains('whyFinancialTrap'));
    });

    test('FAZ 3.3: 6D Intent Vector detects Reward/Betting in obfuscated casino messages', () {
      final intent = SemanticIntentEngine.analyze(
        'Tebrikler! 500 TL ç.e.v.r.i.m.s.i.z b.o.n.u.s ve f*r*e*e*s*p*i*n kazandınız!',
      );
      expect(intent.vector.rewardBetting, greaterThanOrEqualTo(0.40));
      expect(intent.whyReasons, contains('whyRewardBetting'));
      expect(intent.whyReasons, contains('whyHomoglyphObfuscation'));
    });

    test('FAZ 3.4: 6D Intent Vector detects Action/Link redirection and shortened URLs', () {
      final intent = SemanticIntentEngine.analyze(
        'Hediyenizi aktif etmek için hemen tıklayın ve giriş yapın: bit.ly/hediye99',
      );
      expect(intent.vector.actionLink, greaterThanOrEqualTo(0.50));
      expect(intent.whyReasons, contains('whyActionLink'));
    });

    test('FAZ 3.5: 6D Intent Vector detects Corporate/OTP in legitimate banking SMS', () {
      final intent = SemanticIntentEngine.analyze(
        'Garanti BBVA Mobil giriş için tek kullanımlık doğrulama kodunuz: 849201. Kimseyle paylaşmayın. B002',
        sender: 'GARANTI',
      );
      expect(intent.vector.corporateOtp, greaterThanOrEqualTo(0.60));
      expect(intent.dominantCategory, equals(MessageCategory.transaction));
      expect(intent.whyReasons, contains('whyOtpFastPath'));
    });

    test('FAZ 3.6: 6D Intent Vector recognizes "Dükkan & Hakan Abi" personal chat context', () {
      final intent = SemanticIntentEngine.analyze(
        'Hakan abi emaneti dükkana bıraktım, akşam eve gelirken uğrar mısın?',
        sender: '+905321112233',
      );
      expect(intent.vector.personalChat, greaterThanOrEqualTo(0.50));
      expect(intent.dominantCategory, equals(MessageCategory.normal));
      expect(intent.whyReasons, contains('whyPersonalChatContext'));
    });

    test('FAZ 3.7: Character 3-gram & 4-gram analyzer catches disguised brand+number patterns', () {
      final risk = SemanticIntentEngine.evaluateNgramRisk(
        'yeni adresimiz casibom784 ve jojobet912 uzerinden aktif',
        hasUrl: true,
      );
      expect(risk, greaterThanOrEqualTo(0.45));
    });

    test('FAZ 3.8: Dynamic Combo Boost multiplies score when Reward + Link + Urgency combine', () {
      final single = SemanticIntentEngine.analyze('Bedava bonus fırsatı');
      final combo = SemanticIntentEngine.analyze(
        'Son 24 saat! 1000 TL bedava bonus kazandınız, hemen tıklayın: bit.ly/bonus24',
      );
      expect(combo.comboMultiplier, greaterThan(1.4));
      expect(combo.spamIntentScore, greaterThan(single.spamIntentScore));
      expect(combo.whyReasons, contains('whyComboRewardLink'));
    });

    test('FAZ 3.9: SmartClassifier classifies friendly "Hakan Abi / Dükkan" message as Normal with high confidence', () {
      final res = classifier.classify(
        'Hakan abi emaneti dükkana bıraktım, çay demledim müsait olunca uğra.',
        sender: 'Mehmet Usta',
      );
      expect(res.category, equals(MessageCategory.normal));
      expect(res.subCategory, equals(MessageSubCategory.personal));
      expect(res.whyReasons, contains('whyPersonalChatContext'));
      expect(res.intentVector, isNotNull);
    });

    test('FAZ 3.10: SmartClassifier classifies legitimate cargo delivery code SMS as Transaction', () {
      final res = classifier.classify(
        'Yurtiçi Kargo: Gönderiniz dağıtıma çıkmıştır. Tek kullanımlık teslimat doğrulama kodunuz: 4829. B002',
        sender: 'YURTICI',
      );
      expect(res.category, equals(MessageCategory.transaction));
      expect(res.otpCode, equals('4829'));
    });

    test('FAZ 3.11: SmartClassifier blocks fake PTT/DHL customs fee smishing with X-Ray reasons', () {
      final res = classifier.classify(
        'PTT Kargo: Paketiniz gümrük ücreti ödenmediği için bekletiliyor. Hemen tıklayın: ptt-gumruk.xyz',
      );
      expect(res.category, equals(MessageCategory.spam));
      expect(res.subCategory, equals(MessageSubCategory.deliveryCustomsScam));
      expect(res.whyReasons, isNotEmpty);
    });

    test('FAZ 3.12: SmartClassifier blocks semantic financial/job scam even without classic betting words', () {
      final res = classifier.classify(
        'Son gün! Evden çalışarak günlük kazanç ve yatırım fırsatı için hemen bağlantıya tıklayın: bit.ly/kazanc2026',
      );
      expect(res.category, equals(MessageCategory.spam));
      expect(res.whyReasons, contains('whyFinancialTrap'));
      expect(res.whyReasons, contains('whyActionLink'));
    });

    test('FAZ 3.13: SmartClassifier exposes pipeline stageBreakdown for X-Ray inspection', () {
      final res = classifier.classify(
        'В.а.h.!.s 1000 TL deneme bonusu için tıkla: bit.ly/win B.0.0.1',
      );
      expect(res.stageBreakdown, isNotEmpty);
      expect(res.stageBreakdown['stageNormalization'], greaterThan(0.5));
      expect(res.stageBreakdown['stageBtkCheck'], greaterThan(0.5));
      expect(res.stageBreakdown['stageSemanticIntent'], greaterThan(0.5));
    });

    test('FAZ 3.14: NativeBridge hardware accelerator degrades gracefully without crashing', () async {
      final intent = SemanticIntentEngine.analyze('Normal test message');
      expect(intent.probabilities.length, equals(3));
    });

    test('FAZ 3.15: IntentVector serializes and deserializes cleanly for History persistence', () {
      const vec = IntentVector(
        urgencyFear: 0.8,
        financialTrap: 0.4,
        rewardBetting: 0.9,
        actionLink: 0.7,
        corporateOtp: 0.0,
        personalChat: 0.1,
      );
      final restored = IntentVector.fromMap(vec.toMap());
      expect(restored.urgencyFear, closeTo(0.8, 0.001));
      expect(restored.rewardBetting, closeTo(0.9, 0.001));
    });
  });
}
