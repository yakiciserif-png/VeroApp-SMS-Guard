import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/classifier/classification.dart';
import '../core/classifier/safe_click_engine.dart';
import '../core/classifier/semantic_intent_engine.dart';
import '../core/localization/app_localizations.dart';
import '../models/history_entry.dart';

/// Shared visual helpers for categories, sub-categories & decision sources.
class CategoryStyle {
  CategoryStyle._();

  static Color color(MessageCategory c) => switch (c) {
        MessageCategory.normal => const Color(0xFF2E7D32),
        MessageCategory.transaction => const Color(0xFF1565C0),
        MessageCategory.spam => const Color(0xFFC62828),
      };

  static IconData icon(MessageCategory c) => switch (c) {
        MessageCategory.normal => Icons.mark_chat_read_outlined,
        MessageCategory.transaction => Icons.password,
        MessageCategory.spam => Icons.gpp_bad_outlined,
      };

  static String label(AppLocalizations l, MessageCategory c) => switch (c) {
        MessageCategory.normal => l.t('categoryNormal'),
        MessageCategory.transaction => l.t('categoryTransaction'),
        MessageCategory.spam => l.t('categorySpam'),
      };

  static String subCategoryLabel(AppLocalizations l, MessageSubCategory sub) =>
      switch (sub) {
        MessageSubCategory.personal => l.t('subPersonal'),
        MessageSubCategory.otpCode => l.t('subOtpCode'),
        MessageSubCategory.bankTransaction => l.t('subBankTxn'),
        MessageSubCategory.bettingGambling => l.t('subBetting'),
        MessageSubCategory.phishingScam => l.t('subPhishing'),
        MessageSubCategory.deliveryCustomsScam => l.t('subDeliveryScam'),
        MessageSubCategory.governmentScam => l.t('subGovScam'),
        MessageSubCategory.marketingPromotion => l.t('subMarketing'),
        MessageSubCategory.suspiciousLink => l.t('subSuspiciousLink'),
        MessageSubCategory.customRule => l.t('subCustomRule'),
        MessageSubCategory.generalSpam => l.t('subGeneralSpam'),
      };

  static String reason(
    AppLocalizations l,
    DecisionSource s,
    String? ruleName,
  ) =>
      switch (s) {
        DecisionSource.userRule =>
          l.t('reasonUserRule', {'name': ruleName ?? ''}),
        DecisionSource.threatShield =>
          l.t('reasonThreatShield', {'name': ruleName != null ? l.t(ruleName) : ''}),
        DecisionSource.otpDetector => l.t('reasonOtpDetector'),
        DecisionSource.semanticIntent => l.t('reasonSemanticIntent'),
        DecisionSource.aiModel => l.t('reasonAiModel'),
        DecisionSource.heuristic => l.t('reasonHeuristic'),
      };
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.dense = false});

  final MessageCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = CategoryStyle.color(category);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CategoryStyle.icon(category), size: dense ? 14 : 18, color: c),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              CategoryStyle.label(AppLocalizations.of(context), category),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w600,
                fontSize: dense ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive banner that displays an extracted OTP verification code and
/// copies it to the clipboard with a single tap.
class OtpCopyBanner extends StatelessWidget {
  const OtpCopyBanner({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.key, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('otpExtractedLabel'),
                      style: theme.textTheme.labelSmall,
                    ),
                    SelectableText(
                      code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.t('otpCopied', {'code': code}))),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l.t('copyOtpButton')),
          ),
        ],
      ),
    );
  }
}

/// Plain-language "Neden Spam? / Neden Bu Karar Verildi?" X-Ray card,
/// plus 6D Semantic Intent Vector and Pipeline Stage Breakdown.
class WhyDecisionSection extends StatelessWidget {
  const WhyDecisionSection({
    super.key,
    required this.entry,
  });

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = CategoryStyle.color(entry.category);
    final reasons = entry.whyReasons;
    final vec = entry.intentVector;

    if (reasons.isEmpty && vec == null) return const SizedBox.shrink();

    return Container(
      key: const Key('whyDecisionCard'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.t('whyCardTitle'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        entry.category == MessageCategory.spam
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 15,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.t(r),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (vec != null) ...[
            const SizedBox(height: 10),
            _IntentVectorBars(vector: vec),
          ],
        ],
      ),
    );
  }
}

class _IntentVectorBars extends StatelessWidget {
  const _IntentVectorBars({required this.vector});

  final IntentVector vector;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dims = <(String, double, Color)>[
      (l.t('intentUrgency'), vector.urgencyFear, const Color(0xFFD32F2F)),
      (l.t('intentFinancial'), vector.financialTrap, const Color(0xFFE65100)),
      (l.t('intentReward'), vector.rewardBetting, const Color(0xFFC62828)),
      (l.t('intentLink'), vector.actionLink, const Color(0xFFAD1457)),
      (l.t('intentOtp'), vector.corporateOtp, const Color(0xFF1565C0)),
      (l.t('intentPersonal'), vector.personalChat, const Color(0xFF2E7D32)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('intentVectorTitle'),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (final d in dims)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    d.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: d.$2.clamp(0.0, 1.0),
                    color: d.$3,
                    backgroundColor: d.$3.withValues(alpha: 0.14),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(d.$2 * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Visualizes the AI probability breakdown across all categories.
class XRayProbabilitySection extends StatelessWidget {
  const XRayProbabilitySection({super.key, required this.probabilities});

  final Map<MessageCategory, double> probabilities;

  @override
  Widget build(BuildContext context) {
    if (probabilities.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          l.t('xrayTitle'),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        for (final c in MessageCategory.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    CategoryStyle.label(l, c),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (probabilities[c] ?? 0.0).clamp(0.0, 1.0),
                    color: CategoryStyle.color(c),
                    backgroundColor:
                        CategoryStyle.color(c).withValues(alpha: 0.15),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${((probabilities[c] ?? 0.0) * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Displays diagnostic threat/trust signals as compact chips.
class SignalChipsWrap extends StatelessWidget {
  const SignalChipsWrap({super.key, required this.signals});

  final List<String> signals;

  @override
  Widget build(BuildContext context) {
    if (signals.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in signals)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.t(s),
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Three buttons letting the user re-label a message (trains the model).
class CorrectionBar extends StatelessWidget {
  const CorrectionBar({super.key, required this.current, required this.onSelected});

  final MessageCategory current;
  final ValueChanged<MessageCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      MessageCategory.normal: l.t('markAsNormal'),
      MessageCategory.transaction: l.t('markAsTransaction'),
      MessageCategory.spam: l.t('markAsSpam'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.t('correctPrompt'), style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in MessageCategory.values)
              ActionChip(
                avatar: Icon(CategoryStyle.icon(c), size: 18, color: CategoryStyle.color(c)),
                label: Text(labels[c]!),
                onPressed: c == current ? null : () => onSelected(c),
              ),
          ],
        ),
      ],
    );
  }
}

String formatTimestamp(BuildContext context, DateTime t) {
  final m = MaterialLocalizations.of(context);
  return '${m.formatShortDate(t)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(t))}';
}

IconData originIcon(MessageOrigin o) => switch (o) {
      MessageOrigin.manual => Icons.edit_note,
      MessageOrigin.notification => Icons.notifications_active_outlined,
    };

/// FAZ 5 — [1] SAFE-CLICK URL X-Ray & Link Security Breakdown Card.
class SafeClickResultSection extends StatelessWidget {
  const SafeClickResultSection({super.key, required this.results});

  final List<SafeClickLinkResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('safeClickSection'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.policy_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.t('safeClickDetectedTitle'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in results) ...[
            _SafeClickLinkRow(result: r),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _SafeClickLinkRow extends StatelessWidget {
  const _SafeClickLinkRow({required this.result});

  final SafeClickLinkResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = switch (result.riskLevel) {
      SafeClickRisk.safe => const Color(0xFF10B981),
      SafeClickRisk.caution => const Color(0xFFF59E0B),
      SafeClickRisk.critical => const Color(0xFFEF4444),
    };
    final levelText = switch (result.riskLevel) {
      SafeClickRisk.safe => l.t('safeClickLevelSafe'),
      SafeClickRisk.caution => l.t('safeClickLevelCaution'),
      SafeClickRisk.critical => l.t('safeClickLevelCritical'),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 16, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      result.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$levelText (${result.riskScore}/100)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (result.impersonatedBrand != null) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ ${result.impersonatedBrand}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 4),
          for (final key in result.findingKeys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '• ${l.t(key)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// FAZ 5 — [2] OTP-ALERT Emergency Banner (Account Takeover / SMS Bombing).
class OtpEmergencyAlertBanner extends StatelessWidget {
  const OtpEmergencyAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isOtpAttackActive) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = app.recentOtpCount();

    return Card(
      key: const Key('otpEmergencyBanner'),
      color: const Color(0xFF7F1D1D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFCA5A5),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.t('otpAlertTitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.t('otpAlertSubtitle', {'n': '$count'}),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFFECACA),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('otpAlertAdvice'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                key: const Key('dismissOtpAlertBtn'),
                onPressed: app.dismissOtpAlert,
                child: Text(l.t('otpAlertDismiss')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAZ 5 — False Positive / Missed Spam Reporting & Local AI Training Sheet.
class ReportFalsePositiveSheet extends StatefulWidget {
  const ReportFalsePositiveSheet({super.key, this.entry});

  final HistoryEntry? entry;

  static Future<void> show(BuildContext context, {HistoryEntry? entry}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReportFalsePositiveSheet(entry: entry),
    );
  }

  @override
  State<ReportFalsePositiveSheet> createState() =>
      _ReportFalsePositiveSheetState();
}

class _ReportFalsePositiveSheetState extends State<ReportFalsePositiveSheet> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _senderCtrl;
  late MessageCategory _expected;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.entry?.text ?? '');
    _senderCtrl = TextEditingController(text: widget.entry?.sender ?? '');
    _expected = widget.entry?.category == MessageCategory.spam
        ? MessageCategory.normal
        : MessageCategory.spam;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _senderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final msg = l.t('reportSuccessMsg');
    await app.reportAndTrain(
      text: text,
      sender: _senderCtrl.text.trim(),
      expectedCategory: _expected,
      existingEntry: widget.entry,
    );
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.t('reportSheetTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(l.t('reportSheetDesc'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reportSenderInput'),
              controller: _senderCtrl,
              decoration: InputDecoration(
                hintText: l.t('senderHint'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('reportTextInput'),
              controller: _textCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l.t('analyzeHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.t('reportExpectedLabel'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<MessageCategory>(
              segments: [
                ButtonSegment(
                  value: MessageCategory.normal,
                  label: Text(
                    l.t('markAsNormal'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: MessageCategory.transaction,
                  label: Text(
                    l.t('markAsTransaction'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: MessageCategory.spam,
                  label: Text(
                    l.t('markAsSpam'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {_expected},
              onSelectionChanged: (s) => setState(() => _expected = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('submitReportBtn'),
              onPressed: _submit,
              icon: const Icon(Icons.model_training),
              label: Text(l.t('reportSubmitBtn')),
            ),
          ],
        ),
      ),
    );
  }
}
