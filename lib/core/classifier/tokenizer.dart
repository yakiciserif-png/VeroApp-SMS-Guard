/// Language-agnostic tokenizer, Homoglyph/Leetspeak de-obfuscator, Turkish
/// ASCII folder, and BTK B-Code / Sender Header parser used by the on-device
/// AI agent.
///
/// IMPORTANT (Triple-Mirror Pattern):
/// The Kotlin (`TrustFilterEngine.kt`) and Swift (`TrustFilterEngine.swift`)
/// native engines mirror this normalization and parsing pipeline so that
/// real-time background filtering produces identical decisions offline.
library;

/// Result of BTK B-Code, MERSİS, and Sender Header analysis.
class BtkAnalysis {
  const BtkAnalysis({
    this.hasValidBCode = false,
    this.bCode,
    this.operatorName,
    this.hasMersis = false,
    this.mersisNo,
    this.hasFakeBCodeTrap = false,
    this.fakeBCodeRaw,
    this.isForeignSender = false,
    this.foreignCountryCode,
    this.isForeignSenderWithoutBCode = false,
  });

  /// True when a genuine 4-char BTK code (e.g. B001, B002) is at the end of the SMS.
  final bool hasValidBCode;

  /// Extracted canonical BTK code (e.g. "B001", "B002", "B043").
  final String? bCode;

  /// Resolved Turkish operator / STH agency name when known.
  final String? operatorName;

  /// True when a MERSİS number or tag is present.
  final bool hasMersis;

  /// Extracted 16-digit MERSİS number if present.
  final String? mersisNo;

  /// True when a spoofed/obfuscated B-Code (e.g. "B.0.0.1", "B O O 1", Cyrillic "В001",
  /// or mid-message B-code injection) is detected.
  final bool hasFakeBCodeTrap;

  /// Raw matched fake B-code snippet for diagnostics.
  final String? fakeBCodeRaw;

  /// True when the sender starts with a non-Turkish international country code (+63, +62, etc.).
  final bool isForeignSender;

  /// Detected foreign prefix (e.g. "+63", "+62", "+44").
  final String? foreignCountryCode;

  /// High-risk flag: unknown foreign number sending SMS without a valid BTK B-Code.
  final bool isForeignSenderWithoutBCode;
}

class Tokenizer {
  Tokenizer._();

  static const urlToken = '__url__';
  static const shortUrlToken = '__short_url__';
  static const suspiciousTldToken = '__suspicious_tld__';
  static const bCodeToken = '__bcode__';
  static const fakeBCodeToken = '__fake_bcode__';
  static const foreignNoBCodeToken = '__foreign_no_bcode__';
  static const homoglyphToken = '__homoglyph__';
  static const obfuscatedToken = '__obfuscated__';
  static const codeToken = '__code__';
  static const numToken = '__num__';

  /// Known Turkish BTK operator / STH agency B-Codes.
  static const Map<String, String> btkOperators = {
    'B001': 'Vodafone Telekomünikasyon A.Ş.',
    'B002': 'Turkcell İletişim Hizmetleri A.Ş.',
    'B003': 'Türk Telekomünikasyon A.Ş.',
    'B011': 'İleti Yönetim Sistemi (İYS) / STH',
    'B016': 'Netgsm İletişim A.Ş.',
    'B018': 'Mutlucell İletişim',
    'B021': 'İleti Merkezi (Toplusms)',
    'B026': 'Verimor Telekomünikasyon A.Ş.',
    'B030': 'Codec İletişim',
    'B038': 'Mobildev İletişim',
    'B043': 'JetSMS / Biotekno',
    'B045': 'Asist BT / Kurumsal SMS',
    'B199': 'BTK Yetkili STH',
    'B210': 'BTK Yetkili STH (B210)',
  };

  /// Map of Cyrillic & Greek homoglyphs (lookalike characters) to Latin lower-case.
  static const Map<int, String> _homoglyphMap = {
    // Cyrillic uppercase & lowercase
    0x0410: 'a', 0x0430: 'a', // А, а
    0x0412: 'b', 0x0432: 'b', // В, в
    0x0421: 'c', 0x0441: 'c', // С, с
    0x0415: 'e', 0x0435: 'e', // Е, е
    0x0401: 'e', 0x0451: 'e', // Ё, ё
    0x0405: 's', 0x0455: 's', // Ѕ, ѕ
    0x0406: 'i', 0x0456: 'i', // І, і
    0x0407: 'i', 0x0457: 'i', // Ї, ї
    0x0408: 'j', 0x0458: 'j', // Ј, ј
    0x041A: 'k', 0x043A: 'k', // К, к
    0x041C: 'm', 0x043C: 'm', // М, м
    0x041D: 'h', 0x043D: 'h', // Н, н
    0x041E: 'o', 0x043E: 'o', // О, о
    0x0420: 'p', 0x0440: 'p', // Р, р
    0x0422: 't', 0x0442: 't', // Т, т
    0x0423: 'y', 0x0443: 'y', // У, у
    0x0425: 'x', 0x0445: 'x', // Х, х
    0x0417: 'z', 0x0437: 'z', // З, з
    // Greek uppercase & lowercase
    0x0391: 'a', 0x03B1: 'a', // Α, α
    0x0392: 'b', 0x03B2: 'b', // Β, β
    0x0395: 'e', 0x03B5: 'e', // Ε, ε
    0x0396: 'z', 0x03B6: 'z', // Ζ, ζ
    0x0397: 'h', 0x03B7: 'n', // Η, η
    0x0399: 'i', 0x03B9: 'i', // Ι, ι
    0x039A: 'k', 0x03BA: 'k', // Κ, κ
    0x039C: 'm', 0x03BC: 'u', // Μ, μ
    0x039D: 'n', 0x03BD: 'v', // Ν, ν
    0x039F: 'o', 0x03BF: 'o', // Ο, ο
    0x03A1: 'p', 0x03C1: 'p', // Ρ, ρ
    0x03A4: 't', 0x03C4: 't', // Τ, τ
    0x03A5: 'y', 0x03C5: 'u', // Υ, υ
    0x03A7: 'x', 0x03C7: 'x', // Χ, χ
  };

  static final RegExp urlPattern = RegExp(
    r'(https?://\S+|www\.\S+|[a-z0-9-]+\.(com|net|org|info|co|io|ly|me|xyz|top|cn|ru|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|site|online|live)(/\S*)?)',
    caseSensitive: false,
  );

  static final RegExp shortenerPattern = RegExp(
    r'(bit\.ly|tinyurl\.com|goo\.gl|t\.co/|cutt\.ly|is\.gd|ow\.ly|rb\.gy|shorturl\.at|l24\.im|ay\.link|tr\.ee|rebrand\.ly)',
    caseSensitive: false,
  );

  static final RegExp suspiciousTldPattern = RegExp(
    r'\b[a-z0-9-]+\.(xyz|top|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|online|live)\b',
    caseSensitive: false,
  );

  /// Valid BTK B-Code pattern (e.g. B001, B002, B011, B021, B043, B210).
  static final RegExp validBCodePattern = RegExp(
    r'\b(B\d{3})\b',
    caseSensitive: false,
  );

  /// MERSİS pattern (keyword or 16-digit MERSIS identifier).
  static final RegExp mersisPattern = RegExp(
    r'(\bmersis(\s*no)?\s*[:.]?\s*(\d{16})?|\b0\d{15}\b)',
    caseSensitive: false,
  );

  /// Turkish / international commercial SMS suffix codes (e.g. B001, B002, B210, MERSIS).
  static final RegExp bCodePattern = RegExp(
    r'(\bB\d{3}\b|\bmersis\s*no|\bmersis:)',
    caseSensitive: false,
  );

  /// Detects spoofed/obfuscated B-Code traps like "B.0.0.1", "B O O 1", "B-0-0-2",
  /// "B0O1" (letter O instead of digit 0), or Cyrillic "В001".
  static final RegExp _fakeBCodePattern = RegExp(
    r'(?:(?<![a-zA-Z0-9])[BВbв][\s._*-]+[0Oo][\s._*-]*[0Oo1-9][\s._*-]*[0-9OoIl](?![a-zA-Z0-9])|\b[BВbв](?:[Oo]{2}[0-9]|[0-9][Oo][0-9]|[0-9]{2}[OoIl])\b|\b[\u0412\u0432\u0392\u03B2]\d{3}\b)',
    unicode: true,
  );

  static final RegExp _zeroWidth = RegExp(
    r'[\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF\u00AD]',
  );

  /// Matches single-character obfuscated chains separated by spaces, dots,
  /// asterisks, hyphens, underscores or injected leet symbols (e.g.,
  /// "B.a.h.!.s", "f*r*e*e*s*p*i*n", "f r e e s p i n", "b o n u s").
  static final RegExp _spacedOrPunctuatedLetters = RegExp(
    r'(?<![\p{L}\p{N}])([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])(?:[\s.*_~+|/\\-]+([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])){3,}(?![\p{L}\p{N}])',
    unicode: true,
  );

  /// Matches words that have punctuation/leet symbols injected directly inside
  /// them without spaces (e.g. "B.a.h.!.s", "b@h!s", "f*r*e*e*s*p*i*n", "b_o_n_u_s").
  static final RegExp _inlineInjectedWord = RegExp(
    r'(?<![\p{L}\p{N}])[\p{L}$!@€][\p{L}\p{Nd}.*_!@$€-]{2,}[\p{L}\p{Nd}!@$€](?![\p{L}\p{N}])',
    unicode: true,
  );

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  /// CJK Unified Ideographs (+ Extension A) — languages written without spaces.
  static bool isCjk(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF);

  static bool _isDigit(int rune) => _digit.hasMatch(String.fromCharCode(rune));
  static bool _isWordChar(int rune) =>
      _letterOrDigit.hasMatch(String.fromCharCode(rune));

  static bool _isLatinRune(int r) =>
      (r >= 0x0041 && r <= 0x005A) ||
      (r >= 0x0061 && r <= 0x007A) ||
      'çğıöşüÇĞİÖŞÜ'.runes.contains(r);

  /// Detects if [text] uses Cyrillic/Greek homoglyphs mixed with Latin letters
  /// or full-width Unicode characters to evade filters.
  static bool hasHomoglyphAttack(String text) {
    var hasHomo = false;
    var hasLatin = false;
    for (final r in text.runes) {
      if (r >= 0xFF01 && r <= 0xFF5E) return true; // Full-width ASCII
      if (_homoglyphMap.containsKey(r)) hasHomo = true;
      if (_isLatinRune(r)) hasLatin = true;
    }
    if (hasHomo && hasLatin) return true;
    // Also check if Cyrillic В is used in a B-code like В001
    if (RegExp(r'[\u0412\u0432\u0392\u03B2]\d{3}').hasMatch(text)) return true;
    return false;
  }

  /// Detects if [text] contains deliberate character obfuscation (homoglyphs,
  /// spaced/punctuated words like "B.a.h.!.s" or "f*r*e*e*s*p*i*n").
  static bool hasObfuscation(String text) {
    if (hasHomoglyphAttack(text)) return true;
    if (_spacedOrPunctuatedLetters.hasMatch(text)) return true;
    final strippedUrls = text.replaceAll(urlPattern, ' ');
    for (final m in _inlineInjectedWord.allMatches(strippedUrls)) {
      final token = m.group(0)!;
      if (RegExp(r'[.*_!@$€]').hasMatch(token) &&
          RegExp(r'[\p{L}]', unicode: true).hasMatch(token)) {
        return true;
      }
    }
    return false;
  }

  /// Replaces Cyrillic, Greek, and Full-Width Unicode characters with their
  /// standard Latin ASCII equivalents when mixed or used for evasion.
  /// Pure Russian/Greek texts without Latin mixing keep their native script,
  /// while also generating normalized Latin equivalents during de-obfuscation.
  static String normalizeHomoglyphs(String text, {bool forceAll = false}) {
    final cleaned = text.replaceAll(_zeroWidth, '');
    final hasLatin = cleaned.runes.any(_isLatinRune);
    final shouldMapScript = forceAll ||
        hasLatin ||
        RegExp(r'[\u0412\u0432\u0392\u03B2]\d{3}').hasMatch(cleaned);

    final sb = StringBuffer();
    for (final r in cleaned.runes) {
      if (r >= 0xFF01 && r <= 0xFF5E) {
        sb.writeCharCode(r - 0xFEE0);
      } else if (shouldMapScript && _homoglyphMap.containsKey(r)) {
        sb.write(_homoglyphMap[r]!);
      } else {
        sb.writeCharCode(r);
      }
    }
    return sb.toString();
  }

  /// Maps Turkish specific characters ('ı','İ','ş','ğ','ü','ö','ç') to their
  /// ASCII equivalents ('i','s','g','u','o','c') so Turkish words match
  /// regardless of keyboard or accent rounding.
  static String foldTurkishAscii(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('Ş', 's')
        .replaceAll('ş', 's')
        .replaceAll('Ğ', 'g')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('Ö', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'c')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  static String _mapLeetSymbolsAndDigits(String input, {bool mapDigits = true}) {
    var out = input
        .replaceAll('!', 'i')
        .replaceAll('¡', 'i')
        .replaceAll('@', 'a')
        .replaceAll(r'$', 's')
        .replaceAll('€', 'e');
    if (mapDigits) {
      out = out
          .replaceAll('0', 'o')
          .replaceAll('1', 'i')
          .replaceAll('3', 'e')
          .replaceAll('4', 'a')
          .replaceAll('5', 's')
          .replaceAll('7', 't')
          .replaceAll('8', 'b');
    }
    return out;
  }

  /// Cleans a single obfuscated word token such as `B.a.h.!.s` -> `bahis`
  /// or `f*r*e*e*s*p*i*n` -> `freespin`.
  static String _cleanInjectedToken(String raw) {
    // Do not touch pure numbers or decimals like "250.00"
    if (RegExp(r'^\d+([.,:-]\d+)*$').hasMatch(raw)) return raw;
    // Remove separator punctuation (., *, _, -) and map leet symbols (!, @, $, €)
    final strippedSeparators = raw.replaceAll(RegExp(r'[.*_-]+'), '');
    final mappedSymbols = _mapLeetSymbolsAndDigits(
      strippedSeparators,
      mapDigits: false,
    );
    // If there are both letters and digits, also map leet digits
    final hasLetter = RegExp(r'[a-zçğıöşü]', caseSensitive: false).hasMatch(mappedSymbols);
    final hasDigit = RegExp(r'\d').hasMatch(mappedSymbols);
    if (hasLetter && hasDigit && mappedSymbols.length >= 3) {
      return _mapLeetSymbolsAndDigits(mappedSymbols, mapDigits: true);
    }
    return mappedSymbols;
  }

  /// Normalizes obfuscated text (zero-width chars, Cyrillic/Greek homoglyphs,
  /// spaced-out words like "f r e e s p i n", symbol-injected words like
  /// "B.a.h.!.s" or "f*r*e*e*s*p*i*n", and leetspeak like "b0nus") into clean
  /// lower-case text (plus ASCII-folded mirror) for threat & semantic matching.
  static String normalizeObfuscation(String text) {
    // 1. Homoglyph & zero-width normalization (forceAll=true so even all-Cyrillic
    // spoofed words like "bоnus" become "bonus")
    var cleaned = normalizeHomoglyphs(text, forceAll: true)
        .replaceAll('İ', 'i')
        .toLowerCase();

    // 2. Collapse spaced/punctuated single-char chains (e.g. "f r e e s p i n", "b.a.h.!.s")
    cleaned = cleaned.replaceAllMapped(_spacedOrPunctuatedLetters, (m) {
      final raw = m.group(0)!.replaceAll(RegExp(r'[\s.*_~+|/\\-]+'), '');
      return _mapLeetSymbolsAndDigits(raw, mapDigits: true);
    });

    // 3. Clean inline symbol-injected tokens (e.g. "b@h!s", "f*r*e*e*s*p*i*n", "b0nus")
    // while preserving URLs.
    final urls = <String>[];
    cleaned = cleaned.replaceAllMapped(urlPattern, (m) {
      urls.add(m.group(0)!);
      return ' __url_slot_${urls.length - 1}__ ';
    });

    cleaned = cleaned.replaceAllMapped(_inlineInjectedWord, (m) {
      final tok = m.group(0)!;
      if (tok.startsWith('__url_slot_')) return tok;
      return _cleanInjectedToken(tok);
    });

    // Restore URLs
    for (var i = 0; i < urls.length; i++) {
      cleaned = cleaned.replaceAll('__url_slot_${i}__', urls[i]);
    }

    // 4. Append Turkish ASCII-folded mirror if diacritics exist so both
    // "çevrimsiz" and "cevrimsiz" match seamlessly.
    final folded = foldTurkishAscii(cleaned);
    if (folded != cleaned) {
      return '$cleaned $folded';
    }
    return cleaned;
  }

  /// Parses BTK B-Codes (B001, B002, B011, B021, B043, B210, etc.), MERSİS numbers,
  /// spoofed B-Code traps ("B.0.0.1", "B O O 1", mid-text B-codes), and foreign
  /// sender prefixes (+63, +62, etc.).
  static BtkAnalysis analyzeBtk(String text, {String? sender}) {
    final trimmed = text.replaceAll(_zeroWidth, '').trim();
    final cleanSender = sender?.replaceAll(_zeroWidth, '').trim() ?? '';

    // 1. Check for MERSİS
    final mersisMatch = mersisPattern.firstMatch(trimmed);
    final hasMersis = mersisMatch != null;
    final mersisDigits = RegExp(r'\b0\d{15}\b').firstMatch(trimmed)?.group(0);

    // 2. Check for Fake / Obfuscated B-Code Traps ("B.0.0.1", "B O O 1", Cyrillic "В001")
    final fakeMatch = _fakeBCodePattern.firstMatch(trimmed);
    var hasFakeBCodeTrap = fakeMatch != null;
    var fakeRaw = fakeMatch?.group(0);

    // 3. Check for standard B-Code (e.g. B001, B002, B043, B210)
    String? validBCode;
    String? operatorName;
    final allBCodes = validBCodePattern.allMatches(trimmed).toList();
    if (allBCodes.isNotEmpty) {
      final lastMatch = allBCodes.last;
      final candidate = lastMatch.group(1)!.toUpperCase();
      final trailingLength = trimmed.length - lastMatch.end;

      // Genuine BTK B-Codes appear at the end of the SMS (or followed only by short opt-out/whitespace).
      // If a B-Code is injected in the middle of the message followed by a URL or long text (> 28 chars),
      // it is a mid-message fake B-Code trap!
      final trailingText = trimmed.substring(lastMatch.end);
      if (trailingLength <= 28 && !urlPattern.hasMatch(trailingText)) {
        validBCode = candidate;
        operatorName = btkOperators[candidate] ?? 'BTK Kayıtlı Operatör ($candidate)';
      } else {
        hasFakeBCodeTrap = true;
        fakeRaw ??= candidate;
      }
    }

    // 4. Check sender for foreign international dialing prefix (non-+90)
    var isForeignSender = false;
    String? foreignCountryCode;
    if (cleanSender.isNotEmpty) {
      final compactSender = cleanSender.replaceAll(RegExp(r'[\s()-]'), '');
      final intlMatch = RegExp(r'^(\+|00)(\d{1,3})\d{5,}$').firstMatch(compactSender);
      if (intlMatch != null) {
        final digitsAfterPrefix = compactSender.replaceFirst(RegExp(r'^(\+|00)'), '');
        if (!digitsAfterPrefix.startsWith('90')) {
          isForeignSender = true;
          final codeLen = digitsAfterPrefix.startsWith('1') || digitsAfterPrefix.startsWith('7')
              ? 1
              : (digitsAfterPrefix.length >= 2 ? 2 : 1);
          foreignCountryCode = '+${digitsAfterPrefix.substring(0, codeLen)}';
        }
      }
    }

    final isForeignWithoutBCode =
        isForeignSender && validBCode == null && !hasMersis;

    return BtkAnalysis(
      hasValidBCode: validBCode != null,
      bCode: validBCode,
      operatorName: operatorName,
      hasMersis: hasMersis,
      mersisNo: mersisDigits,
      hasFakeBCodeTrap: hasFakeBCodeTrap,
      fakeBCodeRaw: fakeRaw,
      isForeignSender: isForeignSender,
      foreignCountryCode: foreignCountryCode,
      isForeignSenderWithoutBCode: isForeignWithoutBCode,
    );
  }

  /// De-leetspeaks common mixed alphanumeric tokens (e.g. "b0nus" -> "bonus").
  static String? _deLeet(String word) {
    final hasLetter = word.runes.any((r) => !_isDigit(r) && !isCjk(r));
    final hasDigit = word.runes.any(_isDigit);
    if (!hasLetter || !hasDigit || word.length < 3) return null;
    final converted = _mapLeetSymbolsAndDigits(word, mapDigits: true);
    return converted != word ? converted : null;
  }

  /// Returns the ordered token list (may contain duplicates).
  static List<String> tokenize(String text, {String? sender}) {
    final tokens = <String>[];
    final cleaned = text.replaceAll(_zeroWidth, '');
    final homoNormalized = normalizeHomoglyphs(cleaned, forceAll: true);
    final lower = homoNormalized.replaceAll('İ', 'i').toLowerCase();

    if (urlPattern.hasMatch(lower)) tokens.add(urlToken);
    if (shortenerPattern.hasMatch(lower)) tokens.add(shortUrlToken);
    if (suspiciousTldPattern.hasMatch(lower)) tokens.add(suspiciousTldToken);

    final btk = analyzeBtk(text, sender: sender);
    if (btk.hasValidBCode || btk.hasMersis || bCodePattern.hasMatch(lower)) {
      tokens.add(bCodeToken);
    }
    if (btk.hasFakeBCodeTrap) {
      tokens.add(fakeBCodeToken);
    }
    if (btk.isForeignSenderWithoutBCode) {
      tokens.add(foreignNoBCodeToken);
    }
    if (hasHomoglyphAttack(text)) {
      tokens.add(homoglyphToken);
    }
    if (hasObfuscation(text)) {
      tokens.add(obfuscatedToken);
    }

    // Capture de-obfuscated spaced/punctuated words (e.g. "B.a.h.!.s" -> "bahis", "f r e e s p i n" -> "freespin")
    for (final m in _spacedOrPunctuatedLetters.allMatches(homoNormalized)) {
      final raw = m.group(0)!.replaceAll(RegExp(r'[\s.*_~+|/\\-]+'), '').toLowerCase();
      final collapsed = _mapLeetSymbolsAndDigits(raw, mapDigits: true);
      if (collapsed.length >= 3) {
        tokens.add(collapsed);
        final ascii = foldTurkishAscii(collapsed);
        if (ascii != collapsed) tokens.add(ascii);
      }
    }

    final stripped = lower.replaceAll(urlPattern, ' ');

    // Also extract inline symbol-injected words (e.g. "f*r*e*e*s*p*i*n", "b@h!s")
    for (final m in _inlineInjectedWord.allMatches(stripped)) {
      final rawTok = m.group(0)!;
      if (RegExp(r'[.*_!@$€-]').hasMatch(rawTok)) {
        final deobf = _cleanInjectedToken(rawTok);
        if (deobf.length >= 3 && deobf != rawTok) {
          tokens.add(deobf);
          final ascii = foldTurkishAscii(deobf);
          if (ascii != deobf) tokens.add(ascii);
        }
      }
    }

    // Segment into runs of: 0 = other letters, 1 = digits, 2 = CJK.
    final buffer = StringBuffer();
    int? currentClass;

    void flush() {
      if (buffer.isEmpty) return;
      final segment = buffer.toString();
      buffer.clear();
      switch (currentClass) {
        case 1:
          final len = segment.runes.length;
          tokens.add(len >= 4 && len <= 8 ? codeToken : numToken);
        case 2:
          final chars = segment.runes.map(String.fromCharCode).toList();
          tokens.addAll(chars);
          for (var i = 0; i < chars.length - 1; i++) {
            tokens.add(chars[i] + chars[i + 1]);
          }
        default:
          if (segment.runes.length > 1) {
            tokens.add(segment);
            final ascii = foldTurkishAscii(segment);
            if (ascii != segment) tokens.add(ascii);
          }
      }
    }

    for (final rune in stripped.runes) {
      if (!_isWordChar(rune)) {
        flush();
        currentClass = null;
        continue;
      }
      final cls = _isDigit(rune) ? 1 : (isCjk(rune) ? 2 : 0);
      if (cls != currentClass) {
        flush();
        currentClass = cls;
      }
      buffer.writeCharCode(rune);
    }
    flush();

    // Check mixed alphanumeric tokens for leetspeak (e.g. b0nus -> bonus)
    for (final m in RegExp(r'[\p{L}\p{Nd}]{3,}', unicode: true).allMatches(stripped)) {
      final deLeeted = _deLeet(m.group(0)!);
      if (deLeeted != null) {
        tokens.add(deLeeted);
        final ascii = foldTurkishAscii(deLeeted);
        if (ascii != deLeeted) tokens.add(ascii);
      }
    }

    return tokens;
  }

  /// Distinct tokens — the model uses binary (presence) features.
  static Set<String> features(String text, {String? sender}) =>
      tokenize(text, sender: sender).toSet();
}
