import '../core/classifier/classification.dart';
import '../core/classifier/semantic_intent_engine.dart';

enum MessageOrigin { manual, notification }

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.text,
    required this.category,
    required this.confidence,
    required this.source,
    required this.timestamp,
    this.origin = MessageOrigin.manual,
    this.sender,
    this.ruleName,
    this.subCategory,
    this.otpCode,
    this.signals = const [],
    this.probabilities = const {},
    this.intentVector,
    this.whyReasons = const [],
    this.stageBreakdown = const {},
    this.corrected = false,
  });

  final String id;
  final String text;
  final MessageCategory category;
  final double confidence;
  final DecisionSource source;
  final DateTime timestamp;
  final MessageOrigin origin;
  final String? sender;
  final String? ruleName;
  final MessageSubCategory? subCategory;
  final String? otpCode;
  final List<String> signals;
  final Map<MessageCategory, double> probabilities;
  final IntentVector? intentVector;
  final List<String> whyReasons;
  final Map<String, double> stageBreakdown;
  final bool corrected;

  HistoryEntry copyWith({MessageCategory? category, bool? corrected}) =>
      HistoryEntry(
        id: id,
        text: text,
        category: category ?? this.category,
        confidence: corrected == true ? 1.0 : confidence,
        source: source,
        timestamp: timestamp,
        origin: origin,
        sender: sender,
        ruleName: ruleName,
        subCategory: subCategory,
        otpCode: otpCode,
        signals: signals,
        probabilities: probabilities,
        intentVector: intentVector,
        whyReasons: whyReasons,
        stageBreakdown: stageBreakdown,
        corrected: corrected ?? this.corrected,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category.label,
        'confidence': confidence,
        'source': source.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'origin': origin.name,
        'sender': sender,
        'ruleName': ruleName,
        'subCategory': subCategory?.id,
        'otpCode': otpCode,
        'signals': signals,
        'probabilities': {
          for (final e in probabilities.entries) e.key.label: e.value,
        },
        if (intentVector != null) 'intentVector': intentVector!.toMap(),
        'whyReasons': whyReasons,
        'stageBreakdown': stageBreakdown,
        'corrected': corrected,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) {
    final rawProbs = (j['probabilities'] as Map?)?.cast<String, dynamic>();
    final probs = <MessageCategory, double>{};
    if (rawProbs != null) {
      rawProbs.forEach((k, v) {
        probs[MessageCategory.fromLabel(k)] = (v as num).toDouble();
      });
    }

    final rawStages = (j['stageBreakdown'] as Map?)?.cast<String, dynamic>();
    final stages = <String, double>{};
    if (rawStages != null) {
      rawStages.forEach((k, v) {
        stages[k] = (v as num).toDouble();
      });
    }

    return HistoryEntry(
      id: j['id'] as String,
      text: j['text'] as String? ?? '',
      category: MessageCategory.fromLabel(j['category'] as String? ?? 'ham'),
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      source: DecisionSource.values.firstWhere(
        (s) => s.name == j['source'],
        orElse: () => DecisionSource.aiModel,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['timestamp'] as num?)?.toInt() ?? 0,
      ),
      origin: MessageOrigin.values.firstWhere(
        (o) => o.name == j['origin'],
        orElse: () => MessageOrigin.manual,
      ),
      sender: j['sender'] as String?,
      ruleName: j['ruleName'] as String?,
      subCategory: j['subCategory'] != null
          ? MessageSubCategory.fromId(j['subCategory'] as String)
          : null,
      otpCode: j['otpCode'] as String?,
      signals: (j['signals'] as List?)?.cast<String>() ?? const [],
      probabilities: probs,
      intentVector: j['intentVector'] != null
          ? IntentVector.fromMap((j['intentVector'] as Map).cast<String, dynamic>())
          : null,
      whyReasons: (j['whyReasons'] as List?)?.cast<String>() ?? const [],
      stageBreakdown: stages,
      corrected: j['corrected'] as bool? ?? false,
    );
  }
}
