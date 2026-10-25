import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/classifier/classification.dart';
import '../core/classifier/safe_click_engine.dart';
import '../core/localization/app_localizations.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _senderController = TextEditingController();
  final _controller = TextEditingController();
  HistoryEntry? _result;

  @override
  void dispose() {
    _senderController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _result = AppScope.read(context).analyze(
        text,
        sender: _senderController.text,
      );
    });
  }

  Future<void> _pasteAndAnalyze() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.t('clipboardEmpty'))));
      return;
    }
    _controller.text = text;
    _analyze();
  }

  void _runSample({required String sender, required String text}) {
    _senderController.text = sender;
    _controller.text = text;
    _analyze();
  }

  Future<void> _correct(MessageCategory c) async {
    final app = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final msg = AppLocalizations.of(context).t('feedbackThanks');
    final updated = await app.correct(_result!, c);
    if (!mounted) return;
    setState(() => _result = updated);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final stats = app.stats;
    final shields = app.shieldConfig;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = theme.brightness == Brightness.dark;
    final spamCount = stats[MessageCategory.spam]!;

    final modeDesc = switch (app.protectionMode) {
      ProtectionMode.relaxed => l.t('modeRelaxedDesc'),
      ProtectionMode.balanced => l.t('modeBalancedDesc'),
      ProtectionMode.strict => l.t('modeStrictDesc'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('appTitle')),
        centerTitle: false,
        actions: [
          IconButton(
            key: const Key('themeToggleButton'),
            tooltip: isDark ? l.t('themeLight') : l.t('themeDark'),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => app.toggleThemeMode(theme.brightness),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OtpEmergencyAlertBanner(),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.t('homeHeadline'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.t('homeSubtitle'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l.t('blockedBanner', {'n': '$spamCount'}),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (app.bridge.isAndroid) ...[
            const SizedBox(height: 8),
            _ProtectionTile(active: app.isRealTimeProtectionActive),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _StatCard(
                label: l.t('statsTotal'),
                value: app.history.length,
                color: theme.colorScheme.primary,
              ),
              _StatCard(
                label: l.t('statsSpam'),
                value: spamCount,
                color: CategoryStyle.color(MessageCategory.spam),
              ),
              _StatCard(
                label: l.t('statsTransaction'),
                value: stats[MessageCategory.transaction]!,
                color: CategoryStyle.color(MessageCategory.transaction),
              ),
              _StatCard(
                label: l.t('statsNormal'),
                value: stats[MessageCategory.normal]!,
                color: CategoryStyle.color(MessageCategory.normal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 1-Tap Protection Mode Selector (Esnek / Dengeli / Sıkı)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l.t('protectionModeTitle'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ProtectionMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ProtectionMode.relaxed,
                        label: Text(
                          l.t('modeRelaxed'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment(
                        value: ProtectionMode.balanced,
                        label: Text(
                          l.t('modeBalanced'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment(
                        value: ProtectionMode.strict,
                        label: Text(
                          l.t('modeStrict'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    selected: {app.protectionMode},
                    onSelectionChanged: (s) => app.setProtectionMode(s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    modeDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Built-in Junkman Threat Shield Quick Toggles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l.t('shieldsTitle'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FilterChip(
                        selected: shields.bettingShield,
                        label: Text(l.t('shieldBetting')),
                        onSelected: (v) => app.updateShieldConfig(
                          shields.copyWith(bettingShield: v),
                        ),
                      ),
                      FilterChip(
                        selected: shields.phishingShield,
                        label: Text(l.t('shieldPhishing')),
                        onSelected: (v) => app.updateShieldConfig(
                          shields.copyWith(phishingShield: v),
                        ),
                      ),
                      FilterChip(
                        selected: shields.linkShield,
                        label: Text(l.t('shieldLink')),
                        onSelected: (v) => app.updateShieldConfig(
                          shields.copyWith(linkShield: v),
                        ),
                      ),
                      FilterChip(
                        selected: shields.marketingShield,
                        label: Text(l.t('shieldMarketing')),
                        onSelected: (v) => app.updateShieldConfig(
                          shields.copyWith(marketingShield: v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Test Simulator Chips
          Text(
            l.t('quickSamplesTitle'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: Text(l.t('sampleBetting')),
                  onPressed: () => _runSample(
                    sender: 'VIP-CASINO',
                    text: isTr
                        ? 'Tebrikler! Hesabınıza 1000 TL çevrimsiz deneme bonusu ve 250 freespin tanımlandı! Hemen oyna: cutt.ly/bonus'
                        : 'Congratulations! Claim your 250 freespin casino bonus now at bit.ly/win123',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l.t('samplePhishing')),
                  onPressed: () => _runSample(
                    sender: '+905390000000',
                    text: isTr
                        ? 'Sayın ilgili, hakkınızda açılmış uzlaştırma dosyası bulunmaktadır. Ceza dosyanızın son günüdür: bit.ly/uzlasma'
                        : 'URGENT: Your package is on hold due to unpaid customs fee. Pay now: http://dhl-delivery-fee.info',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l.t('sampleOtp')),
                  onPressed: () => _runSample(
                    sender: 'BANKA',
                    text: isTr
                        ? 'Giriş için tek kullanımlık doğrulama kodunuz 482913. Bu kodu kimseyle paylaşmayın.'
                        : 'Your verification code is 482913. Do not share this code with anyone.',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l.t('sampleMarketing')),
                  onPressed: () => _runSample(
                    sender: 'MAGAZA',
                    text: isTr
                        ? 'Büyük sezon indirimi! Tüm ürünlerde %50 indirim. İptal için RET yaz 3344e gönder MERSIS: 0123456789 B002'
                        : 'Limited time offer! 70% discount on all products. Reply STOP to opt out.',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l.t('sampleHakanAbi')),
                  onPressed: () => _runSample(
                    sender: isTr ? 'Hakan Abi' : 'Shop Partner',
                    text: isTr
                        ? 'Hakan abi emaneti dükkana bıraktım, akşam geçerken alırsın.'
                        : 'Hey brother, I left the package at the shop, pick it up this evening.',
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(l.t('sampleNormal')),
                  onPressed: () => _runSample(
                    sender: isTr ? 'Annem' : 'Mom',
                    text: isTr
                        ? 'Eve gelirken ekmek alır mısın? Teşekkürler'
                        : 'Can you pick up some milk on your way home? Thanks',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('senderInput'),
            controller: _senderController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: l.t('senderHint'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('analyzeInput'),
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: l.t('analyzeHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('analyzeButton'),
              onPressed: _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.t('analyzeButton')),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('pasteAnalyzeButton'),
                  onPressed: _pasteAndAnalyze,
                  icon: const Icon(Icons.content_paste_go, size: 18),
                  label: Text(
                    l.t('pasteAndAnalyze'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() {
                  _senderController.clear();
                  _controller.clear();
                  _result = null;
                }),
                child: Text(l.t('clearButton')),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(entry: _result!, onCorrect: _correct),
          ],
          const SizedBox(height: 12),
          const _SafeClickScannerCard(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.t('privacyNote'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtectionTile extends StatelessWidget {
  const _ProtectionTile({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final color = active
        ? CategoryStyle.color(MessageCategory.normal)
        : theme.colorScheme.error;
    return Card(
      key: const Key('protectionTileCard'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.shield : Icons.shield_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active ? l.t('protectionStatus') : l.t('permGuideTitle'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        active ? l.t('protectionActive') : l.t('permGuideSubtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: active ? color : theme.colorScheme.onSurfaceVariant,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (app.lastInterceptLatencyMs > 0)
                        Text(
                          l.t('interceptLatencyLabel', {
                            'ms': app.lastInterceptLatencyMs.toStringAsFixed(2),
                          }),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!active && defaultTargetPlatform == TargetPlatform.android) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('btnEnableNotificationAccess'),
                    onPressed: app.bridge.openNotificationAccessSettings,
                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                    label: Text(l.t('enableProtection')),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('btnRequestSmsPerm'),
                    onPressed: app.requestSmsPermissions,
                    icon: const Icon(Icons.sms_outlined, size: 16),
                    label: Text(l.t('requestPermissionBtn')),
                  ),
                  OutlinedButton.icon(
                    key: const Key('btnRequestSpamRole'),
                    onPressed: app.requestSpamRole,
                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                    label: Text(l.t('requestRoleBtn')),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.entry, required this.onCorrect});

  final HistoryEntry entry;
  final ValueChanged<MessageCategory> onCorrect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final theme = Theme.of(context);
    final color = CategoryStyle.color(entry.category);
    final targetItem = (entry.sender != null && entry.sender!.trim().isNotEmpty)
        ? entry.sender!.trim()
        : entry.text;

    return Card(
      key: const Key('resultCard'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.t('resultTitle'),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (entry.subCategory != null)
                        Text(
                          CategoryStyle.subCategoryLabel(l, entry.subCategory!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                CategoryChip(category: entry.category),
              ],
            ),
            if (entry.otpCode != null) OtpCopyBanner(code: entry.otpCode!),
            const SizedBox(height: 16),
            Text(
              '${l.t('confidence')}: ${(entry.confidence * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: entry.confidence.clamp(0.0, 1.0),
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              '${l.t('reason')}: ${CategoryStyle.reason(l, entry.source, entry.ruleName)}',
              style: theme.textTheme.bodySmall,
            ),
            SignalChipsWrap(signals: entry.signals),
            SafeClickResultSection(
              results: SafeClickEngine.inspectText(entry.text),
            ),
            WhyDecisionSection(entry: entry),
            XRayProbabilitySection(probabilities: entry.probabilities),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.block, size: 16),
                  label: Text(l.t('addToBlacklist')),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final msg = l.t('addedToBlacklist', {'item': targetItem});
                    await app.addBlacklistItem(targetItem);
                    messenger.showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: Text(l.t('addToWhitelist')),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final msg = l.t('addedToWhitelist', {'item': targetItem});
                    await app.addWhitelistItem(targetItem);
                    messenger.showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
                FilledButton.tonalIcon(
                  key: const Key('reportFalsePositiveBtn'),
                  icon: const Icon(Icons.campaign_outlined, size: 16),
                  label: Text(l.t('reportButtonLabel')),
                  onPressed: () =>
                      ReportFalsePositiveSheet.show(context, entry: entry),
                ),
              ],
            ),
            const Divider(height: 24),
            CorrectionBar(current: entry.category, onSelected: _onCorrectProxy),
          ],
        ),
      ),
    );
  }

  void _onCorrectProxy(MessageCategory c) => onCorrect(c);
}

/// FAZ 5 — [1] Standalone Safe-Click URL X-Ray Scanner Card.
class _SafeClickScannerCard extends StatefulWidget {
  const _SafeClickScannerCard();

  @override
  State<_SafeClickScannerCard> createState() => _SafeClickScannerCardState();
}

class _SafeClickScannerCardState extends State<_SafeClickScannerCard> {
  final _urlCtrl = TextEditingController();
  List<SafeClickLinkResult> _results = const [];

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _scan() {
    final raw = _urlCtrl.text.trim();
    if (raw.isEmpty) return;
    final extracted = SafeClickEngine.inspectText(raw);
    setState(() {
      _results = extracted.isNotEmpty
          ? extracted
          : [SafeClickEngine.analyzeUrl(raw)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: const Key('safeClickScannerCard'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.t('safeClickTitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('safeClickInput'),
              controller: _urlCtrl,
              onSubmitted: (_) => _scan(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link),
                hintText: l.t('safeClickHint'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('safeClickScanBtn'),
              onPressed: _scan,
              icon: const Icon(Icons.radar_outlined, size: 18),
              label: Text(l.t('safeClickScanBtn')),
            ),
            if (_results.isNotEmpty) SafeClickResultSection(results: _results),
          ],
        ),
      ),
    );
  }
}
