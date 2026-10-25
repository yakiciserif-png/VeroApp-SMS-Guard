/// FAZ 5 — [1] SAFE-CLICK: 100% Offline Static URL X-Ray & Link Risk Analyzer.
///
/// Inspects URLs inside SMS messages or pasted directly by the user without
/// making any network requests (100% KVKK / GDPR compliant).
enum SafeClickRisk { safe, caution, critical }

class SafeClickLinkResult {
  const SafeClickLinkResult({
    required this.rawUrl,
    required this.host,
    required this.riskScore,
    required this.riskLevel,
    required this.findingKeys,
    this.impersonatedBrand,
  });

  final String rawUrl;
  final String host;

  /// Normalized risk score in [0, 100].
  final int riskScore;
  final SafeClickRisk riskLevel;

  /// Localization keys describing why the link was flagged (or `safeClickClean`).
  final List<String> findingKeys;

  /// Name of the brand/institution being impersonated, if detected.
  final String? impersonatedBrand;
}

class SafeClickEngine {
  const SafeClickEngine._();

  static final RegExp _urlExtractRegex = RegExp(
    r'(?:https?:\/\/|www\.|[a-zA-Z0-9][a-zA-Z0-9-]{1,61}\.(?:com|net|org|tr|gov\.tr|edu\.tr|com\.tr|xyz|top|bet|vip|icu|click|link|shop|site|online|club|info|biz|me|ly|gl|co|io|tk|ml|ga|cf|gq|pw|win|loan|buzz|monster|rest|sbs|cfd|cam|fun))(?:\/[^\s<>"]*)?',
    caseSensitive: false,
  );

  static final RegExp _ipHostRegex = RegExp(
    r'^(?:\d{1,3}\.){3}\d{1,3}$',
  );

  static const Set<String> suspiciousTlds = {
    'xyz',
    'top',
    'bet',
    'tk',
    'click',
    'icu',
    'vip',
    'win',
    'loan',
    'buzz',
    'monster',
    'rest',
    'sbs',
    'cfd',
    'cam',
    'fun',
    'pw',
    'gq',
    'ml',
    'cf',
    'ga',
    'casino',
    'poker',
  };

  static const Set<String> shortenerHosts = {
    'bit.ly',
    't.me',
    'cutt.ly',
    'tinyurl.com',
    'rb.gy',
    'is.gd',
    'shorturl.at',
    'rebrand.ly',
    'ow.ly',
    'soo.gd',
    's.id',
    'v.gd',
    'tiny.cc',
    't.co',
    'lnkd.in',
  };

  /// Map of protected brand token -> official legitimate root domains.
  static const Map<String, List<String>> protectedBrands = {
    'edevlet': ['turkiye.gov.tr'],
    'e-devlet': ['turkiye.gov.tr'],
    'turkiyegov': ['turkiye.gov.tr'],
    'uyap': ['uyap.gov.tr', 'adalet.gov.tr'],
    'gib': ['gib.gov.tr'],
    'hgs': ['ptt.gov.tr', 'kgm.gov.tr'],
    'ptt': ['ptt.gov.tr', 'pttkargo.com.tr'],
    'trendyol': ['trendyol.com', 'ty.gl'],
    'hepsiburada': ['hepsiburada.com'],
    'yurticikargo': ['yurticikargo.com'],
    'araskargo': ['araskargo.com.tr'],
    'mngkargo': ['mngkargo.com.tr'],
    'garanti': ['garantibbva.com.tr', 'garanti.com.tr'],
    'akbank': ['akbank.com', 'akbank.com.tr'],
    'ziraat': ['ziraatbank.com.tr'],
    'isbank': ['isbank.com.tr'],
    'yapikredi': ['yapikredi.com.tr'],
    'vakifbank': ['vakifbank.com.tr'],
    'halkbank': ['halkbank.com.tr'],
    'qnb': ['qnbfinansbank.com', 'qnb.com.tr'],
    'denizbank': ['denizbank.com'],
    'enpara': ['enpara.com', 'qnbfinansbank.com'],
    'papara': ['papara.com'],
    'apple': ['apple.com', 'icloud.com'],
    'netflix': ['netflix.com'],
    'binance': ['binance.com', 'trbinance.com'],
  };

  /// Extracts and analyzes all URLs found in [text].
  static List<SafeClickLinkResult> inspectText(String text) {
    if (text.trim().isEmpty) return const [];
    final matches = _urlExtractRegex.allMatches(text);
    final seen = <String>{};
    final results = <SafeClickLinkResult>[];

    for (final m in matches) {
      var raw = m.group(0)!.trim();
      // Strip trailing punctuation
      raw = raw.replaceAll(RegExp(r'[.,!?;:)\]]+$'), '');
      if (raw.isEmpty || !seen.add(raw.toLowerCase())) continue;
      results.add(analyzeUrl(raw));
    }
    return results;
  }

  /// Analyzes a single URL or domain string completely offline.
  static SafeClickLinkResult analyzeUrl(String rawInput) {
    final cleaned = rawInput.trim().replaceAll(RegExp(r'[.,!?;:)\]]+$'), '');
    final normalized = cleaned.startsWith(RegExp(r'https?://', caseSensitive: false))
        ? cleaned
        : 'http://$cleaned';

    Uri? uri;
    try {
      uri = Uri.parse(normalized);
    } catch (_) {
      uri = null;
    }

    final host = (uri?.host.isNotEmpty == true ? uri!.host : cleaned)
        .toLowerCase()
        .replaceFirst(RegExp(r'^www\.'), '');
    final pathAndQuery =
        '${uri?.path.toLowerCase() ?? ''} ${uri?.query.toLowerCase() ?? ''}';

    var score = 0;
    final findings = <String>[];
    String? impersonated;

    // 1. Raw IP address check
    if (_ipHostRegex.hasMatch(host)) {
      score += 65;
      findings.add('safeClickRiskIpHost');
    }

    // 2. URL shortener check
    if (shortenerHosts.contains(host)) {
      score += 45;
      findings.add('safeClickRiskShortener');
    }

    // 3. Suspicious TLD check
    final parts = host.split('.');
    final tld = parts.length >= 2 ? parts.last : '';
    if (suspiciousTlds.contains(tld)) {
      score += 55;
      findings.add('safeClickRiskTld');
    }

    // 4. Brand / Gov Impersonation & Typosquatting check
    final hostCompact = host.replaceAll(RegExp(r'[0-9]'), '');
    for (final entry in protectedBrands.entries) {
      final brand = entry.key;
      final officialDomains = entry.value;
      final mentionsBrand = host.contains(brand) ||
          hostCompact.contains(brand) ||
          pathAndQuery.contains(brand);
      if (mentionsBrand) {
        final isOfficial = officialDomains.any(
          (official) => host == official || host.endsWith('.$official'),
        );
        if (!isOfficial) {
          score += 70;
          impersonated = brand.toUpperCase();
          if (!findings.contains('safeClickRiskBrandSpoof')) {
            findings.add('safeClickRiskBrandSpoof');
          }
          break;
        }
      }
    }

    // 5. Punycode / Homoglyph & @ redirect / Excessive hyphens
    if (host.contains('xn--') || cleaned.contains('@')) {
      score += 50;
      findings.add('safeClickRiskPunycode');
    } else if ('-'.allMatches(host).length >= 2) {
      score += 25;
      findings.add('safeClickRiskHyphens');
    }

    // 6. Explicit HTTP with sensitive path words
    if (cleaned.toLowerCase().startsWith('http://') &&
        RegExp(r'(login|giris|odeme|verify|dogrula|bonus|iade|borc|icra)')
            .hasMatch('$host $pathAndQuery')) {
      score += 30;
      findings.add('safeClickRiskInsecureHttp');
    }

    final clampedScore = score.clamp(0, 100);
    final level = clampedScore >= 55
        ? SafeClickRisk.critical
        : clampedScore >= 25
            ? SafeClickRisk.caution
            : SafeClickRisk.safe;

    if (findings.isEmpty) {
      findings.add('safeClickClean');
    }

    return SafeClickLinkResult(
      rawUrl: cleaned,
      host: host,
      riskScore: clampedScore,
      riskLevel: level,
      findingKeys: findings,
      impersonatedBrand: impersonated,
    );
  }
}
