/// Multilingual detector for one-time passwords and banking transaction
/// notices. Keyword lists are exported to the native filters as well.
library;

import 'classification.dart';

class OtpAnalysis {
  const OtpAnalysis({
    required this.isTransaction,
    required this.score,
    this.extractedCode,
    this.subCategory,
  });

  final bool isTransaction;
  final double score;
  final String? extractedCode;
  final MessageSubCategory? subCategory;

  static const none = OtpAnalysis(isTransaction: false, score: 0);
}

class OtpDetector {
  OtpDetector._();

  /// Words that indicate a verification / one-time code (10 languages).
  static const List<String> otpKeywords = [
    // en
    'code', 'otp', 'verification', 'verify code', 'password', 'passcode', 'pin', 'one-time',
    // tr
    'kod', 'kodunuz', 'şifre', 'şifreniz', 'doğrulama', 'onay kodu', 'tek kullanımlık',
    // es / pt
    'código', 'clave', 'contraseña', 'senha', 'verificação', 'verificación',
    // de
    'bestätigungscode', 'tan', 'einmalcode', 'passwort',
    // fr / it
    'mot de passe', 'codice', 'usage unique', 'monouso',
    // ru
    'код', 'пароль', 'одноразовый',
    // zh
    '验证码', '动态密码', '校验码', '确认码',
    // ar
    'رمز', 'كلمة المرور', 'رمز التحقق',
  ];

  /// Words that indicate a bank/card transaction notice.
  static const List<String> transactionKeywords = [
    'charged', 'balance', 'transaction', 'debited', 'credited', 'payment of',
    'harcama', 'bakiye', 'limit', 'havale', 'eft', 'fast işlemi', 'ekstre',
    'saldo', 'compra de', 'cartão final', 'tarjeta terminada',
    'kartenzahlung', 'überweisung',
    'solde', 'paiement de', 'pagamento di',
    'покупка', 'баланс', 'доступно', 'по карте',
    '余额', '消费', '尾号',
    'الرصيد', 'تم خصم', 'بطاقتك',
  ];

  /// Keywords in CJK / Arabic scripts are matched as substrings (no spaces,
  /// attached prefixes). All other scripts require word boundaries so that
  /// e.g. "pin" does not match "shopping".
  static bool usesSubstringMatch(String keyword) => keyword.runes.any(
        (r) => (r >= 0x4E00 && r <= 0x9FFF) || (r >= 0x0600 && r <= 0x06FF),
      );

  static final Map<String, RegExp> _keywordCache = {};

  static bool containsKeyword(String lowerText, String keyword) {
    if (usesSubstringMatch(keyword)) return lowerText.contains(keyword);
    final re = _keywordCache.putIfAbsent(
      keyword,
      () => RegExp(
        '(?<![\\p{L}\\p{N}])${RegExp.escape(keyword)}(?![\\p{L}\\p{N}])',
        unicode: true,
      ),
    );
    return re.hasMatch(lowerText);
  }

  static final RegExp _code = RegExp(
    r'(?<!\p{Nd})(?:[a-z]-)?\p{Nd}{4,8}(?!\p{Nd})',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _amount = RegExp(r'\p{Nd}+(?:[.,]\p{Nd}+)?', unicode: true);

  /// Extracts the first 4–8 digit verification code (e.g. "482913" or "G-583920")
  /// when present.
  static String? extractCode(String text) {
    final m = _code.firstMatch(text);
    return m?.group(0);
  }

  static OtpAnalysis analyze(String text) {
    final lower = text.toLowerCase();
    final hasOtpKeyword = otpKeywords.any((k) => containsKeyword(lower, k));
    final codeMatch = _code.firstMatch(text);
    if (hasOtpKeyword && codeMatch != null) {
      return OtpAnalysis(
        isTransaction: true,
        score: 0.95,
        extractedCode: codeMatch.group(0),
        subCategory: MessageSubCategory.otpCode,
      );
    }
    final hasTxnKeyword =
        transactionKeywords.any((k) => containsKeyword(lower, k));
    if (hasTxnKeyword && _amount.hasMatch(lower)) {
      return const OtpAnalysis(
        isTransaction: true,
        score: 0.85,
        subCategory: MessageSubCategory.bankTransaction,
      );
    }
    return OtpAnalysis.none;
  }
}
