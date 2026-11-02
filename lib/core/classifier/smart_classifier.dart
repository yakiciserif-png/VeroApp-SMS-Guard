import 'dart:math' as math;

import '../rules/rule_engine.dart';
import 'classification.dart';
import 'naive_bayes.dart';
import 'otp_detector.dart';
import 'semantic_intent_engine.dart';
import 'threat_database.dart';
import 'tokenizer.dart';

/// Multi-stage VeroApp SMS Guard classification pipeline ("Dükkan & Hakan Abi"):
///   Stage 1: Normalizasyon (FAZ 2 Homoglyph, De-Obfuscation & Turkish Folding)
///   Stage 2: BTK B-Kodu & Kurumsal Başlık Analizi
///   Stage 3: OTP Fast-Path (0 ms) & Kullanıcı Kuralları
///   Stage 4: Semantik Niyet Motoru (6 Boyutlu Niyet Vektörü + 3/4-gram + Combo Boost) & Tehdit Kalkanları
///   Stage 5: Cihaz İçi Naive Bayes AI + Skor Birleştirici (Score Combiner)
class SmartClassifier {
  SmartClassifier({
    required this.model,
    RuleEngine? rules,
    this.shieldConfig = const ThreatShieldConfig(),
  }) : rules = rules ?? RuleEngine();

  NaiveBayesModel model;
  RuleEngine rules;
  ThreatShieldConfig shieldConfig;

  /// Extra spam logit added for URL shorteners (heavily abused by scammers).
  static const double shortUrlBoost = 2.5;

  /// Extra spam logit when an OTP-like message contains a link (phishing trap).
  static const double otpLinkTrapBoost = 4.0;

  ClassificationResult classify(String text, {String? sender}) {
    if (text.trim().isEmpty) {
      return const ClassificationResult(
        category: MessageCategory.normal,
        confidence: 0,
        source: DecisionSource.aiModel,
        subCategory: MessageSubCategory.personal,
        intentVector: IntentVector.zero,
      );
    }

    // -------------------------------------------------------------------------
    // STAGE 1 & 2: FAZ 2 Normalization + BTK B-Code & Header Analysis
    // -------------------------------------------------------------------------
    final features = Tokenizer.features(text, sender: sender);
    final btk = Tokenizer.analyzeBtk(text, sender: sender);
    final hasUrl = features.contains(Tokenizer.urlToken);
    final hasFakeBCode =
        btk.hasFakeBCodeTrap || features.contains(Tokenizer.fakeBCodeToken);
    final hasForeignNoBCode = btk.isForeignSenderWithoutBCode ||
        features.contains(Tokenizer.foreignNoBCodeToken);
    final hasObfuscation = features.contains(Tokenizer.homoglyphToken) ||
        features.contains(Tokenizer.obfuscatedToken);

    final normRisk = hasObfuscation ? 0.85 : 0.0;
    final btkRisk = hasFakeBCode
        ? 0.96
        : (hasForeignNoBCode ? 0.90 : (btk.hasValidBCode ? 0.15 : 0.0));

    // -------------------------------------------------------------------------
    // STAGE 3A: User-defined rules (deterministic override)
    // -------------------------------------------------------------------------
    final rule = rules.firstMatch(text, sender: sender);
    if (rule != null) {
      final intent = SemanticIntentEngine.analyze(text, sender: sender, btk: btk);
      return ClassificationResult(
        category: rule.action,
        confidence: 1.0,
        source: DecisionSource.userRule,
        subCategory: MessageSubCategory.customRule,
        ruleName: rule.name,
        signals: const ['signalUserRule'],
        intentVector: intent.vector,
        whyReasons: const ['whyUserRuleMatch'],
        stageBreakdown: {
          'stageNormalization': normRisk,
          'stageBtkCheck': btkRisk,
          'stageUserRule': 1.0,
          'stageOtpFastPath': 0.0,
          'stageSemanticIntent': intent.probabilities[rule.action] ?? 0.0,
          'stageNaiveBayes': 0.0,
        },
      );
    }

    // -------------------------------------------------------------------------
    // STAGE 3B: OTP / Bank Transaction Fast-Path (strictly without links or fake B-code)
    // -------------------------------------------------------------------------
    final otp = OtpDetector.analyze(text);
    final nbProbs = model.predictFeatures(features);
    final intent = SemanticIntentEngine.analyze(text, sender: sender, btk: btk);

    if (otp.isTransaction && !hasUrl && !hasFakeBCode && !hasForeignNoBCode) {
      final combinedSignals = <String>{
        if (otp.extractedCode != null) 'signalOtpCode' else 'signalBankTxn',
        ...intent.signals,
      }.toList();
      final combinedWhy = <String>{
        'whyOtpFastPath',
        ...intent.whyReasons,
      }.toList();

      return ClassificationResult(
        category: MessageCategory.transaction,
        confidence: math.max(otp.score, nbProbs[MessageCategory.transaction]!),
        source: DecisionSource.otpDetector,
        subCategory: otp.subCategory ?? MessageSubCategory.otpCode,
        otpCode: otp.extractedCode,
        signals: combinedSignals,
        probabilities: nbProbs,
        intentVector: intent.vector,
        whyReasons: combinedWhy,
        stageBreakdown: {
          'stageNormalization': normRisk,
          'stageBtkCheck': btkRisk,
          'stageOtpFastPath': otp.score,
          'stageUserRule': 0.0,
          'stageSemanticIntent': intent.probabilities[MessageCategory.transaction] ?? 0.85,
          'stageNaiveBayes': nbProbs[MessageCategory.transaction] ?? 0.5,
        },
      );
    }

    // -------------------------------------------------------------------------
    // STAGE 4: Threat Intelligence Shields & Semantic Intent Engine
    // -------------------------------------------------------------------------
    final threat = ThreatDatabase.evaluate(
      text,
      sender: sender,
      config: shieldConfig,
    );

    // -------------------------------------------------------------------------
    // STAGE 5: Naive Bayes + Semantic Intent Score Combiner
    // -------------------------------------------------------------------------
    var boosted = false;
    final logits = {
      for (final e in nbProbs.entries)
        e.key.label: math.log(math.max(e.value, 1e-12)),
    };

    // Blend Semantic Intent Engine probabilities into the combiner logits
    for (final cat in MessageCategory.values) {
      final intentProb = intent.probabilities[cat] ?? 0.33;
      logits[cat.label] = logits[cat.label]! + math.log(math.max(intentProb, 1e-6)) * 0.85;
    }

    if (!otp.isTransaction) {
      logits[MessageCategory.transaction.label] =
          logits[MessageCategory.transaction.label]! - 3.0;
    }

    if (features.contains(Tokenizer.shortUrlToken)) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + shortUrlBoost;
      boosted = true;
    }

    if (features.contains(Tokenizer.suspiciousTldToken)) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + 2.0;
      boosted = true;
    }

    if (hasFakeBCode) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + 3.5;
      boosted = true;
    }

    if (hasForeignNoBCode) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + 3.0;
      boosted = true;
    }

    if (hasObfuscation) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + 2.2;
      boosted = true;
    }

    if (intent.comboMultiplier > 1.2) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + (intent.comboMultiplier * 1.6);
      boosted = true;
    }

    // Strong "Hakan Abi / Dükkan" personal conversation boost when clean
    if (intent.vector.personalChat >= 0.35 &&
        !hasUrl &&
        !threat.isThreat &&
        intent.spamIntentScore < 0.35) {
      logits[MessageCategory.normal.label] =
          logits[MessageCategory.normal.label]! + 2.5;
    }

    // Fake OTP + Link Phishing Trap
    if (otp.isTransaction && hasUrl) {
      logits[MessageCategory.transaction.label] =
          logits[MessageCategory.transaction.label]! - otpLinkTrapBoost;
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + otpLinkTrapBoost;
      boosted = true;
    }

    if (threat.isThreat) {
      logits[MessageCategory.spam.label] =
          logits[MessageCategory.spam.label]! + 3.5;
      boosted = true;
    }

    final adjusted = NaiveBayesModel.softmax(logits)
        .map((k, v) => MapEntry(MessageCategory.fromLabel(k), v));

    final mergedSignals = <String>{
      ...threat.signals,
      ...intent.signals,
    }.toList();

    final mergedWhy = <String>{
      ...intent.whyReasons,
      if (features.contains(Tokenizer.shortUrlToken)) 'whyShortUrl',
      if (features.contains(Tokenizer.suspiciousTldToken)) 'whySuspiciousTld',
      if (otp.isTransaction && hasUrl) 'whyFakeOtpLink',
      if (threat.shieldName == 'shieldMarketing') 'whyCommercialPromo',
    }.toList();

    final stageBreakdown = <String, double>{
      'stageNormalization': double.parse(normRisk.toStringAsFixed(2)),
      'stageBtkCheck': double.parse(btkRisk.toStringAsFixed(2)),
      'stageOtpFastPath': double.parse(otp.score.toStringAsFixed(2)),
      'stageUserRule': 0.0,
      'stageSemanticIntent': double.parse(
        (intent.probabilities[MessageCategory.spam] ?? 0.0).toStringAsFixed(2),
      ),
      'stageNaiveBayes': double.parse(
        (nbProbs[MessageCategory.spam] ?? 0.0).toStringAsFixed(2),
      ),
    };

    if (threat.isThreat) {
      return ClassificationResult(
        category: MessageCategory.spam,
        confidence: math.max(threat.score, adjusted[MessageCategory.spam]!),
        source: otp.isTransaction && hasUrl
            ? DecisionSource.heuristic
            : DecisionSource.threatShield,
        subCategory: threat.subCategory ??
            intent.suggestedSubCategory ??
            MessageSubCategory.generalSpam,
        ruleName: threat.shieldName,
        signals: mergedSignals,
        probabilities: adjusted,
        intentVector: intent.vector,
        whyReasons: mergedWhy.isEmpty ? const ['whySpamPattern'] : mergedWhy,
        stageBreakdown: stageBreakdown,
      );
    }

    // If Semantic Intent Engine strongly detected spam combo/intent even without
    // exact phrase match in ThreatDatabase:
    if (intent.spamIntentScore >= 0.72 &&
        adjusted[MessageCategory.spam]! >= 0.60) {
      return ClassificationResult(
        category: MessageCategory.spam,
        confidence: math.max(
          adjusted[MessageCategory.spam]!,
          intent.probabilities[MessageCategory.spam] ?? 0.85,
        ),
        source: DecisionSource.semanticIntent,
        subCategory: intent.suggestedSubCategory ?? MessageSubCategory.generalSpam,
        signals: mergedSignals,
        probabilities: adjusted,
        intentVector: intent.vector,
        whyReasons: mergedWhy.isEmpty ? const ['whySpamPattern'] : mergedWhy,
        stageBreakdown: stageBreakdown,
      );
    }

    final best = adjusted.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final modelBest = nbProbs.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final source = boosted &&
            best.key == MessageCategory.spam &&
            modelBest.key != MessageCategory.spam
        ? DecisionSource.heuristic
        : DecisionSource.aiModel;

    final subCategory = switch (best.key) {
      MessageCategory.normal => MessageSubCategory.personal,
      MessageCategory.transaction => otp.extractedCode != null
          ? MessageSubCategory.otpCode
          : MessageSubCategory.bankTransaction,
      MessageCategory.spam => intent.suggestedSubCategory ??
          (features.contains(Tokenizer.shortUrlToken) || hasUrl
              ? MessageSubCategory.suspiciousLink
              : (features.contains(Tokenizer.bCodeToken)
                  ? MessageSubCategory.marketingPromotion
                  : MessageSubCategory.generalSpam)),
    };

    if (best.key == MessageCategory.normal && mergedWhy.isEmpty) {
      mergedWhy.add('whyPersonalChatContext');
    } else if (best.key == MessageCategory.spam && mergedWhy.isEmpty) {
      mergedWhy.add('whySpamPattern');
    }

    return ClassificationResult(
      category: best.key,
      confidence: best.value,
      source: source,
      subCategory: subCategory,
      otpCode: best.key == MessageCategory.transaction
          ? OtpDetector.extractCode(text)
          : null,
      signals: mergedSignals,
      probabilities: adjusted,
      intentVector: intent.vector,
      whyReasons: mergedWhy,
      stageBreakdown: stageBreakdown,
    );
  }
}
