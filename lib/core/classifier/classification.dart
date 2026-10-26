/// Core value types shared by the classification pipeline.
library;

import 'semantic_intent_engine.dart';

/// The three primary message buckets VeroApp SMS Guard sorts every message into.
enum MessageCategory {
  normal('ham'),
  transaction('transaction'),
  spam('spam');

  const MessageCategory(this.label);

  /// Stable label used by the AI model, storage and native bridges.
  final String label;

  static MessageCategory fromLabel(String label) => MessageCategory.values
      .firstWhere((c) => c.label == label, orElse: () => MessageCategory.normal);
}

/// Detailed sub-category aligned with VeroApp SMS Guard & Apple IdentityLookup sub-actions.
enum MessageSubCategory {
  personal('personal'),
  otpCode('otp_code'),
  bankTransaction('bank_transaction'),
  bettingGambling('betting_gambling'),
  phishingScam('phishing_scam'),
  deliveryCustomsScam('delivery_scam'),
  governmentScam('gov_scam'),
  marketingPromotion('promotion'),
  suspiciousLink('suspicious_link'),
  customRule('custom_rule'),
  generalSpam('general_spam');

  const MessageSubCategory(this.id);
  final String id;

  static MessageSubCategory fromId(String? id) =>
      MessageSubCategory.values.firstWhere(
        (s) => s.id == id,
        orElse: () => MessageSubCategory.personal,
      );
}

/// Which stage of the pipeline produced the final decision.
enum DecisionSource {
  userRule,
  threatShield,
  otpDetector,
  semanticIntent,
  aiModel,
  heuristic,
}

/// Output of [SmartClassifier.classify].
class ClassificationResult {
  const ClassificationResult({
    required this.category,
    required this.confidence,
    required this.source,
    this.subCategory,
    this.ruleName,
    this.otpCode,
    this.signals = const [],
    this.probabilities = const {},
    this.intentVector,
    this.whyReasons = const [],
    this.stageBreakdown = const {},
  });

  final MessageCategory category;

  /// 0.0 - 1.0
  final double confidence;
  final DecisionSource source;

  /// Detailed sub-classification (e.g. betting/gambling, phishing, OTP, promotion).
  final MessageSubCategory? subCategory;

  /// Set when [source] is [DecisionSource.userRule] or [DecisionSource.threatShield].
  final String? ruleName;

  /// Extracted one-time verification code when present (e.g. "482913").
  final String? otpCode;

  /// Human-readable diagnostic risk/trust signals detected in the message.
  final List<String> signals;

  /// Per-category probability from the AI model + Semantic Intent combiner.
  final Map<MessageCategory, double> probabilities;

  /// 6-dimensional semantic intent vector ("Dükkan & Hakan Abi" architecture).
  final IntentVector? intentVector;

  /// Plain-language X-Ray explanations ("Neden Spam? / Neden Güvenli?").
  final List<String> whyReasons;

  /// Contribution score per pipeline stage for X-Ray inspection.
  final Map<String, double> stageBreakdown;

  @override
  String toString() =>
      'ClassificationResult(${category.name}, ${confidence.toStringAsFixed(2)}, ${source.name}, sub: ${subCategory?.name})';
}
