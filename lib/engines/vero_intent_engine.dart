/// VeroApp 2025 Turkey Fraud Intent Engine.
///
/// Implements 10 specialized 2025 fraud attack signatures,
/// Cyrillic/homoglyph de-obfuscation, BTK B001-B015 operator code parsing,
/// and 6-dimensional semantic intent vector weighting.
library;

import '../core/classifier/semantic_intent_engine.dart';

/// 10 Specialized 2025 Türkiye Fraud Categories.
enum FraudType2025 {
  tapuDevir,
  sgkPrim,
  vergiHaciz,
  eDevletDava,
  kuryeTeslimat,
  kartBloke,
  hediyeCeki,
  abonelikAskiya,
  mahkemeIcra,
  faturaKesinti,
}

extension FraudType2025Ext on FraudType2025 {
  String get titleTr => switch (this) {
        FraudType2025.tapuDevir => 'Tapu Devir Dolandırıcılığı',
        FraudType2025.sgkPrim => 'SGK Prim Borcu / İadesi Tuzağı',
        FraudType2025.vergiHaciz => 'Vergi Dairesi / Haciz Bildirimi',
        FraudType2025.eDevletDava => 'Sahte e-Devlet Dava / Tebligat Bildirimi',
        FraudType2025.kuryeTeslimat => 'Kurye / Kargo Teslimat Ücreti Tuzağı',
        FraudType2025.kartBloke => 'Banka Kart Bloke / Dondurma Blöfü',
        FraudType2025.hediyeCeki => 'Sahte Hediye Çeki / Çekiliş Tuzağı',
        FraudType2025.abonelikAskiya => 'Abonelik Yenileme / Askıya Alma Tuzağı',
        FraudType2025.mahkemeIcra => 'Sahte Mahkeme / İcra Celbi',
        FraudType2025.faturaKesinti => 'Elektrik / Doğalgaz Kesme İhbarı',
      };
}

/// Result of 2025 fraud pattern recognition.
class FraudPatternResult {
  const FraudPatternResult({
    required this.isFraud,
    this.type,
    required this.confidence,
    required this.bCode,
    required this.operatorName,
    required this.homoglyphsFound,
    required this.vector,
    required this.matchedKeywords,
    required this.riskExplanation,
  });

  final bool isFraud;
  final FraudType2025? type;
  final double confidence; // 0.0 to 1.0
  final String? bCode;
  final String? operatorName;
  final List<String> homoglyphsFound;
  final IntentVector vector;
  final List<String> matchedKeywords;
  final String riskExplanation;

  String? get typeTitle => type?.titleTr;

  static const clean = FraudPatternResult(
    isFraud: false,
    confidence: 0,
    bCode: null,
    operatorName: null,
    homoglyphsFound: [],
    vector: IntentVector.zero,
    matchedKeywords: [],
    riskExplanation: 'Tehdit tespit edilmedi',
  );
}

/// Engine that recognizes modern 2025 Türkiye SMS and messaging fraud patterns.
class VeroIntentEngine {
  VeroIntentEngine._();
  static final VeroIntentEngine instance = VeroIntentEngine._();

  static const Map<String, String> _btkOperators = {
    'B001': 'TT Mobil İletişim Hizmetleri A.Ş.',
    'B002': 'Turkcell İletişim Hizmetleri A.Ş.',
    'B003': 'Vodafone Telekomünikasyon A.Ş.',
    'B004': 'Türk Telekomünikasyon A.Ş.',
    'B005': 'Netgsm İletişim ve Bilgi Teknolojileri A.Ş.',
    'B006': 'Türk Telekom Sabit',
    'B007': 'Millenicom Telekomünikasyon Hizmetleri A.Ş.',
    'B008': 'Superonline İletişim Hizmetleri A.Ş.',
    'B009': 'Doruk İletişim ve Otomasyon San. ve Tic. A.Ş.',
    'B010': 'Vodafone Net İletişim Hizmetleri A.Ş.',
    'B011': 'İşNet Elektronik Bilgi Üretim Dağıtım Tic. A.Ş.',
    'B012': 'İletişim Makinesi',
    'B013': 'Hermes İletişim Danışmanlık',
    'B014': 'Verimor Telekomünikasyon A.Ş.',
    'B015': 'Mutlucell İletişim Hizmetleri A.Ş.',
  };

  static const Map<String, String> _homoglyphs = {
    'а': 'a', // Cyrillic small a
    'е': 'e', // Cyrillic small e
    'о': 'o', // Cyrillic small o
    'р': 'p', // Cyrillic small p
    'с': 'c', // Cyrillic small c
    'у': 'y', // Cyrillic small y
    'х': 'x', // Cyrillic small x
    'і': 'i', // Cyrillic small i
    'А': 'A', // Cyrillic cap A
    'В': 'B', // Cyrillic cap B
    'Е': 'E', // Cyrillic cap E
    'К': 'K', // Cyrillic cap K
    'М': 'M', // Cyrillic cap M
    'Н': 'H', // Cyrillic cap H
    'О': 'O', // Cyrillic cap O
    'Р': 'P', // Cyrillic cap P
    'С': 'C', // Cyrillic cap C
    'Т': 'T', // Cyrillic cap T
    'Х': 'X', // Cyrillic cap X
  };

  static final RegExp _bCodeRegex = RegExp(r'\b(B0[0-1][0-9])\b', caseSensitive: false);

  /// De-obfuscate text by normalizing Cyrillic/Greek homoglyphs to Latin equivalents.
  String normalizeHomoglyphs(String text, List<String> outFound) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (_homoglyphs.containsKey(char)) {
        outFound.add(char);
        buffer.write(_homoglyphs[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String toDeaccented(String s) {
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  /// Analyze text for 2025 fraud patterns.
  FraudPatternResult analyze(String rawText, {String? sender}) {
    final homoglyphsFound = <String>[];
    final normalized = normalizeHomoglyphs(rawText, homoglyphsFound);
    final deaccented = toDeaccented(normalized);
    final senderDeaccented = toDeaccented(sender ?? '');
    final combined = '$senderDeaccented $deaccented';

    // 1. Detect BTK Operator Code
    String? bCode;
    String? operatorName;
    final bMatch = _bCodeRegex.firstMatch(rawText);
    if (bMatch != null) {
      bCode = bMatch.group(1)?.toUpperCase();
      if (bCode != null && _btkOperators.containsKey(bCode)) {
        operatorName = _btkOperators[bCode];
      }
    }

    // 2. Pattern Matching against 10 modern fraud types
    FraudType2025? detectedType;
    final matchedKeywords = <String>[];
    var maxConfidence = 0.0;
    String explanation = '';

    // Pattern 1: Tapu Devir
    if (_matchesPattern(combined, [
      ['tapu', 'harc'],
      ['tapu', 'devir'],
      ['kadastro', 'odeme'],
      ['tapu', 'eksik'],
    ])) {
      detectedType = FraudType2025.tapuDevir;
      matchedKeywords.addAll(['tapu', 'harç', 'devir']);
      maxConfidence = 0.94;
      explanation = 'Sahte tapu harcı ve devir ödemesi tuzağı tespit edildi.';
    }
    // Pattern 2: SGK Prim Borcu / İadesi
    else if (_matchesPattern(combined, [
      ['sgk', 'prim', 'iade'],
      ['sgk', 'borc'],
      ['sosyal guvenlik', 'odeme'],
      ['sgk', 'prim', 'hazir'],
      ['sgk', 'prim'],
    ])) {
      detectedType = FraudType2025.sgkPrim;
      matchedKeywords.addAll(['sgk', 'prim iadesi', 'borç']);
      maxConfidence = 0.95;
      explanation = 'Sahte SGK prim iadesi veya asılsız borç tuzağı tespit edildi.';
    }
    // Pattern 3: Vergi Borcu / Haciz
    else if (_matchesPattern(combined, [
      ['vergi', 'haciz'],
      ['vergi borc', 'haciz'],
      ['gib', 'haciz'],
      ['hesabiniza haciz'],
      ['hesaplariniza haciz'],
    ])) {
      detectedType = FraudType2025.vergiHaciz;
      matchedKeywords.addAll(['vergi borcu', 'haciz bildirimi']);
      maxConfidence = 0.96;
      explanation = 'Asılsız vergi dairesi haciz bildirimi ile korku yaratma tuzağı.';
    }
    // Pattern 4: e-Devlet Kapısı Sahte Dava Bildirimi
    else if (_matchesPattern(combined, [
      ['e-devlet', 'dava'],
      ['edevlet', 'dava'],
      ['dava dosya'],
      ['sorusturma', 'dosya'],
      ['e-devlet', 'ceza'],
    ])) {
      detectedType = FraudType2025.eDevletDava;
      matchedKeywords.addAll(['e-devlet', 'adınıza dava', 'tebligat']);
      maxConfidence = 0.95;
      explanation = 'Sahte e-Devlet dava/soruşturma celbi ile linke tıklatma tuzağı.';
    }
    // Pattern 5: Kurye Teslimat Ücreti Tuzağı
    else if (_matchesPattern(combined, [
      ['teslim', 'edilemed'],
      ['teslimat', 'ucret'],
      ['kurye', 'tl'],
      ['adres', 'guncelle'],
      ['kargo', 'ucret'],
    ])) {
      detectedType = FraudType2025.kuryeTeslimat;
      matchedKeywords.addAll(['kargo teslim edilemedi', 'teslimat ücreti']);
      maxConfidence = 0.92;
      explanation = 'Küçük tutarlı teslimat ücreti bahanesiyle kredi kartı çalma tuzağı.';
    }
    // Pattern 6: Banka Kart Bloke Blöfü
    else if (_matchesPattern(combined, [
      ['kart', 'supheli'],
      ['kart', 'bloke'],
      ['donduruldu'],
      ['hesap', 'donduruldu'],
      ['guvenlik', 'bloke'],
      ['kart', 'askiya'],
    ])) {
      detectedType = FraudType2025.kartBloke;
      matchedKeywords.addAll(['kart şüpheli işlem', 'bloke blöfü']);
      maxConfidence = 0.97;
      explanation = 'Sahte kart bloke blöfü ile acil şifre/kart bilgisi ele geçirme tuzağı.';
    }
    // Pattern 7: Hediye Çeki / Çekiliş
    else if (_matchesPattern(combined, [
      ['hediye cek', 'kazan'],
      ['tl', 'kazan'],
      ['cekilis', 'odul'],
      ['tebrik', 'hediye'],
    ])) {
      detectedType = FraudType2025.hediyeCeki;
      matchedKeywords.addAll(['hediye çeki', 'kazandınız']);
      maxConfidence = 0.93;
      explanation = 'Ödül/çekiliş vaadiyle sahte siteye yönlendirme tuzağı.';
    }
    // Pattern 8: Abonelik Yenileme / Askıya Alındı
    else if (_matchesPattern(combined, [
      ['netflix', 'askiya'],
      ['amazon', 'askiya'],
      ['abonelik', 'askiya'],
      ['abonelik', 'sonlandir'],
      ['uyelik', 'yenile'],
    ])) {
      detectedType = FraudType2025.abonelikAskiya;
      matchedKeywords.addAll(['abonelik askıya alındı', 'üyelik yenileme']);
      maxConfidence = 0.91;
      explanation = 'Popüler servis aboneliği askıya alındı yalanıyla kimlik avı.';
    }
    // Pattern 9: Mahkeme / İcra Celbi
    else if (_matchesPattern(combined, [
      ['icra', 'takib'],
      ['icra', 'daire'],
      ['uzlasma', 'dosya'],
      ['hukuk', 'buro'],
      ['icra'],
    ])) {
      detectedType = FraudType2025.mahkemeIcra;
      matchedKeywords.addAll(['icra takibi', 'dosya no', 'hukuk bürosu']);
      maxConfidence = 0.98;
      explanation = 'Sahte icra ve uzlaşma dosyası korkutmasıyla para koparma tuzağı.';
    }
    // Pattern 10: Fatura Kesinti İhbarı
    else if (_matchesPattern(combined, [
      ['fatura', 'odenmed'],
      ['elektrik', 'kesme'],
      ['dogalgaz', 'kesme'],
      ['enerji', 'kesinti'],
      ['hizmet', 'durdur'],
    ])) {
      detectedType = FraudType2025.faturaKesinti;
      matchedKeywords.addAll(['fatura ödenmedi', 'kesme ihbarı']);
      maxConfidence = 0.93;
      explanation = 'Sahte fatura kesinti tehdidi ile acil ödeme linkine yönlendirme.';
    }

    // 3. Compute 6D Intent Vector
    var urgencyFear = 0.0;
    var financialTrap = 0.0;
    var rewardBetting = 0.0;
    var actionLink = 0.0;
    var corporateOtp = 0.0;
    var personalChat = 0.0;

    if (detectedType != null) {
      switch (detectedType) {
        case FraudType2025.vergiHaciz:
        case FraudType2025.mahkemeIcra:
        case FraudType2025.kartBloke:
        case FraudType2025.faturaKesinti:
          urgencyFear = 0.95;
          financialTrap = 0.85;
          actionLink = normalized.contains('http') || normalized.contains('.com') ? 0.90 : 0.40;
          break;
        case FraudType2025.sgkPrim:
        case FraudType2025.hediyeCeki:
          rewardBetting = 0.80;
          financialTrap = 0.85;
          actionLink = 0.85;
          break;
        case FraudType2025.tapuDevir:
        case FraudType2025.kuryeTeslimat:
        case FraudType2025.abonelikAskiya:
        case FraudType2025.eDevletDava:
          urgencyFear = 0.80;
          financialTrap = 0.80;
          actionLink = 0.90;
          break;
      }
    } else {
      // Generic semantic scoring if not recognized as specific 2025 fraud
      if (normalized.contains('dükkan') || normalized.contains('abi') || normalized.contains('merhaba')) {
        personalChat = 0.85;
      }
    }

    // Bonus penalty if homoglyphs are detected in suspicious context
    if (homoglyphsFound.isNotEmpty && detectedType != null) {
      maxConfidence = (maxConfidence + 0.05).clamp(0.0, 1.0);
      explanation += ' (Karakter gizleme / Homoglyph saldırısı tespit edildi!)';
    }

    final vector = IntentVector(
      urgencyFear: urgencyFear,
      financialTrap: financialTrap,
      rewardBetting: rewardBetting,
      actionLink: actionLink,
      corporateOtp: corporateOtp,
      personalChat: personalChat,
    );

    if (detectedType == null) {
      return FraudPatternResult(
        isFraud: false,
        type: null,
        confidence: 0.0,
        bCode: bCode,
        operatorName: operatorName,
        homoglyphsFound: homoglyphsFound,
        vector: vector,
        matchedKeywords: [],
        riskExplanation: 'Normal ileti',
      );
    }

    return FraudPatternResult(
      isFraud: true,
      type: detectedType,
      confidence: maxConfidence,
      bCode: bCode,
      operatorName: operatorName,
      homoglyphsFound: homoglyphsFound,
      vector: vector,
      matchedKeywords: matchedKeywords,
      riskExplanation: explanation,
    );
  }

  bool _matchesPattern(String text, List<List<String>> keywordGroups) {
    for (final group in keywordGroups) {
      var allPresent = true;
      for (final kw in group) {
        if (!text.contains(kw)) {
          allPresent = false;
          break;
        }
      }
      if (allPresent) return true;
    }
    return false;
  }
}
