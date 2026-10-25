import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/classifier/classification.dart';
import '../core/localization/app_localizations.dart';
import '../core/rules/rule_engine.dart';
import 'widgets.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static Future<void> openEditor(BuildContext context, [FilterRule? rule]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RuleEditorSheet(
        initial: rule ?? AppScope.read(context).newRule(),
        isNew: rule == null,
      ),
    );
  }

  static Future<void> openTemplates(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final templates = RuleEngine.builtInTemplates();

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  l.t('templatesTitle'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final tpl = templates[i];
                    return ListTile(
                      leading: Icon(
                        tpl.type == RuleType.regex
                            ? Icons.code
                            : Icons.text_fields,
                        color: CategoryStyle.color(tpl.action),
                      ),
                      title: Text(tpl.name),
                      subtitle: Text(
                        tpl.pattern,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: FilledButton.tonalIcon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final msg = l.t('templateAdded');
                          await app.upsertRule(tpl);
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(SnackBar(content: Text(msg)));
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.t('addRule')),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _targetLabel(AppLocalizations l, RuleTarget t) => switch (t) {
        RuleTarget.any => l.t('targetAny'),
        RuleTarget.sender => l.t('targetSender'),
        RuleTarget.body => l.t('targetBody'),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('navRules')),
        actions: [
          TextButton.icon(
            onPressed: () => openTemplates(context),
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(l.t('templatesButton')),
          ),
          if (app.rules.isNotEmpty)
            IconButton(
              tooltip: l.t('exportRules'),
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: app.exportRulesJson()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.t('rulesExported'))),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addRuleFab'),
        onPressed: () => openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.t('addRule')),
      ),
      body: Column(
        children: [
          const _SimpleListsCard(),
          Expanded(
            child: app.rules.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.t('rulesEmpty'), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => openTemplates(context),
                            icon: const Icon(Icons.auto_fix_high),
                            label: Text(l.t('templatesTitle')),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: app.rules.length,
                    // ignore: deprecated_member_use
                    onReorder: app.reorderRules,
                    itemBuilder: (context, i) {
                      final r = app.rules[i];
                      final typeStr = r.type == RuleType.regex
                          ? l.t('ruleTypeRegex')
                          : l.t('ruleTypeKeyword');
                      final targetStr = _targetLabel(l, r.target);
                      return ListTile(
                        key: ValueKey(r.id),
                        leading: Icon(
                          r.type == RuleType.regex
                              ? Icons.code
                              : Icons.text_fields,
                          color: CategoryStyle.color(r.action),
                        ),
                        title: Text(r.name.isEmpty ? r.pattern : r.name),
                        subtitle: Text(
                          '$typeStr ($targetStr) → ${CategoryStyle.label(l, r.action)}\n${r.pattern}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: Switch(
                          value: r.enabled,
                          onChanged: (v) =>
                              app.upsertRule(r.copyWith(enabled: v)),
                        ),
                        onTap: () => openEditor(context, r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SimpleListsCard extends StatefulWidget {
  const _SimpleListsCard();

  @override
  State<_SimpleListsCard> createState() => _SimpleListsCardState();
}

class _SimpleListsCardState extends State<_SimpleListsCard> {
  bool _showBlacklist = true;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _ctrl.clear();
    if (_showBlacklist) {
      await app.addBlacklistItem(v);
      messenger.showSnackBar(
        SnackBar(content: Text(l.t('addedToBlacklist'))),
      );
    } else {
      await app.addWhitelistItem(v);
      messenger.showSnackBar(
        SnackBar(content: Text(l.t('addedToWhitelist'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final items = _showBlacklist ? app.blacklist : app.whitelist;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.block, size: 16),
                  label: Text(
                    '${l.t('blacklistTitle')} (${app.blacklist.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text(
                    '${l.t('whitelistTitle')} (${app.whitelist.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {_showBlacklist},
              onSelectionChanged: (s) =>
                  setState(() => _showBlacklist = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _showBlacklist ? l.t('blacklistDesc') : l.t('whitelistDesc'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('simpleListInput'),
                    controller: _ctrl,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _showBlacklist
                          ? l.t('blacklistHint')
                          : l.t('whitelistHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  key: const Key('simpleListAddButton'),
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.t('addSimpleItem')),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final item in items)
                    InputChip(
                      avatar: Icon(
                        _showBlacklist
                            ? Icons.block
                            : Icons.verified_user_outlined,
                        size: 16,
                        color: _showBlacklist
                            ? theme.colorScheme.error
                            : Colors.green,
                      ),
                      label: Text(item),
                      onDeleted: () => _showBlacklist
                          ? app.removeBlacklistItem(item)
                          : app.removeWhitelistItem(item),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RuleEditorSheet extends StatefulWidget {
  const RuleEditorSheet({super.key, required this.initial, required this.isNew});

  final FilterRule initial;
  final bool isNew;

  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _pattern;
  final _test = TextEditingController();
  late RuleType _type;
  late RuleTarget _target;
  late MessageCategory _action;
  late bool _caseSensitive;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _name = TextEditingController(text: r.name);
    _pattern = TextEditingController(text: r.pattern);
    _type = r.type;
    _target = r.target;
    _action = r.action;
    _caseSensitive = r.caseSensitive;
    _enabled = r.enabled;
  }

  @override
  void dispose() {
    _name.dispose();
    _pattern.dispose();
    _test.dispose();
    super.dispose();
  }

  FilterRule get _draft => widget.initial.copyWith(
        name: _name.text.trim(),
        pattern: _pattern.text,
        type: _type,
        target: _target,
        action: _action,
        caseSensitive: _caseSensitive,
        enabled: true,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    final rule = _draft.copyWith(
      enabled: _enabled,
      name: _name.text.trim().isEmpty ? _pattern.text.trim() : _name.text.trim(),
    );
    await app.upsertRule(rule);
    nav.pop();
  }

  Future<void> _delete() async {
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    await app.deleteRule(widget.initial.id);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final testText = _test.text;
    final patternValid =
        FilterRule.validatePattern(_pattern.text, _type) == null;
    final matches = testText.isNotEmpty &&
        patternValid &&
        _draft.matches(testText, sender: testText);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isNew ? l.t('addRule') : l.t('editRule'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l.t('ruleName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<RuleType>(
                segments: [
                  ButtonSegment(
                    value: RuleType.keyword,
                    label: Text(l.t('ruleTypeKeyword')),
                    icon: const Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: RuleType.regex,
                    label: Text(l.t('ruleTypeRegex')),
                    icon: const Icon(Icons.code),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              Text(
                l.t('ruleTargetLabel'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              SegmentedButton<RuleTarget>(
                segments: [
                  ButtonSegment(
                    value: RuleTarget.any,
                    label: Text(l.t('targetAny')),
                  ),
                  ButtonSegment(
                    value: RuleTarget.sender,
                    label: Text(l.t('targetSender')),
                  ),
                  ButtonSegment(
                    value: RuleTarget.body,
                    label: Text(l.t('targetBody')),
                  ),
                ],
                selected: {_target},
                onSelectionChanged: (s) => setState(() => _target = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('rulePatternField'),
                controller: _pattern,
                onChanged: (_) => setState(() {}),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: _type == RuleType.regex
                    ? const TextStyle(fontFamily: 'monospace')
                    : null,
                decoration: InputDecoration(
                  labelText: l.t('rulePattern'),
                  helperText: _type == RuleType.keyword
                      ? 'kampanya, bonus, bit.ly'
                      : r'(?i)(win|kazan|bonus)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.t('requiredField');
                  if (FilterRule.validatePattern(v, _type) != null) {
                    return l.t('invalidRegex');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l.t('ruleAction'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<MessageCategory>(
                showSelectedIcon: false,
                segments: [
                  for (final c in MessageCategory.values)
                    ButtonSegment(
                      value: c,
                      icon: Icon(
                        CategoryStyle.icon(c),
                        color: CategoryStyle.color(c),
                      ),
                      label: Text(
                        switch (c) {
                          MessageCategory.normal => l.t('markAsNormal'),
                          MessageCategory.transaction =>
                            l.t('markAsTransaction'),
                          MessageCategory.spam => l.t('markAsSpam'),
                        },
                      ),
                    ),
                ],
                selected: {_action},
                onSelectionChanged: (s) => setState(() => _action = s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.t('ruleCaseSensitive')),
                value: _caseSensitive,
                onChanged: (v) => setState(() => _caseSensitive = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.t('ruleEnabled')),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              TextField(
                controller: _test,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l.t('ruleTestHint'),
                  border: const OutlineInputBorder(),
                  suffixIcon: testText.isEmpty
                      ? null
                      : Icon(
                          matches ? Icons.check_circle : Icons.cancel,
                          color: matches
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                ),
              ),
              if (testText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    matches ? l.t('ruleMatches') : l.t('ruleNoMatch'),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!widget.isNew)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.t('deleteRule')),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.t('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('saveRuleButton'),
                    onPressed: _save,
                    child: Text(l.t('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
