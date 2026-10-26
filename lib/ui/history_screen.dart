import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/classifier/classification.dart';
import '../core/classifier/safe_click_engine.dart';
import '../core/classifier/semantic_intent_engine.dart';
import '../core/localization/app_localizations.dart';
import '../core/rules/rule_engine.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';
import 'cyberpunk_theme.dart';
import 'rules_screen.dart';
import 'widgets.dart';

/// Built-in realistic inbox items displayed in WhatsApp-style inbox views
/// alongside live intercepted SMS messages (does not mutate AppState.history).
List<HistoryEntry> builtInInboxEntries(bool isTr) {
  final now = DateTime.now();
  return [
    HistoryEntry(
      id: 'inbox_ziraat_otp',
      sender: isTr ? 'Ziraat Bankası' : 'Ziraat Bank',
      text: isTr
          ? 'Onay kodunuz 324324. Mobil bankacılık giriş işleminiz için bu kodu kimseyle paylaşmayın. B001'
          : 'Your verification code is 324324. Do not share this code with anyone.',
      category: MessageCategory.transaction,
      subCategory: MessageSubCategory.otpCode,
      confidence: 0.99,
      source: DecisionSource.otpDetector,
      otpCode: '324324',
      signals: const ['signalOtpCode'],
      whyReasons: const ['whyOtpFastPath'],
      intentVector: const IntentVector(
        urgencyFear: 0.05,
        financialTrap: 0.02,
        rewardBetting: 0.0,
        actionLink: 0.0,
        corporateOtp: 0.98,
        personalChat: 0.05,
      ),
      timestamp: now.subtract(const Duration(minutes: 4)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_isbank_otp',
      sender: isTr ? 'İş Bankası' : 'IsBank',
      text: isTr
          ? 'Doğrulama kodunuz 234234 ile İşCep işleminizi tamamlayabilirsiniz. B002'
          : 'Your verification code is 234234 to complete your mobile banking transaction.',
      category: MessageCategory.transaction,
      subCategory: MessageSubCategory.otpCode,
      confidence: 0.99,
      source: DecisionSource.otpDetector,
      otpCode: '234234',
      signals: const ['signalOtpCode'],
      whyReasons: const ['whyOtpFastPath'],
      intentVector: const IntentVector(
        urgencyFear: 0.04,
        financialTrap: 0.02,
        rewardBetting: 0.0,
        actionLink: 0.0,
        corporateOtp: 0.97,
        personalChat: 0.04,
      ),
      timestamp: now.subtract(const Duration(minutes: 19)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_garanti_otp',
      sender: 'Garanti BBVA',
      text: isTr
          ? '3D Secure alışverişiniz için tek kullanımlık doğrulama şifreniz: 589104. Kimseyle paylaşmayınız. B002'
          : 'Your 3D Secure one-time password is 589104. Never share this code.',
      category: MessageCategory.transaction,
      subCategory: MessageSubCategory.otpCode,
      confidence: 0.98,
      source: DecisionSource.otpDetector,
      otpCode: '589104',
      signals: const ['signalOtpCode', 'signalBankTxn'],
      whyReasons: const ['whyOtpFastPath'],
      intentVector: const IntentVector(
        urgencyFear: 0.05,
        financialTrap: 0.03,
        rewardBetting: 0.0,
        actionLink: 0.0,
        corporateOtp: 0.96,
        personalChat: 0.03,
      ),
      timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_akbank_txn',
      sender: 'Akbank',
      text: isTr
          ? 'Akbank Mobil giriş doğrulama kodunuz: 741852. İşlemi siz yapmadıysanız 444 25 25\'i arayın. B001'
          : 'Your Akbank Mobile login verification code is 741852.',
      category: MessageCategory.transaction,
      subCategory: MessageSubCategory.otpCode,
      confidence: 0.98,
      source: DecisionSource.otpDetector,
      otpCode: '741852',
      signals: const ['signalOtpCode'],
      whyReasons: const ['whyOtpFastPath'],
      timestamp: now.subtract(const Duration(hours: 3)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_yurtici_delivery',
      sender: isTr ? 'Yurtiçi Kargo' : 'Express Parcel',
      text: isTr
          ? '48291032 takip numaralı kargonuz dağıtıma çıkarılmıştır, bugün adresinize teslim edilecektir. B002'
          : 'Your parcel #48291032 is out for delivery and will arrive today.',
      category: MessageCategory.normal,
      subCategory: MessageSubCategory.personal,
      confidence: 0.95,
      source: DecisionSource.semanticIntent,
      whyReasons: const ['whyPersonalChatContext'],
      timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_mhrs_appt',
      sender: isTr ? 'MHRS Randevu' : 'Clinic Appointment',
      text: isTr
          ? 'Sayın vatandaşımız, yarın saat 10:30 Dahiliye Polikliniği hastane randevunuz bulunmaktadır. B001'
          : 'Reminder: You have a clinic appointment tomorrow at 10:30 AM.',
      category: MessageCategory.normal,
      subCategory: MessageSubCategory.personal,
      confidence: 0.96,
      source: DecisionSource.semanticIntent,
      whyReasons: const ['whyPersonalChatContext'],
      timestamp: now.subtract(const Duration(hours: 5)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_hakan_chat',
      sender: isTr ? 'Hakan Abi' : 'Shop Partner',
      text: isTr
          ? 'Hakan abi emaneti dükkana bıraktım, akşam geçerken alırsın.'
          : 'Hey brother, I left the package at the shop, pick it up this evening.',
      category: MessageCategory.normal,
      subCategory: MessageSubCategory.personal,
      confidence: 0.97,
      source: DecisionSource.semanticIntent,
      whyReasons: const ['whyPersonalChatContext'],
      timestamp: now.subtract(const Duration(minutes: 42)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_mom_chat',
      sender: isTr ? 'Annem' : 'Mom',
      text: isTr
          ? 'Eve gelirken sıcak ekmek alır mısın? Akşama misafir var.'
          : 'Can you pick up some fresh bread on your way home?',
      category: MessageCategory.normal,
      subCategory: MessageSubCategory.personal,
      confidence: 0.98,
      source: DecisionSource.semanticIntent,
      whyReasons: const ['whyPersonalChatContext'],
      timestamp: now.subtract(const Duration(hours: 4)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_spam_betting',
      sender: 'VIP-CASINO (+63917...)',
      text: isTr
          ? 'Son 24 saat! Hesabınıza 2000 TL çevrimsiz deneme bonusu ve 250 freespin tanımlandı: bit.ly/vipbonus'
          : 'Final 24h! Claim your 2000 TL casino bonus and 250 freespins now: bit.ly/vipbonus',
      category: MessageCategory.spam,
      subCategory: MessageSubCategory.bettingGambling,
      confidence: 0.99,
      source: DecisionSource.threatShield,
      ruleName: 'shieldBetting',
      signals: const ['signalBettingPattern', 'signalShortUrl', 'signalForeignNoBCode'],
      whyReasons: const ['whyRewardBetting', 'whyShortUrl', 'whyBtkMissingForeign'],
      intentVector: const IntentVector(
        urgencyFear: 0.78,
        financialTrap: 0.84,
        rewardBetting: 0.98,
        actionLink: 0.94,
        corporateOtp: 0.0,
        personalChat: 0.0,
      ),
      timestamp: now.subtract(const Duration(minutes: 28)),
      origin: MessageOrigin.notification,
    ),
    HistoryEntry(
      id: 'inbox_spam_phishing',
      sender: '+905390001122',
      text: isTr
          ? 'Sayın ilgili, hakkınızda açılmış uzlaştırma ceza dosyası bulunmaktadır. Son ödeme günüdür: cutt.ly/uzlasma'
          : 'URGENT: Legal enforcement file opened under your name. Final day to pay: cutt.ly/legal',
      category: MessageCategory.spam,
      subCategory: MessageSubCategory.governmentScam,
      confidence: 0.99,
      source: DecisionSource.threatShield,
      ruleName: 'shieldPhishing',
      signals: const ['signalGovLegalScam', 'signalShortUrl'],
      whyReasons: const ['whyUrgencyFear', 'whyFinancialTrap', 'whyShortUrl'],
      intentVector: const IntentVector(
        urgencyFear: 0.96,
        financialTrap: 0.91,
        rewardBetting: 0.05,
        actionLink: 0.92,
        corporateOtp: 0.0,
        personalChat: 0.0,
      ),
      timestamp: now.subtract(const Duration(hours: 2)),
      origin: MessageOrigin.notification,
    ),
  ];
}

/// Full-page WhatsApp-style Smart Inbox Screen opened when tapping
/// "Banka / OTP", "Kargo & Randevu", "Kişisel / Sohbet", or "Spam" on Dashboard.
class CategoryInboxScreen extends StatefulWidget {
  const CategoryInboxScreen({
    super.key,
    required this.initialFolder,
  });

  final SmartInboxFolder initialFolder;

  static Future<void> open(BuildContext context, SmartInboxFolder folder) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CategoryInboxScreen(initialFolder: folder),
      ),
    );
  }

  @override
  State<CategoryInboxScreen> createState() => _CategoryInboxScreenState();
}

class _CategoryInboxScreenState extends State<CategoryInboxScreen> {
  late SmartInboxFolder _folder;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _folder = widget.initialFolder;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = switch (_folder) {
      SmartInboxFolder.all => l.t('folderAll'),
      SmartInboxFolder.finance => l.t('folderFinance'),
      SmartInboxFolder.deliveryAppointment => l.t('folderDelivery'),
      SmartInboxFolder.personalChat => l.t('folderPersonal'),
      SmartInboxFolder.spam => l.t('folderSpam'),
    };

    return Scaffold(
      key: const Key('categoryInboxPage'),
      appBar: AppBar(
        leading: BackButton(
          key: const Key('categoryInboxBackBtn'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(title),
      ),
      body: _SmartInboxBody(
        selectedFolder: _folder,
        onFolderChanged: (f) => setState(() => _folder = f),
        query: _query,
        onQueryChanged: (q) => setState(() => _query = q),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);

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
      body: _SmartInboxBody(
        selectedFolder: _folder,
        onFolderChanged: (f) => setState(() => _folder = f),
        query: _query,
        onQueryChanged: (q) => setState(() => _query = q),
      ),
    );
  }
}

class _SmartInboxBody extends StatelessWidget {
  const _SmartInboxBody({
    required this.selectedFolder,
    required this.onFolderChanged,
    required this.query,
    required this.onQueryChanged,
  });

  final SmartInboxFolder selectedFolder;
  final ValueChanged<SmartInboxFolder> onFolderChanged;
  final String query;
  final ValueChanged<String> onQueryChanged;

  void _openDetail(BuildContext context, HistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HistoryDetail(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    // Combine real user/intercepted history with built-in WhatsApp-style inbox items
    final builtIns = builtInInboxEntries(isTr);
    final allItems = <HistoryEntry>[
      ...app.history,
      for (final b in builtIns)
        if (!app.history.any((h) => h.id == b.id)) b,
    ];

    final counts = <SmartInboxFolder, int>{
      for (final f in SmartInboxFolder.values) f: 0,
    };
    counts[SmartInboxFolder.all] = allItems.length;
    for (final item in allItems) {
      final f = app.folderForEntry(item);
      counts[f] = (counts[f] ?? 0) + 1;
    }

    final filtered = allItems.where((e) {
      if (selectedFolder != SmartInboxFolder.all &&
          app.folderForEntry(e) != selectedFolder) {
        return false;
      }
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final matchText = e.text.toLowerCase().contains(q);
        final matchSender = e.sender?.toLowerCase().contains(q) ?? false;
        if (!matchText && !matchSender) return false;
      }
      return true;
    }).toList();

    final folders = <(SmartInboxFolder, String, Key, Color)>[
      (
        SmartInboxFolder.all,
        l.t('folderAll'),
        const Key('folder_all'),
        CyberpunkColors.electricViolet
      ),
      (
        SmartInboxFolder.finance,
        l.t('folderFinance'),
        const Key('folder_finance'),
        CyberpunkColors.neonCyan
      ),
      (
        SmartInboxFolder.deliveryAppointment,
        l.t('folderDelivery'),
        const Key('folder_delivery'),
        CyberpunkColors.warningAmber
      ),
      (
        SmartInboxFolder.personalChat,
        l.t('folderPersonal'),
        const Key('folder_personal'),
        CyberpunkColors.successGreen
      ),
      (
        SmartInboxFolder.spam,
        l.t('folderSpam'),
        const Key('folder_spam'),
        CyberpunkColors.dangerRed
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: onQueryChanged,
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
                  selectedColor: f.$4.withValues(alpha: 0.20),
                  backgroundColor: CyberpunkColors.bgSecondary,
                  side: BorderSide(
                    color: selectedFolder == f.$1
                        ? f.$4
                        : CyberpunkColors.borderSubtle,
                    width: selectedFolder == f.$1 ? 1.4 : 1.0,
                  ),
                  labelStyle: TextStyle(
                    color: selectedFolder == f.$1
                        ? f.$4
                        : CyberpunkColors.textSecondary,
                    fontWeight: selectedFolder == f.$1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  label: Text('${f.$2} (${counts[f.$1] ?? 0})'),
                  selected: selectedFolder == f.$1,
                  onSelected: (_) => onFolderChanged(f.$1),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l.t('historyEmpty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return _WhatsAppStyleInboxTile(
                      entry: e,
                      onTap: () => _openDetail(context, e),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// WhatsApp-style rich inbox row showing sender avatar, bank/sender name,
/// timestamp, message preview, and one-tap OTP copy badge.
class _WhatsAppStyleInboxTile extends StatelessWidget {
  const _WhatsAppStyleInboxTile({
    required this.entry,
    required this.onTap,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;

  String _initials(String sender) {
    final clean = sender.trim();
    if (clean.isEmpty) return 'SMS';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = CategoryStyle.color(entry.category);
    final senderTitle = (entry.sender != null && entry.sender!.trim().isNotEmpty)
        ? entry.sender!.trim()
        : CategoryStyle.label(l, entry.category);
    final timeStr = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.timestamp),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar Circle (WhatsApp style)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.65),
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(senderTitle),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sender Name + Message Preview + Optional OTP Copy Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          senderTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: CyberpunkColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CategoryChip(category: entry.category, dense: true),
                      if (entry.otpCode != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: entry.otpCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l.t('otpCopied', {'code': entry.otpCode!}),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: CyberpunkColors.neonCyan
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CyberpunkColors.neonCyan
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: CyberpunkColors.neonCyan,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'OTP: ${entry.otpCode}',
                                  style: const TextStyle(
                                    color: CyberpunkColors.neonCyan,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  const _HistoryDetail({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    // Check if an updated version exists in app.history
    final idx = app.history.indexWhere((h) => h.id == entry.id);
    final e = idx >= 0 ? app.history[idx] : entry;

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
