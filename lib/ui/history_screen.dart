import 'package:flutter/material.dart';

import '../app.dart';
import '../core/classifier/safe_click_engine.dart';
import '../core/localization/app_localizations.dart';
import '../core/rules/rule_engine.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';
import 'rules_screen.dart';
import 'widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  SmartInboxFolder _folder = SmartInboxFolder.all;
  String _query = '';

  Future<void> _confirmClear(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('historyClear')),
        content: Text(l.t('historyClearConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.t('confirm')),
          ),
        ],
      ),
    );
    if (ok == true) await app.clearHistory();
  }

  Future<void> _import(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final n = await AppScope.read(context).importPendingMessages();
    messenger.showSnackBar(
      SnackBar(content: Text(l.t('syncedCount', {'n': '$n'}))),
    );
  }

  void _openDetail(BuildContext context, HistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HistoryDetail(entryId: entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final counts = app.folderCounts;

    final filtered = app.history.where((e) {
      if (_folder != SmartInboxFolder.all && app.folderForEntry(e) != _folder) {
        return false;
      }
      if (_query.trim().isNotEmpty) {
        final q = _query.toLowerCase();
        final matchText = e.text.toLowerCase().contains(q);
        final matchSender = e.sender?.toLowerCase().contains(q) ?? false;
        if (!matchText && !matchSender) return false;
      }
      return true;
    }).toList();

    final folders = <(SmartInboxFolder, String, Key)>[
      (SmartInboxFolder.all, l.t('folderAll'), const Key('folder_all')),
      (SmartInboxFolder.finance, l.t('folderFinance'), const Key('folder_finance')),
      (SmartInboxFolder.deliveryAppointment, l.t('folderDelivery'), const Key('folder_delivery')),
      (SmartInboxFolder.personalChat, l.t('folderPersonal'), const Key('folder_personal')),
      (SmartInboxFolder.spam, l.t('folderSpam'), const Key('folder_spam')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('navHistory')),
        actions: [
          if (app.bridge.isAndroid)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _import(context),
            ),
          IconButton(
            key: const Key('historyAutoCleanerBtn'),
            tooltip: l.t('autoCleanRunNowBtn'),
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: app.history.isEmpty
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final n = await app.runAutoCleaner(cleanAllOtpNow: true);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l.t('autoCleanResultMsg', {'n': '$n'})),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: l.t('historyClear'),
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: app.history.isEmpty ? null : () => _confirmClear(context),
          ),
        ],
      ),
      body: app.history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.t('historyEmpty'), textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.t('searchHistoryHint'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      for (final f in folders) ...[
                        ChoiceChip(
                          key: f.$3,
                          label: Text('${f.$2} (${counts[f.$1] ?? 0})'),
                          selected: _folder == f.$1,
                          onSelected: (_) => setState(() => _folder = f.$1),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(Icons.delete_outline),
                        ),
                        onDismissed: (_) => app.deleteHistoryEntry(e.id),
                        child: ListTile(
                          leading: Icon(
                            CategoryStyle.icon(e.category),
                            color: CategoryStyle.color(e.category),
                          ),
                          title: Text(
                            e.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Icon(originIcon(e.origin), size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  [
                                    if (e.sender != null) e.sender!,
                                    if (e.subCategory != null)
                                      CategoryStyle.subCategoryLabel(
                                        l,
                                        e.subCategory!,
                                      ),
                                    formatTimestamp(context, e.timestamp),
                                  ].join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          trailing: CategoryChip(
                            category: e.category,
                            dense: true,
                          ),
                          onTap: () => _openDetail(context, e),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  const _HistoryDetail({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final idx = app.history.indexWhere((h) => h.id == entryId);
    if (idx < 0) return const SizedBox.shrink();
    final e = app.history[idx];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryChip(category: e.category),
                  const SizedBox(width: 8),
                  if (e.subCategory != null)
                    Expanded(
                      child: Text(
                        CategoryStyle.subCategoryLabel(l, e.subCategory!),
                        style: Theme.of(context).textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  Text('${(e.confidence * 100).toStringAsFixed(0)}%'),
                ],
              ),
              if (e.otpCode != null) OtpCopyBanner(code: e.otpCode!),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(child: SelectableText(e.text)),
              ),
              const SizedBox(height: 12),
              Text(
                '${l.t('reason')}: ${CategoryStyle.reason(l, e.source, e.ruleName)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${e.origin == MessageOrigin.manual ? l.t('sourceManual') : l.t('sourceNotification')} · ${formatTimestamp(context, e.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SignalChipsWrap(signals: e.signals),
              SafeClickResultSection(
                results: SafeClickEngine.inspectText(e.text),
              ),
              WhyDecisionSection(entry: e),
              XRayProbabilitySection(probabilities: e.probabilities),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final seedRule = app.newRule().copyWith(
                            name: e.sender ?? 'Özel Kural',
                            pattern: e.sender ?? e.text,
                            target: e.sender != null
                                ? RuleTarget.sender
                                : RuleTarget.body,
                            action: e.category,
                          );
                      RulesScreen.openEditor(context, seedRule);
                    },
                    icon: const Icon(Icons.rule, size: 18),
                    label: Text(l.t('createRuleFromEntry')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ReportFalsePositiveSheet.show(context, entry: e),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: Text(l.t('reportButtonLabel')),
                  ),
                ],
              ),
              const Divider(height: 24),
              CorrectionBar(
                current: e.category,
                onSelected: (c) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final msg = l.t('feedbackThanks');
                  await app.correct(e, c);
                  messenger.showSnackBar(SnackBar(content: Text(msg)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
