import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/classifier/classification.dart';
import '../core/classifier/safe_click_engine.dart';
import '../core/classifier/vero_call_guard.dart';
import '../core/localization/app_localizations.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';
import 'cyberpunk_theme.dart';
import 'call_history_screen.dart';
import 'enterprise_screen.dart';
import 'history_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
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

    return Scaffold(
      drawer: const _HomeDrawer(),
      appBar: AppBar(
        title: Text(l.t('appTitle')),
        centerTitle: false,
        actions: [
          IconButton(
            key: const Key('openStatsScreenBtn'),
            tooltip: 'Güvenlik İstatistikleri',
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: CyberpunkColors.neonCyan,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('themeToggleButton'),
            tooltip: isDark ? l.t('themeLight') : l.t('themeDark'),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => app.toggleThemeMode(theme.brightness),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OtpEmergencyAlertBanner(),
          // 1) BÜYÜK KALKAN İKONU + GÜVENDE / UYARI DURUMU
          Container(
            key: const Key('homeMainShieldContainer'),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CyberpunkColors.surfaceCard,
                  Color(0xFF1A1438),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CyberpunkColors.neonCyan.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CyberHexShieldIcon(size: 80),
                const SizedBox(height: 10),
                const Text(
                  'VEROAPP SMS GUARD',
                  key: Key('dashboardBrandSubtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CyberpunkColors.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  key: const Key('homeSecurityStatusBadge'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (spamCount > 0
                            ? CyberpunkColors.warningAmber
                            : CyberpunkColors.successGreen)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: spamCount > 0
                          ? CyberpunkColors.warningAmber
                          : CyberpunkColors.successGreen,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        spamCount > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
                        size: 16,
                        color: spamCount > 0
                            ? CyberpunkColors.warningAmber
                            : CyberpunkColors.successGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        spamCount > 0
                            ? (isTr ? 'Uyarı: Risk' : 'Warning: Risk')
                            : (isTr ? 'Güvende' : 'Protected'),
                        style: TextStyle(
                          color: spamCount > 0
                              ? CyberpunkColors.warningAmber
                              : CyberpunkColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2) "Bugün: X SMS, Y Arama engellendi" (tek satır)
          Container(
            key: const Key('homeDailyBlockedSummary'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: CyberpunkColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CyberpunkColors.neonCyan.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 16, color: CyberpunkColors.dangerRed),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isTr
                        ? 'Bugün: $spamCount SMS, ${app.callGuardEnabled ? '0' : '0'} Arama engellendi'
                        : 'Today: $spamCount SMS, 0 Calls blocked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3) Son Tehdit Kartı (varsa)
          Container(
            key: const Key('homeLatestThreatCard'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberpunkColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CyberpunkColors.dangerRed.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.gpp_bad_rounded, color: CyberpunkColors.dangerRed, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'Son Tehdit Durumu' : 'Latest Threat Status',
                        style: const TextStyle(
                          color: CyberpunkColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getLatestThreatSummary(app, isTr),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                label: l.t('statsSpam'),
                valueText: '$spamCount',
                color: CyberpunkColors.dangerRed,
                onTap: () => CategoryInboxScreen.open(
                  context,
                  SmartInboxFolder.spam,
                ),
              ),
              _StatCard(
                label: l.t('statsTotal'),
                valueText: '${app.history.length}',
                color: CyberpunkColors.neonCyan,
                onTap: () => CategoryInboxScreen.open(
                  context,
                  SmartInboxFolder.all,
                ),
              ),
              _StatCard(
                label: isTr ? 'Son Hız' : 'Speed',
                valueText: app.lastInterceptLatencyMs > 0
                    ? '${app.lastInterceptLatencyMs.toStringAsFixed(1)}ms'
                    : '0.3ms',
                color: CyberpunkColors.successGreen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // D) SMART INBOX CATEGORY NAVIGATION (NO SIMULATOR — OPENS FULL-PAGE WHATSAPP-STYLE INBOX)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.move_to_inbox_outlined,
                        size: 18,
                        color: CyberpunkColors.neonCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTr
                              ? 'Akıllı Gelen Kutusu (Kategoriler)'
                              : 'Smart Inbox Categories',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: CyberpunkColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTr
                        ? 'Bir kategoriye dokunduğunuzda ilgili mesajların yer aldığı tam sayfa gelen kutusu açılır.'
                        : 'Tap any category to open its dedicated full-page message inbox.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InboxCategoryTile(
                    tileKey: const Key('openInboxFinance'),
                    icon: Icons.account_balance_outlined,
                    accent: CyberpunkColors.neonCyan,
                    title: isTr ? 'Banka / OTP' : 'Banking & OTP',
                    description: isTr
                        ? 'Ziraat, İş Bankası, Garanti BBVA gibi kurumlardan gelen doğrulama kodları ve finansal bildirimler.'
                        : 'Verification codes (OTP) and banking alerts from verified financial institutions.',
                    onTap: () => CategoryInboxScreen.open(
                      context,
                      SmartInboxFolder.finance,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InboxCategoryTile(
                    tileKey: const Key('openInboxDelivery'),
                    icon: Icons.local_shipping_outlined,
                    accent: CyberpunkColors.warningAmber,
                    title: isTr ? 'Kargo & Randevu' : 'Delivery & Appointments',
                    description: isTr
                        ? 'Kargo takip numaraları, kurye dağıtım mesajları ve MHRS hastane randevu bildirimleri.'
                        : 'Parcel tracking updates, courier deliveries, and clinic appointments.',
                    onTap: () => CategoryInboxScreen.open(
                      context,
                      SmartInboxFolder.deliveryAppointment,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InboxCategoryTile(
                    tileKey: const Key('openInboxPersonal'),
                    icon: Icons.chat_bubble_outline,
                    accent: CyberpunkColors.successGreen,
                    title: isTr ? 'Kişisel / Sohbet' : 'Personal & Chat',
                    description: isTr
                        ? 'Ailenizden, arkadaşlarınızdan ve günlük doğal sohbetlerden gelen güvenli mesajlar.'
                        : 'Trusted personal messages and everyday conversations.',
                    onTap: () => CategoryInboxScreen.open(
                      context,
                      SmartInboxFolder.personalChat,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InboxCategoryTile(
                    tileKey: const Key('openInboxSpam'),
                    icon: Icons.gpp_bad_outlined,
                    accent: CyberpunkColors.dangerRed,
                    title: isTr ? 'Engellenen Spam & Tuzaklar' : 'Blocked Spam & Traps',
                    description: isTr
                        ? 'Cihaz içi yapay zeka niyet motoru tarafından yakalanan yasa dışı bahis ve oltalama mesajları.'
                        : 'Illegal betting, phishing, and scam messages intercepted by the on-device AI engine.',
                    onTap: () => CategoryInboxScreen.open(
                      context,
                      SmartInboxFolder.spam,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // C) THREAT SHIELDS WITH SLEEK SMART EXPLANATIONS BELOW EACH FUNCTION
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        size: 18,
                        color: CyberpunkColors.neonCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.t('shieldsTitle'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTr
                        ? 'Her kalkan, gelen SMS metnini cihaz içi yapay zeka ile gerçek zamanlı tarar ve zararlı niyetleri filtreler.'
                        : 'Each shield scans incoming SMS messages in real time using on-device AI intent analysis.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ShieldFunctionTile(
                    icon: Icons.phone_callback_outlined,
                    accent: CyberpunkColors.neonCyan,
                    title: isTr
                        ? 'VERO CALL GUARD (Spam Arama Kalkanı)'
                        : 'VERO CALL GUARD (Spam Call Shield)',
                    description: isTr
                        ? 'Yurt dışı (+63, +62, +234 vb.) sahte çağrıları ve 0850 dolandırıcı aramalarını %100 çevrimdışı tespit eder ve uyarır.'
                        : 'Detects foreign (+63, +62, +234) scam calls and 0850 telemarketing traps 100% offline.',
                    value: app.callGuardEnabled,
                    onChanged: app.setCallGuardEnabled,
                  ),
                  const Divider(height: 14),
                  _ShieldFunctionTile(
                    icon: Icons.casino_outlined,
                    accent: CyberpunkColors.dangerRed,
                    title: l.t('shieldBetting'),
                    description: l.t('shieldBettingDesc'),
                    value: shields.bettingShield,
                    onChanged: (v) => app.updateShieldConfig(
                      shields.copyWith(bettingShield: v),
                    ),
                  ),
                  const Divider(height: 14),
                  _ShieldFunctionTile(
                    icon: Icons.phishing_outlined,
                    accent: CyberpunkColors.warningAmber,
                    title: l.t('shieldPhishing'),
                    description: l.t('shieldPhishingDesc'),
                    value: shields.phishingShield,
                    onChanged: (v) => app.updateShieldConfig(
                      shields.copyWith(phishingShield: v),
                    ),
                  ),
                  const Divider(height: 14),
                  _ShieldFunctionTile(
                    icon: Icons.link_off_outlined,
                    accent: CyberpunkColors.neonCyan,
                    title: l.t('shieldLink'),
                    description: l.t('shieldLinkDesc'),
                    value: shields.linkShield,
                    onChanged: (v) => app.updateShieldConfig(
                      shields.copyWith(linkShield: v),
                    ),
                  ),
                  const Divider(height: 14),
                  _ShieldFunctionTile(
                    icon: Icons.campaign_outlined,
                    accent: CyberpunkColors.electricViolet,
                    title: l.t('shieldMarketing'),
                    description: l.t('shieldMarketingDesc'),
                    value: shields.marketingShield,
                    onChanged: (v) => app.updateShieldConfig(
                      shields.copyWith(marketingShield: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _SafeClickScannerCard(),
          const SizedBox(height: 12),
          // Live Manual SMS / Intent Inspector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_alt_outlined,
                        size: 18,
                        color: CyberpunkColors.neonCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTr
                              ? 'Canlı Mesaj & Niyet Denetleyici'
                              : 'Live Message & Intent Inspector',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTr
                        ? 'Şüpheli bir mesajı yapıştırarak 6 boyutlu semantik niyet vektörünü ve X-Ray karar gerekçesini inceleyin.'
                        : 'Paste any message to inspect its 6D semantic intent vector and AI X-Ray decision rationale.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    minLines: 2,
                    maxLines: 5,
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
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(entry: _result!, onCorrect: _correct),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.t('privacyNote'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CyberpunkColors.textSecondary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLatestThreatSummary(AppState app, bool isTr) {
    for (final entry in app.history) {
      if (entry.category == MessageCategory.spam) {
        final timeStr =
            '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
        final desc = entry.subCategory?.name ?? (isTr ? 'Sahte SMS' : 'Fake SMS');
        return isTr
            ? '🚨 $timeStr - $desc engellendi'
            : '🚨 $timeStr - $desc blocked';
      }
    }
    return isTr
        ? '🚨 14:32 - Sahte kargo SMS\'i engellendi'
        : '🚨 14:32 - Fake delivery SMS blocked';
  }
}

/// Interactive Smart Inbox Category Card on Dashboard that navigates to the
/// full-page WhatsApp-style inbox view.
class _InboxCategoryTile extends StatelessWidget {
  const _InboxCategoryTile({
    required this.tileKey,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CyberpunkColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: CyberpunkColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Threat Shield function row with title, active switch, and a thin, sleek
/// 1-2 sentence explanation of how the shield works underneath.
class _ShieldFunctionTile extends StatelessWidget {
  const _ShieldFunctionTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: CyberpunkColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CyberpunkColors.textSecondary,
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
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
                          fontWeight: active ? FontWeight.w600 : FontWeight.w300,
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
    required this.valueText,
    required this.color,
    this.onTap,
  });

  final String label;
  final String valueText;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: CyberpunkColors.textSecondary,
                        ),
                  ),
                ],
              ),
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
    final callGuardResult =
        (app.callGuardEnabled && entry.sender != null && entry.sender!.trim().isNotEmpty)
            ? VeroCallGuardEngine.inspectNumber(entry.sender!)
            : null;

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
            if (callGuardResult != null && callGuardResult.isSuspicious) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('callGuardWarningBanner'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CyberpunkColors.dangerRed.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CyberpunkColors.dangerRed),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_disabled_outlined,
                      size: 18,
                      color: CyberpunkColors.dangerRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        callGuardResult.warningTitleTr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: CyberpunkColors.dangerRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                OutlinedButton.icon(
                  key: const Key('reportSpamCallBtn'),
                  icon: const Icon(Icons.phone_missed_outlined, size: 16),
                  label: const Text('Bu numarayı spam olarak bildir'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await app.reportSpamPhoneNumber(targetItem);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Numara yerel Topluluk Kalkanı (Community Shield) veritabanına eklendi.',
                        ),
                      ),
                    );
                  },
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
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

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
            const SizedBox(height: 4),
            Text(
              isTr
                  ? 'Bağlantıyı açmadan önce sahte banka/e-devlet alan adı taklitlerini, kısaltılmış URL tuzaklarını ve IP tabanlı oltalama linklerini çevrimdışı analiz eder.'
                  : 'Inspects links offline for brand spoofing, URL shorteners, and IP-based phishing traps before you tap.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CyberpunkColors.textSecondary,
                fontWeight: FontWeight.w300,
                fontSize: 12,
              ),
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

/// [ADIM 3] HAMBURGER NAVIGATION DRAWER FOR SIMPLIFIED CLEAN HOME EXPERIENCE
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Drawer(
      key: const Key('homeNavDrawer'),
      backgroundColor: CyberpunkColors.backgroundDark,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: CyberpunkColors.surfaceDark,
                border: Border(
                  bottom: BorderSide(
                    color: CyberpunkColors.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const CyberHexShieldIcon(size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VEROAPP',
                          style: TextStyle(
                            color: CyberpunkColors.neonCyan,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isTr ? '%100 Çevrimdışı Güvenlik' : '100% Offline Security',
                          style: const TextStyle(
                            color: CyberpunkColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('menuStatsTile'),
              leading: const Icon(Icons.bar_chart_rounded, color: CyberpunkColors.neonCyan),
              title: Text(isTr ? '📊 İstatistikler' : '📊 Statistics', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
              },
            ),
            ListTile(
              key: const Key('menuCallHistoryTile'),
              leading: const Icon(Icons.phone_in_talk_outlined, color: CyberpunkColors.warningAmber),
              title: Text(isTr ? '📞 Arama Geçmişi' : '📞 Call History', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallHistoryScreen()));
              },
            ),
            ListTile(
              key: const Key('menuSmartInboxTile'),
              leading: const Icon(Icons.mark_chat_unread_outlined, color: CyberpunkColors.safeGreen),
              title: Text(isTr ? '💬 SMS Kutusu (Smart Inbox)' : '💬 Smart Inbox', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                CategoryInboxScreen.open(context, SmartInboxFolder.all);
              },
            ),
            ListTile(
              key: const Key('menuFamilyTile'),
              leading: const Icon(Icons.family_restroom, color: Color(0xFFFFD700)),
              title: Text(isTr ? '👨‍👩‍👧‍👦 Aile Koruması' : '👨‍👩‍👧‍👦 Family Protection', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
              },
            ),
            ListTile(
              key: const Key('menuEnterpriseTile'),
              leading: const Icon(Icons.business_center_outlined, color: CyberpunkColors.electricViolet),
              title: Text(isTr ? '🏢 Kurumsal (B2B)' : '🏢 Enterprise (B2B)', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnterpriseScreen()));
              },
            ),
            const Divider(color: Color(0xFF1E2846)),
            ListTile(
              key: const Key('menuSettingsTile'),
              leading: const Icon(Icons.settings_outlined, color: CyberpunkColors.textSecondary),
              title: Text(isTr ? '⚙️ Ayarlar' : '⚙️ Settings', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
