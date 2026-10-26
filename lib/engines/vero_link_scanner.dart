import 'dart:convert';
import 'package:flutter/services.dart';

/// Threat level of a scanned URL.
enum LinkRiskLevel {
  safe,
  suspicious,
  dangerous,
}

/// Result of scanning a URL for phishing, shorteners, dangerous files, and spoofing.
class LinkScanResult {
  const LinkScanResult({
    required this.originalUrl,
    required this.domain,
    required this.riskLevel,
    required this.riskScore,
    required this.reasons,
    required this.isShortened,
    required this.isPhishing,
    required this.isInsecureHttp,
    required this.isExecutable,
    this.sourceApp,
  });

  final String originalUrl;
  final String domain;
  final LinkRiskLevel riskLevel;
  final double riskScore; // 0.0 to 100.0
  final List<String> reasons;
  final bool isShortened;
  final bool isPhishing;
  final bool isInsecureHttp;
  final bool isExecutable;
  final String? sourceApp;

  bool get isThreat => riskLevel != LinkRiskLevel.safe;

  String get warningMessage =>
      isThreat ? '🚨 DİKKAT: Bu link şüpheli! Tıklamayın.' : '✅ Bu link güvenli görünüyor.';

  Map<String, dynamic> toMap() => {
        'originalUrl': originalUrl,
        'domain': domain,
        'riskLevel': riskLevel.name,
        'riskScore': riskScore,
        'reasons': reasons,
        'isShortened': isShortened,
        'isPhishing': isPhishing,
        'isInsecureHttp': isInsecureHttp,
        'isExecutable': isExecutable,
        'sourceApp': sourceApp,
        'warningMessage': warningMessage,
      };

  @override
  String toString() =>
      'LinkScanResult(domain: $domain, riskLevel: ${riskLevel.name}, score: $riskScore)';
}

/// 100% Offline Real-Time WhatsApp & Telegram Link Scanner.
///
/// Detects phishing URLs, dangerous file downloads (.apk, .exe),
/// obfuscated URL shorteners, and brand impersonation without any internet access.
class VeroLinkScanner {
  VeroLinkScanner._();
  static final VeroLinkScanner instance = VeroLinkScanner._();

  final Set<String> _phishingDomains = <String>{};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  int get domainCount => _phishingDomains.length;

  static final RegExp _urlRegex = RegExp(
    r'(?:https?:\/\/|www\.)[^\s/$.?#].[^\s]*',
    caseSensitive: false,
  );

  static final Set<String> _shorteners = {
    'bit.ly',
    'tinyurl.com',
    't.co',
    'goo.gl',
    'ow.ly',
    'is.gd',
    'buff.ly',
    'adf.ly',
    'bit.do',
    'cutt.ly',
    'rebrand.ly',
    'shorturl.at',
    't.ly',
    'tiny.cc',
  };

  static final Set<String> _dangerousExtensions = {
    '.apk',
    '.exe',
    '.bat',
    '.cmd',
    '.msi',
    '.vbs',
    '.scr',
    '.jar',
    '.com',
    '.pif',
    '.reg',
  };

  static final List<String> _brandKeywords = [
    'ziraat',
    'garanti',
    'isbank',
    'akbank',
    'vakif',
    'yapikredi',
    'halkbank',
    'denizbank',
    'qnb',
    'enpara',
    'papara',
    'edevlet',
    'e-devlet',
    'e-deviet',
    'turkiye-gov',
    'turkiyegov',
    'gib-gov',
    'ptt-kargo',
    'araskargo',
    'yurticikargo',
    'mngkargo',
    'netflix',
    'amazon',
    'instagram',
    'whatsapp',
    'telegram',
  ];

  static final Set<String> _suspiciousTlds = {
    '.top',
    '.xyz',
    '.club',
    '.click',
    '.icu',
    '.link',
    '.online',
    '.site',
    '.vip',
    '.work',
    '.tk',
    '.ml',
    '.ga',
    '.cf',
    '.gq',
  };

  /// Initialize and load offline phishing domains database.
  Future<void> initialize({String? customDomainsRaw, Set<String>? customDomainSet}) async {
    if (customDomainSet != null) {
      _phishingDomains.clear();
      _phishingDomains.addAll(customDomainSet);
      _initialized = true;
      return;
    }

    if (customDomainsRaw != null) {
      _loadFromString(customDomainsRaw);
      _initialized = true;
      return;
    }

    try {
      final raw = await rootBundle.loadString('assets/spam_db/phishing_domains.bin');
      _loadFromString(raw);
      _initialized = true;
    } catch (_) {
      // Fallback: load baseline fraudulent domains offline
      _loadDefaultSeed();
      _initialized = true;
    }
  }

  void _loadFromString(String raw) {
    _phishingDomains.clear();
    final lines = const LineSplitter().convert(raw);
    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        _phishingDomains.add(trimmed);
      }
    }
  }

  void _loadDefaultSeed() {
    _phishingDomains.addAll([
      'e-deviet.com',
      'e-devlet-kapisi-onay.com',
      'turkiye-gov-tr-aidat.site',
      'ziraat-banka-guvenlik.com',
      'ziraat-sube-onay.xyz',
      'garanti-kart-bloke.top',
      'ptt-kargo-takip-teslimat.icu',
      'hgs-borc-odeme-ceza.online',
      'sgk-prim-iade-sorgu.click',
      'vergi-borcu-yapilandirma-gib.club',
      'netflix-hesap-askida.com',
      'whatsapp-hediye-cekilis.xyz',
    ]);
  }

  /// Scans raw text (e.g. from WhatsApp or Telegram notification/message)
  /// and returns scan results for all contained URLs.
  List<LinkScanResult> scanText(String text, {String? sourceApp}) {
    final matches = _urlRegex.allMatches(text);
    if (matches.isEmpty) return const [];

    final results = <LinkScanResult>[];
    for (final m in matches) {
      final url = m.group(0)!;
      results.add(scanUrl(url, sourceApp: sourceApp));
    }
    return results;
  }

  /// Scans a single URL and returns detailed threat breakdown.
  LinkScanResult scanUrl(String rawUrl, {String? sourceApp}) {
    var cleanUrl = rawUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    Uri? uri;
    try {
      uri = Uri.parse(cleanUrl);
    } catch (_) {
      uri = null;
    }

    final host = (uri?.host ?? '').toLowerCase();
    final path = (uri?.path ?? '').toLowerCase();
    final full = cleanUrl.toLowerCase();

    final reasons = <String>[];
    var score = 0.0;
    var isShortened = false;
    var isPhishing = false;
    var isInsecureHttp = false;
    var isExecutable = false;

    // 1. Insecure HTTP Check
    if (cleanUrl.startsWith('http://')) {
      isInsecureHttp = true;
      score += 20.0;
      reasons.add('Güvensiz HTTP protokolü kullanılıyor (şifreleme yok)');
    }

    // 2. Shortener Check
    for (final s in _shorteners) {
      if (host == s || host.endsWith('.$s')) {
        isShortened = true;
        score += 35.0;
        reasons.add('Kısaltılmış URL ($host) hedef adresi gizliyor');
        break;
      }
    }

    // 3. Dangerous File Download Check (.apk, .exe, etc.)
    for (final ext in _dangerousExtensions) {
      if (path.endsWith(ext) || full.contains('$ext?')) {
        isExecutable = true;
        score += 85.0;
        reasons.add('Doğrudan zararlı dosya indirme tespit edildi ($ext)');
        break;
      }
    }

    // 4. Exact match in Offline Phishing Database
    if (_phishingDomains.contains(host)) {
      isPhishing = true;
      score += 90.0;
      reasons.add('VeroApp çevrimdışı sahte domain veritabanında kayıtlı');
    }

    // 5. Suspicious TLD check
    for (final tld in _suspiciousTlds) {
      if (host.endsWith(tld)) {
        score += 25.0;
        reasons.add('Yüksek riskli TLD uzantısı ($tld)');
        break;
      }
    }

    // 6. Typo-squatting / Brand Impersonation check
    for (final brand in _brandKeywords) {
      if (host.contains(brand)) {
        // Legitimate domain check
        final isLegit = (brand == 'ziraat' && (host == 'ziraatbank.com.tr' || host.endsWith('.ziraatbank.com.tr'))) ||
            (brand == 'garanti' && (host == 'garantibbva.com.tr' || host.endsWith('.garantibbva.com.tr'))) ||
            (brand == 'isbank' && (host == 'isbank.com.tr' || host.endsWith('.isbank.com.tr'))) ||
            (brand == 'akbank' && (host == 'akbank.com' || host.endsWith('.akbank.com'))) ||
            (brand == 'edevlet' && (host == 'turkiye.gov.tr' || host.endsWith('.turkiye.gov.tr'))) ||
            (brand == 'e-devlet' && (host == 'turkiye.gov.tr' || host.endsWith('.turkiye.gov.tr'))) ||
            (brand == 'netflix' && (host == 'netflix.com' || host.endsWith('.netflix.com'))) ||
            (brand == 'amazon' && (host == 'amazon.com.tr' || host == 'amazon.com' || host.endsWith('.amazon.com'))) ||
            (brand == 'whatsapp' && (host == 'whatsapp.com' || host.endsWith('.whatsapp.com'))) ||
            (brand == 'telegram' && (host == 'telegram.org' || host == 't.me'));

        if (!isLegit) {
          isPhishing = true;
          score += 45.0;
          reasons.add('Sahte resmi marka/kurum taklidi ($brand)');
          break;
        }
      }
    }

    // Normalize score
    if (score > 100.0) score = 100.0;

    final LinkRiskLevel riskLevel;
    if (score >= 60.0) {
      riskLevel = LinkRiskLevel.dangerous;
    } else if (score >= 30.0) {
      riskLevel = LinkRiskLevel.suspicious;
    } else {
      riskLevel = LinkRiskLevel.safe;
    }

    return LinkScanResult(
      originalUrl: rawUrl,
      domain: host.isNotEmpty ? host : rawUrl,
      riskLevel: riskLevel,
      riskScore: score,
      reasons: reasons,
      isShortened: isShortened,
      isPhishing: isPhishing,
      isInsecureHttp: isInsecureHttp,
      isExecutable: isExecutable,
      sourceApp: sourceApp,
    );
  }
}
