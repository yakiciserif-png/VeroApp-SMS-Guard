import '../classifier/classification.dart';

enum RuleType { keyword, regex }

/// Which part of the incoming SMS/notification a rule inspects (Junkman style).
enum RuleTarget {
  /// Matches if either sender or message body matches (default).
  any,

  /// Matches only the sender name / phone number / title.
  sender,

  /// Matches only the message body.
  body,
}

class _ParsedRegex {
  const _ParsedRegex({
    required this.pattern,
    required this.caseSensitive,
    required this.multiLine,
    required this.dotAll,
  });

  final String pattern;
  final bool caseSensitive;
  final bool multiLine;
  final bool dotAll;
}

/// A user-defined filtering rule. Keyword rules accept a comma-separated list
/// of keywords (any match triggers the rule); regex rules accept a full
/// regular expression (including inline flags like `(?i)`).
class FilterRule {
  FilterRule({
    required this.id,
    required this.name,
    required this.pattern,
    this.type = RuleType.keyword,
    this.target = RuleTarget.any,
    this.action = MessageCategory.spam,
    this.enabled = true,
    this.caseSensitive = false,
  });

  final String id;
  final String name;
  final String pattern;
  final RuleType type;
  final RuleTarget target;
  final MessageCategory action;
  final bool enabled;
  final bool caseSensitive;

  RegExp? _compiled;

  List<String> get keywords => pattern
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty)
      .toList();

  static _ParsedRegex _parseInlineRegexFlags(
    String rawPattern,
    bool defaultCaseSensitive,
  ) {
    var caseSens = defaultCaseSensitive;
    var multi = true;
    var dot = false;

    final inlineFlagRe = RegExp(r'\(\?([ims]+)\)');
    final cleaned = rawPattern.replaceAllMapped(inlineFlagRe, (m) {
      final flags = m.group(1)!;
      if (flags.contains('i')) caseSens = false;
      if (flags.contains('m')) multi = true;
      if (flags.contains('s')) dot = true;
      return '';
    });

    return _ParsedRegex(
      pattern: cleaned,
      caseSensitive: caseSens,
      multiLine: multi,
      dotAll: dot,
    );
  }

  static String _foldTurkishCase(String input) =>
      input.replaceAll('İ', 'i').toLowerCase();

  bool _matchesSingle(String text) {
    if (text.isEmpty) return false;
    switch (type) {
      case RuleType.keyword:
        final haystack = caseSensitive ? text : _foldTurkishCase(text);
        return keywords.any(
          (k) => haystack.contains(caseSensitive ? k : _foldTurkishCase(k)),
        );
      case RuleType.regex:
        try {
          final parsed = _parseInlineRegexFlags(pattern, caseSensitive);
          _compiled ??= RegExp(
            parsed.pattern,
            caseSensitive: parsed.caseSensitive,
            unicode: true,
            multiLine: parsed.multiLine,
            dotAll: parsed.dotAll,
          );
          final targetText =
              parsed.caseSensitive ? text : text.replaceAll('İ', 'i');
          return _compiled!.hasMatch(targetText);
        } on FormatException {
          return false;
        }
    }
  }

  bool matches(String text, {String? sender}) {
    if (!enabled || pattern.trim().isEmpty) return false;
    switch (target) {
      case RuleTarget.body:
        return _matchesSingle(text);
      case RuleTarget.sender:
        if (sender != null && sender.trim().isNotEmpty) {
          return _matchesSingle(sender);
        }
        // Fallback if sender was prefixed in `text` as "Sender: message"
        final colonIdx = text.indexOf(':');
        if (colonIdx > 0 && colonIdx < 32) {
          return _matchesSingle(text.substring(0, colonIdx));
        }
        return false;
      case RuleTarget.any:
        if (sender != null &&
            sender.trim().isNotEmpty &&
            _matchesSingle(sender)) {
          return true;
        }
        return _matchesSingle(text);
    }
  }

  /// Returns `null` when the pattern is valid, otherwise the error message.
  static String? validatePattern(String pattern, RuleType type) {
    if (pattern.trim().isEmpty) return 'empty';
    if (type == RuleType.regex) {
      try {
        final parsed = _parseInlineRegexFlags(pattern, false);
        if (parsed.pattern.isEmpty) return 'empty';
        RegExp(parsed.pattern, unicode: true);
      } on FormatException catch (e) {
        return e.message;
      }
    }
    return null;
  }

  FilterRule copyWith({
    String? name,
    String? pattern,
    RuleType? type,
    RuleTarget? target,
    MessageCategory? action,
    bool? enabled,
    bool? caseSensitive,
  }) =>
      FilterRule(
        id: id,
        name: name ?? this.name,
        pattern: pattern ?? this.pattern,
        type: type ?? this.type,
        target: target ?? this.target,
        action: action ?? this.action,
        enabled: enabled ?? this.enabled,
        caseSensitive: caseSensitive ?? this.caseSensitive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pattern': pattern,
        'type': type.name,
        'target': target.name,
        'action': action.label,
        'enabled': enabled,
        'caseSensitive': caseSensitive,
      };

  factory FilterRule.fromJson(Map<String, dynamic> json) => FilterRule(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        type: RuleType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => RuleType.keyword,
        ),
        target: RuleTarget.values.firstWhere(
          (t) => t.name == json['target'],
          orElse: () => RuleTarget.any,
        ),
        action: MessageCategory.fromLabel(json['action'] as String? ?? 'spam'),
        enabled: json['enabled'] as bool? ?? true,
        caseSensitive: json['caseSensitive'] as bool? ?? false,
      );
}

/// Ordered rule list — the first enabled matching rule wins, so users can
/// place "allow" rules above "block" rules.
class RuleEngine {
  RuleEngine([List<FilterRule>? rules]) : rules = rules ?? [];

  List<FilterRule> rules;

  FilterRule? firstMatch(String text, {String? sender}) {
    for (final rule in rules) {
      if (rule.matches(text, sender: sender)) return rule;
    }
    return null;
  }

  /// Ready-to-use Junkman-style rule templates users can add with one tap.
  static List<FilterRule> builtInTemplates() => [
        FilterRule(
          id: 'tpl_betting',
          name: 'Bahis & Casino Engelle (Betting Block)',
          pattern:
              'deneme bonusu, freespin, çevrimsiz, sweet bonanza, casino, slot, bahis, jackpot',
          type: RuleType.keyword,
          target: RuleTarget.any,
          action: MessageCategory.spam,
        ),
        FilterRule(
          id: 'tpl_icra_hgs',
          name: 'Sahte İcra / Uzlaştırma / HGS Engelle',
          pattern:
              r'(?i)(uzlaştırma dosyası|icra takibi|ceza dosyası|hgs borcu|gümrük ücreti)',
          type: RuleType.regex,
          target: RuleTarget.body,
          action: MessageCategory.spam,
        ),
        FilterRule(
          id: 'tpl_bcode',
          name: 'Ticari B-Kodlu / MERSİS Kampanya Engelle',
          pattern: r'(?i)(\bB0\d{2}\b|mersis\s*no|ret\s+yaz)',
          type: RuleType.regex,
          target: RuleTarget.body,
          action: MessageCategory.spam,
        ),
        FilterRule(
          id: 'tpl_shortlinks',
          name: 'Kısaltılmış Linkleri Engelle (Short URLs)',
          pattern: 'bit.ly, tinyurl.com, cutt.ly, t.co/, rb.gy, shorturl.at',
          type: RuleType.keyword,
          target: RuleTarget.body,
          action: MessageCategory.spam,
        ),
        FilterRule(
          id: 'tpl_vip_banks',
          name: 'Resmi Banka Başlıklarına İzin Ver (VIP)',
          pattern: 'GARANTI, ISBANKASI, ZIRAATBANK, AKBANK, YAPIKREDI, ENPARA',
          type: RuleType.keyword,
          target: RuleTarget.sender,
          action: MessageCategory.transaction,
        ),
      ];
}
