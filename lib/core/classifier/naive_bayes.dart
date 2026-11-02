import 'dart:math' as math;

import 'classification.dart';
import 'tokenizer.dart';

/// Multi-class Naive Bayes text classifier with binary features and Laplace
/// smoothing. Small, fast, fully offline and incrementally trainable from user
/// feedback — ideal for on-device SMS filtering.
class NaiveBayesModel {
  NaiveBayesModel();

  static final List<String> labels =
      MessageCategory.values.map((c) => c.label).toList(growable: false);

  /// label -> token -> number of documents containing token.
  final Map<String, Map<String, int>> _tokenDocCounts = {
    for (final l in labels) l: <String, int>{},
  };

  /// label -> number of documents.
  final Map<String, int> _docCounts = {for (final l in labels) l: 0};

  final Set<String> _vocabulary = {};

  int get vocabularySize => _vocabulary.length;
  int get documentCount => _docCounts.values.fold(0, (a, b) => a + b);

  void train(String text, MessageCategory category, {int weight = 1}) {
    final label = category.label;
    final features = Tokenizer.features(text);
    if (features.isEmpty) return;
    _docCounts[label] = _docCounts[label]! + weight;
    final counts = _tokenDocCounts[label]!;
    for (final f in features) {
      counts[f] = (counts[f] ?? 0) + weight;
      _vocabulary.add(f);
    }
  }

  double _logPrior(String label) {
    final total = documentCount;
    return math.log((_docCounts[label]! + 1) / (total + labels.length));
  }

  double _logLikelihood(String label, String token) {
    final count = _tokenDocCounts[label]![token] ?? 0;
    return math.log((count + 1) / (_docCounts[label]! + 2));
  }

  /// Returns normalised probabilities for each category.
  Map<MessageCategory, double> predict(String text) =>
      predictFeatures(Tokenizer.features(text));

  Map<MessageCategory, double> predictFeatures(Set<String> features) {
    final known = features.where(_vocabulary.contains).toList();
    final scores = <String, double>{};
    for (final label in labels) {
      var s = _logPrior(label);
      for (final t in known) {
        s += _logLikelihood(label, t);
      }
      scores[label] = s;
    }
    return softmax(scores).map(
      (label, p) => MapEntry(MessageCategory.fromLabel(label), p),
    );
  }

  static Map<String, double> softmax(Map<String, double> logits) {
    final maxLogit = logits.values.reduce(math.max);
    final exps = logits.map((k, v) => MapEntry(k, math.exp(v - maxLogit)));
    final sum = exps.values.fold(0.0, (a, b) => a + b);
    return exps.map((k, v) => MapEntry(k, v / sum));
  }

  /// log P(spam) - log P(ham)
  double get spamPriorLogRatio =>
      _logPrior(MessageCategory.spam.label) - _logPrior(MessageCategory.normal.label);

  /// Per-token log-likelihood ratio spam vs. ham, consumed by the native
  /// Android/iOS filters for real-time decisions without a Flutter engine.
  /// Only the [limit] most discriminative tokens are exported.
  Map<String, double> exportSpamWeights({int limit = 4000}) {
    final spam = MessageCategory.spam.label;
    final ham = MessageCategory.normal.label;
    final entries = _vocabulary
        .map((t) => MapEntry(t, _logLikelihood(spam, t) - _logLikelihood(ham, t)))
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return {
      for (final e in entries.take(limit))
        e.key: double.parse(e.value.toStringAsFixed(4)),
    };
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'docCounts': _docCounts,
        'tokenDocCounts': _tokenDocCounts,
      };

  factory NaiveBayesModel.fromJson(Map<String, dynamic> json) {
    final model = NaiveBayesModel();
    final docs = (json['docCounts'] as Map).cast<String, dynamic>();
    final tokens = (json['tokenDocCounts'] as Map).cast<String, dynamic>();
    for (final l in labels) {
      model._docCounts[l] = (docs[l] as num?)?.toInt() ?? 0;
      final map = (tokens[l] as Map?)?.cast<String, dynamic>() ?? const {};
      final target = model._tokenDocCounts[l]!;
      map.forEach((t, c) {
        target[t] = (c as num).toInt();
        model._vocabulary.add(t);
      });
    }
    return model;
  }
}
