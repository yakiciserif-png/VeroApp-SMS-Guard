import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/localization/app_localizations.dart';
import '../core/monetization/purchase_service.dart';
import '../engines/vero_community_shield.dart';
import '../engines/vero_link_scanner.dart';
import '../state/app_state.dart';
import 'cyberpunk_theme.dart';
import 'enterprise_screen.dart';
import 'edevlet_guard_screen.dart';
import 'database_stats_screen.dart';
import 'link_scanner_screen.dart';
import 'paywall_screen.dart';
import 'crash_reports_screen.dart';
import '../security_audit.dart';
import '../screens/screenshot_mode.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final shields = app.shieldConfig;
    final current = app.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final isTr = current == 'tr';

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.t('navSettings'))),
      body: ListView(
        children: [
          // B) PROTECTION MODE ("Esnek / Dengeli / Sıkı") AT VERY TOP OF SETTINGS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              key: const Key('settingsProtectionModeCard'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 18,
                          color: CyberpunkColors.neonCyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t('modeTitle'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: CyberpunkColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? 'Yapay zeka niyet motorunun engelleme hassasiyetini belirler: Esnek mod yalnızca kesin tehditleri, Sıkı mod ise en ufak şüpheli sinyali bile anında filtreler.'
                          : 'Controls the AI intent engine sensitivity: Relaxed blocks only high-certainty threats, while Strict filters even subtle suspicious signals.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CyberpunkColors.textSecondary,
                        fontWeight: FontWeight.w300,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ProtectionMode>(
                      key: const Key('protectionModeSegment'),
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
                    const SizedBox(height: 6),
                    Text(
                      switch (app.protectionMode) {
                        ProtectionMode.relaxed => l.t('modeRelaxedDesc'),
                        ProtectionMode.balanced => l.t('modeBalancedDesc'),
                        ProtectionMode.strict => l.t('modeStrictDesc'),
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CyberpunkColors.neonCyan,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: CyberpunkColors.electricViolet.withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CyberHexShieldIcon(size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.t('aiBrainTitle'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: CyberpunkColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _BrainMetric(
                            label: l.t('aiVocabSize'),
                            value: '${app.classifier.model.vocabularySize}',
                          ),
                        ),
                        Expanded(
                          child: _BrainMetric(
                            label: l.t('aiTrainedDocs'),
                            value: '${app.classifier.model.documentCount}',
                          ),
                        ),
                        Expanded(
                          child: _BrainMetric(
                            label: l.t('aiActiveRules'),
                            value: '${app.rules.where((r) => r.enabled).length}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 4) AİLE KORUMASI & VERO AİLE KODU + VERO PRO / AİLE PAKETLERİ (DIRECTLY ABOVE HAZIR TEHDİT KALKANLARI)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _FamilyAndProCard(),
          ),
          header(l.t('shieldsTitle')),
          SwitchListTile(
            key: const Key('callGuardSwitchTile'),
            secondary: const Icon(Icons.phone_callback_outlined),
            title: Text(
              isTr
                  ? 'VERO CALL GUARD (Spam Arama Kalkanı)'
                  : 'VERO CALL GUARD (Spam Call Shield)',
            ),
            subtitle: Text(
              isTr
                  ? 'Yurt dışı (+63, +62, +234 vb.) sahte çağrıları ve 0850 dolandırıcı aramalarını %100 çevrimdışı tespit eder.'
                  : 'Detects foreign (+63, +62, +234) scam calls and 0850 telemarketing traps 100% offline.',
            ),
            value: app.callGuardEnabled,
            onChanged: app.setCallGuardEnabled,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.casino_outlined),
            title: Text(l.t('shieldBetting')),
            subtitle: Text(l.t('shieldBettingDesc')),
            value: shields.bettingShield,
            onChanged: (v) =>
                app.updateShieldConfig(shields.copyWith(bettingShield: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.phishing_outlined),
            title: Text(l.t('shieldPhishing')),
            subtitle: Text(l.t('shieldPhishingDesc')),
            value: shields.phishingShield,
            onChanged: (v) =>
                app.updateShieldConfig(shields.copyWith(phishingShield: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.link_off_outlined),
            title: Text(l.t('shieldLink')),
            subtitle: Text(l.t('shieldLinkDesc')),
            value: shields.linkShield,
            onChanged: (v) =>
                app.updateShieldConfig(shields.copyWith(linkShield: v)),
          ),
          ListTile(
            key: const Key('linkScannerModeTile'),
            leading: const Icon(Icons.radar_outlined, color: CyberpunkColors.neonCyan),
            title: Text(isTr ? 'Link Tarama Modu: Otomatik / Manuel' : 'Link Scanner Mode: Auto / Manual'),
            subtitle: Text(
              app.linkScannerMode == LinkScannerMode.automatic
                  ? (isTr
                      ? 'Otomatik (Erişilebilirlik ile WhatsApp & Telegram arka plan taraması)'
                      : 'Automatic (Background scanning via Accessibility)')
                  : (isTr
                      ? 'Manuel (Paylaş menüsü veya kopyala-yapıştır ile güvenli tarama)'
                      : 'Manual (Share target or copy-paste scanning)'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: CyberpunkColors.textSecondary,
              ),
            ),
            trailing: SegmentedButton<LinkScannerMode>(
              key: const Key('linkScannerModeSegment'),
              segments: [
                ButtonSegment<LinkScannerMode>(
                  value: LinkScannerMode.automatic,
                  label: Text(isTr ? 'Oto' : 'Auto'),
                ),
                ButtonSegment<LinkScannerMode>(
                  value: LinkScannerMode.manual,
                  label: Text(isTr ? 'Man' : 'Man'),
                ),
              ],
              selected: {app.linkScannerMode},
              onSelectionChanged: (Set<LinkScannerMode> selected) {
                app.setLinkScannerMode(selected.first);
              },
            ),
          ),
          ListTile(
            key: const Key('openLinkScannerScreenTile'),
            leading: const Icon(Icons.open_in_new, color: CyberpunkColors.neonCyan),
            title: Text(isTr ? 'Manuel Link Radarı Ekranını Aç' : 'Open Link Radar Screen'),
            subtitle: Text(
              isTr
                  ? 'Şüpheli bir bağlantıyı doğrudan yapıştırıp risk seviyesini inceleyin.'
                  : 'Paste a suspicious link directly to inspect its risk score.',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: CyberpunkColors.neonCyan),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LinkScannerScreen()),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: Text(l.t('shieldMarketing')),
            subtitle: Text(l.t('shieldMarketingDesc')),
            value: shields.marketingShield,
            onChanged: (v) =>
                app.updateShieldConfig(shields.copyWith(marketingShield: v)),
          ),
          header(l.t('settingsProtection')),
          if (app.bridge.isAndroid) ...[
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.t('settingsAndroidAccess')),
              subtitle: Text(
                '${l.t('settingsAndroidAccessDesc')}\n${app.notificationAccess ? l.t('granted') : l.t('notGranted')}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.open_in_new),
              onTap: app.bridge.openNotificationAccessSettings,
            ),
            ListTile(
              key: const Key('settingsSmsPermissionTile'),
              leading: const Icon(Icons.sms_outlined),
              title: Text(l.t('permSmsTitle')),
              subtitle: Text(
                '${l.t('permSmsDesc')}\n${app.smsPermissionGranted ? l.t('granted') : l.t('notGranted')}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.security_update_good_outlined),
              onTap: app.requestSmsPermissions,
            ),
            ListTile(
              key: const Key('settingsSpamRoleTile'),
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(l.t('permRoleTitle')),
              subtitle: Text(
                '${l.t('permRoleDesc')}\n${app.isDefaultSmsRoleHeld ? l.t('granted') : l.t('notGranted')}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.admin_panel_settings_outlined),
              onTap: app.requestSpamRole,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.auto_delete_outlined),
              title: Text(l.t('settingsAutoDismiss')),
              subtitle: Text(l.t('settingsAutoDismissDesc')),
              value: app.autoDismissSpam,
              onChanged: app.setAutoDismiss,
            ),
          ] else ...[
            if (Platform.isIOS || defaultTargetPlatform == TargetPlatform.iOS || !app.bridge.isAndroid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  key: const Key('iosLimitedProtectionBanner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberpunkColors.warningAmber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CyberpunkColors.warningAmber.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    l.t('iosLimitedWarning'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.warningAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.sms_failed_outlined),
              title: Text(l.t('settingsIosGuide')),
              subtitle: Text(l.t('settingsIosGuideDesc')),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l.t('settingsResetModel')),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final msg = l.t('settingsResetModelDone');
              await app.resetModel();
              messenger.showSnackBar(SnackBar(content: Text(msg)));
            },
          ),
          header(l.t('autoCleanerTitle')),
          SwitchListTile(
            key: const Key('autoCleanOtp24hSwitch'),
            secondary: const Icon(Icons.cleaning_services_outlined),
            title: Text(l.t('autoCleanOtp24hTitle')),
            subtitle: Text(l.t('autoCleanOtp24hDesc')),
            value: app.autoCleanOtp24h,
            onChanged: app.setAutoCleanOtp24h,
          ),
          ListTile(
            key: const Key('runAutoCleanerNowTile'),
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(l.t('autoCleanRunNowBtn')),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final n = await app.runAutoCleaner(cleanAllOtpNow: true);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l.t('autoCleanResultMsg', {'n': '$n'})),
                ),
              );
            },
          ),
          header(l.t('communityShieldTitle')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('communityShieldDesc'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTr
                          ? 'Kaç numara bildirdin: ${app.reportedCommunityNumbersCount}'
                          : 'Reported numbers count: ${app.reportedCommunityNumbersCount}',
                      key: const Key('communityReportedCountText'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: CyberpunkColors.neonCyan,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? 'Topluluk tarafından engellenen: ${VeroCommunityShield.communityBlockedCount}'
                          : 'Community blocked count: ${VeroCommunityShield.communityBlockedCount}',
                      key: const Key('communityBlockedCountText'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('viewCommunityHistoryBtn'),
                          onPressed: () {
                            final list = VeroCommunityShield.reportedNumbers;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: CyberpunkColors.bgSecondary,
                                title: const Text(
                                  'Bildirim Geçmişi',
                                  style: TextStyle(
                                    fontFamily: 'Book Antiqua',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: list.isEmpty
                                      ? const Text(
                                          'Henüz bir spam numarası bildirmediniz.',
                                          style: TextStyle(
                                            fontFamily: 'Book Antiqua',
                                            color: CyberpunkColors.textSecondary,
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: list.length,
                                          itemBuilder: (ctx, idx) => ListTile(
                                            dense: true,
                                            leading: const Icon(
                                              Icons.phone_disabled_rounded,
                                              color: Color(0xFFFF1744),
                                              size: 18,
                                            ),
                                            title: Text(
                                              list[idx].rawNumber,
                                              style: const TextStyle(
                                                fontFamily: 'Book Antiqua',
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${list[idx].category} • Güven: %${list[idx].confidenceScore}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: CyberpunkColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Kapat'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text('Bildirim geçmişi'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('clearCommunityNumbersBtn'),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await app.clearReportedSpamPhoneNumbers();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTr
                                      ? 'Bildirilen numaralar yerel veritabanından silindi.'
                                      : 'Reported numbers cleared from local database.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            isTr
                                ? 'Bildirilen numaraları sil'
                                : 'Clear reported numbers',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          key: const Key('exportCommunityShieldBtn'),
                          onPressed: () {
                            final jsonStr = app.exportCommunityShieldBundle();
                            Clipboard.setData(ClipboardData(text: jsonStr));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.t('communityExportDone')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file_outlined, size: 18),
                          label: Text(l.t('communityExportBtn')),
                        ),
                        OutlinedButton.icon(
                          key: const Key('importCommunityShieldBtn'),
                          onPressed: () =>
                              _showCommunityImportDialog(context),
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: Text(l.t('communityImportBtn')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          header(isTr ? 'Tehdit Veritabanı & Güncelleme' : 'Threat Database & Updates'),
          ListTile(
            key: const Key('settingsDatabaseStatsTile'),
            leading: const Icon(Icons.analytics_outlined, color: CyberpunkColors.neonCyan),
            title: Text(
              isTr ? 'Veritabanı İstatistikleri' : 'Database Statistics',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isTr
                  ? '63.000+ numara, 38.000+ phishing domain ve kaynak dağılımını inceleyin.'
                  : 'Inspect 63,000+ numbers, 38,000+ phishing domains and metrics.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: CyberpunkColors.neonCyan),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DatabaseStatsScreen()),
              );
            },
          ),
          SwitchListTile(
            key: const Key('settingsAutoThreatUpdateToggle'),
            title: Text(
              isTr ? 'Haftalık Tehdit Güncellemesi' : 'Weekly Threat Update',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isTr
                  ? 'GitHub Releases üzerinden yalnızca yeni tehdit ve oltalama verilerini indirir. Cihazınızdan dışarıya hiçbir veri çıkmaz (%100 KVKK uyumlu tek yönlü çekme).'
                  : 'Downloads threat package updates via GitHub Releases. Zero telemetry or user data transmitted.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            value: app.isAutoThreatUpdateEnabled,
            onChanged: (val) => app.setAutoThreatUpdate(val),
          ),
          header(l.t('reportSectionTitle')),
          ListTile(
            key: const Key('openReportSheetTile'),
            leading: const Icon(Icons.campaign_outlined),
            title: Text(l.t('reportButtonLabel')),
            subtitle: Text(l.t('reportCardSubtitle')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ReportFalsePositiveSheet.show(context),
          ),
          header(l.t('faqSectionTitle')),
          ExpansionTile(
            key: const Key('faqTile1'),
            leading: const Icon(Icons.help_outline),
            title: Text(l.t('faqQ1')),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [Text(l.t('faqA1'))],
          ),
          ExpansionTile(
            key: const Key('faqTile2'),
            leading: const Icon(Icons.lock_outline),
            title: Text(l.t('faqQ2')),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [Text(l.t('faqA2'))],
          ),
          ExpansionTile(
            key: const Key('faqTile3'),
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l.t('faqQ3')),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [Text(l.t('faqA3'))],
          ),
          ExpansionTile(
            key: const Key('faqTile4'),
            leading: const Icon(Icons.policy_outlined),
            title: Text(l.t('faqQ4')),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [Text(l.t('faqA4'))],
          ),
          header(l.t('themeTitle')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                  label: Text(
                    l.t('themeLight'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text(
                    l.t('themeDark'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text(
                    l.t('themeSystem'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {app.themeMode},
              onSelectionChanged: (s) => app.setThemeMode(s.first),
            ),
          ),
          header(l.t('settingsLanguage')),
          for (final code in AppLocalizations.supportedCodes)
            ListTile(
              key: Key('lang_$code'),
              title: Text(AppLocalizations.nativeNames[code]!),
              subtitle: Text(code.toUpperCase()),
              trailing: code == current
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () => app.setLocale(Locale(code)),
            ),
          header(l.t('settingsAbout')),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.t('appTitle')),
            subtitle: Text(l.t('settingsAboutDesc')),
          ),
          header(isTr ? 'Gelişmiş Güvenlik & Sertifikasyon' : 'Advanced Security & Certification'),
          ListTile(
            key: const Key('openEDevletGuardTile'),
            leading: const Icon(Icons.lock_person_outlined, color: CyberpunkColors.neonCyan),
            title: Text(isTr ? 'e-Devlet Şifre Güvenliği' : 'e-Devlet Password Security'),
            subtitle: Text(isTr ? '100% Çevrimdışı şifre gücü ve sızıntı denetimi' : 'On-device breach check & complexity audit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EDevletGuardScreen()),
            ),
          ),
          ListTile(
            key: const Key('openSecurityAuditTile'),
            leading: const Icon(Icons.verified_outlined, color: CyberpunkColors.safeGreen),
            title: Text(isTr ? 'Güvenlik Sertifikası' : 'Security Audit Certificate'),
            subtitle: Text(isTr ? 'Kendi kendini denetleyen tam uyumlu çevrimdışı kalkan' : 'Self-auditing certified offline shield'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecurityAuditScreen()),
            ),
          ),
          ListTile(
            key: const Key('openCrashReportsTile'),
            leading: const Icon(Icons.bug_report_outlined, color: CyberpunkColors.warningAmber),
            title: Text(isTr ? 'Hata Raporları' : 'Crash Reports'),
            subtitle: Text(isTr ? 'Yerel çökme günlükleri (Sıfır telemetri)' : 'Local exception logs (Zero telemetry)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CrashReportsScreen()),
            ),
          ),
          ListTile(
            key: const Key('openScreenshotModeTile'),
            leading: const Icon(Icons.photo_camera_outlined, color: CyberpunkColors.electricViolet),
            title: Text(isTr ? 'Mağaza Ekran Görüntüsü Modu' : 'Store Screenshot Mode'),
            subtitle: Text(isTr ? 'Play Store & App Store demo durumları' : 'Play Store & App Store visual showcase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScreenshotModeScreen()),
            ),
          ),
          header(isTr ? 'Yasal & Gizlilik' : 'Legal & Privacy'),
          ListTile(
            key: const Key('openPrivacyPolicyTile'),
            leading: const Icon(Icons.privacy_tip_outlined, color: CyberpunkColors.neonCyan),
            title: Text(isTr ? 'Gizlilik Politikası' : 'Privacy Policy'),
            subtitle: Text(isTr ? 'KVKK & GDPR tam uyumluluk ve sıfır veri toplama' : 'KVKK & GDPR zero data collection guarantee'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            key: const Key('openTermsOfServiceTile'),
            leading: const Icon(Icons.gavel_outlined, color: CyberpunkColors.neonCyan),
            title: Text(isTr ? 'Kullanım Şartları' : 'Terms of Service'),
            subtitle: Text(isTr ? 'Lisans şartları ve abonelik hakları' : 'Licensing terms & subscriber rights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showCommunityImportDialog(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController();

    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('communityImportDialogTitle')),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: l.t('communityImportHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l.t('confirm')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (raw == null || raw.isEmpty) return;
    try {
      final count = await app.importCommunityShieldBundle(raw);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.t('communityImportSuccess', {'n': '$count'})),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.t('communityImportError'))),
      );
    }
  }
}

/// Family Protection & VERO AİLE Code + VERO PRO / AİLE Subscription & Breach Radar Card
/// placed directly above "Hazır Tehdit Kalkanları" in SettingsScreen.
class _FamilyAndProCard extends StatefulWidget {
  const _FamilyAndProCard();

  @override
  State<_FamilyAndProCard> createState() => _FamilyAndProCardState();
}

class _FamilyAndProCardState extends State<_FamilyAndProCard> {
  final _familyCodeCtrl = TextEditingController();
  final _breachInputCtrl = TextEditingController();
  BreachRadarResult? _breachResult;

  @override
  void dispose() {
    _familyCodeCtrl.dispose();
    _breachInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _onJoinFamily(AppState app, bool isTr) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await app.joinFamilyWithCode(_familyCodeCtrl.text);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isTr
                  ? 'VERO AİLE korumasına başarıyla bağlandınız!'
                  : 'Successfully connected to VERO FAMILY protection!')
              : (isTr
                  ? 'Lütfen geçerli bir 6 haneli VERO AİLE kodu girin.'
                  : 'Please enter a valid 6-digit VERO FAMILY code.'),
        ),
      ),
    );
  }

  void _onCheckBreach() {
    final raw = _breachInputCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _breachResult = VeroBreachRadarEngine.checkIdentity(raw);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final purchase = app.purchaseService;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final tierLabel = switch (app.subscriptionTier) {
      VeroSubscriptionTier.free => isTr ? 'ÜCRETSİZ PLAN' : 'FREE PLAN',
      VeroSubscriptionTier.proMonthly ||
      VeroSubscriptionTier.proYearly =>
        'VERO PRO',
      VeroSubscriptionTier.familyYearly => 'VERO AİLE (4/4)',
    };

    return Card(
      key: const Key('familyProtectionCard'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: CyberpunkColors.neonCyan.withValues(alpha: 0.75),
          width: 1.3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.family_restroom_outlined,
                  size: 20,
                  color: CyberpunkColors.neonCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AİLE KORUMASI & VERO AİLE KODU',
                    key: const Key('familyCardTitle'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: CyberpunkColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: app.isProOrFamily
                        ? CyberpunkColors.successGreen.withValues(alpha: 0.16)
                        : CyberpunkColors.neonCyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: app.isProOrFamily
                          ? CyberpunkColors.successGreen
                          : CyberpunkColors.neonCyan,
                    ),
                  ),
                  child: Text(
                    tierLabel,
                    key: const Key('activePlanBadge'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: app.isProOrFamily
                          ? CyberpunkColors.successGreen
                          : CyberpunkColors.neonCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isTr
                  ? '4 kişilik VERO AİLE kontenjanı ile anne, baba ve çocuklarınızı tek kodla koruyun. Paket sahibi kodu paylaşır; aile üyesi 6 haneli kodu girerek anında bağlanır.'
                  : 'Protect up to 4 family members with a single VERO FAMILY code. The owner shares the 6-digit code; family members enter it to activate instant protection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CyberpunkColors.textSecondary,
                fontWeight: FontWeight.w300,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              key: const Key('familyRoleToggle'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text(
                    isTr ? 'Paket Sahibi' : 'Plan Owner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.group_add_outlined, size: 16),
                  label: Text(
                    isTr ? 'Aile Üyesi' : 'Family Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: {app.isFamilyOwner},
              onSelectionChanged: (s) => app.setFamilyOwnerMode(s.first),
            ),
            const SizedBox(height: 10),
            if (app.isFamilyOwner)
              Container(
                key: const Key('familyOwnerCodeBox'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CyberpunkColors.bgPrimary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CyberpunkColors.neonCyan.withValues(alpha: 0.55),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      purchase.formattedFamilyCode,
                      key: const Key('familyOwnerCodeText'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: CyberpunkColors.neonCyan,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CyberpunkColors.successGreen
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CyberpunkColors.successGreen
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        '${purchase.connectedFamilyMembers}/${purchase.maxFamilyMembers} Üye Bağlı',
                        key: const Key('familyMemberQuotaBadge'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: CyberpunkColors.successGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                key: const Key('familyMemberInputBox'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('familyCodeInput'),
                    controller: _familyCodeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      prefixIcon: const Icon(Icons.key_outlined),
                      hintText: isTr
                          ? '6 Haneli Aile Kodu (Örn: 892341)'
                          : '6-Digit Family Code (e.g. 892341)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('familyJoinButton'),
                    onPressed: () => _onJoinFamily(app, isTr),
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Aileni Koru'),
                  ),
                ],
              ),
            const Divider(height: 22),
            Text(
              isTr
                  ? 'VERO PRO & VERO AİLE PAKETLERİ (0 ms Anında Geçiş)'
                  : 'VERO PRO & VERO FAMILY PLANS (0 ms Instant Upgrade)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: CyberpunkColors.neonCyan,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTr
                  ? '• VERO PRO (${VeroPlanCatalog.proMonthlyPriceText} / ${VeroPlanCatalog.proYearlyPriceText}): ${VeroPlanCatalog.proDescriptionTr}\n'
                      '• VERO AİLE (${VeroPlanCatalog.familyYearlyPriceText}): Tüm Pro özellikler + 4 Cihaza kadar aile koruması.'
                  : '• VERO PRO (${VeroPlanCatalog.proMonthlyPriceText} / ${VeroPlanCatalog.proYearlyPriceText}): ${VeroPlanCatalog.proDescriptionEn}\n'
                      '• VERO FAMILY (${VeroPlanCatalog.familyYearlyPriceText}): All Pro features + up to 4 family devices.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CyberpunkColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('upgradeProButton'),
                  onPressed: () => app.upgradeSubscription(
                    VeroSubscriptionTier.proYearly,
                  ),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                  label: Text(
                    isTr ? 'VERO PRO\'ya Geç' : 'Upgrade to VERO PRO',
                  ),
                ),
                FilledButton.icon(
                  key: const Key('upgradeFamilyButton'),
                  onPressed: () => app.upgradeSubscription(
                    VeroSubscriptionTier.familyYearly,
                  ),
                  icon: const Icon(Icons.groups_outlined, size: 16),
                  label: Text(
                    isTr ? 'VERO AİLE (4 Kişi)' : 'VERO FAMILY (4 Users)',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('openPaywallComparisonBtn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PaywallScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: Text(
                    isTr ? 'Plan Karşılaştırma Tablosu' : 'Plan Comparison Table',
                  ),
                ),
                if (app.isProOrFamily)
                  OutlinedButton(
                    key: const Key('downgradeFreeButton'),
                    onPressed: () => app.upgradeSubscription(
                      VeroSubscriptionTier.free,
                    ),
                    child: Text(isTr ? 'Ücretsiz Mod' : 'Free Tier'),
                  ),
              ],
            ),
            const Divider(height: 22),
            // ENTERPRISE (B2B) SECTION
            ListTile(
              key: const Key('openEnterpriseScreenTile'),
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  size: 20,
                  color: CyberpunkColors.neonCyan,
                ),
              ),
              title: Text(
                isTr ? 'VERO ENTERPRISE (B2B MODU)' : 'VERO ENTERPRISE (B2B MODE)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: CyberpunkColors.neonCyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                isTr
                    ? '19,99 TL / Çalışan / Ay • MDM / EMM desteği, 8 haneli kurumsal kod & yerel ağ senkronizasyonu.'
                    : '19.99 TL / Employee / Mo • MDM / EMM support, 8-digit corporate code & local network sync.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CyberpunkColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: CyberpunkColors.neonCyan),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EnterpriseScreen()),
                );
              },
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.radar_outlined,
                  size: 16,
                  color: CyberpunkColors.electricViolet,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isTr
                        ? 'VeroApp Offline Veri Sızıntısı Radarı'
                        : 'VeroApp Offline Veri Sızıntısı Radarı (Bloom Filter)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: CyberpunkColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('breachRadarInput'),
              controller: _breachInputCtrl,
              onSubmitted: (_) => _onCheckBreach(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.alternate_email_outlined),
                hintText: isTr
                    ? 'E-posta veya telefon (Örn: test@ornek.com)'
                    : 'Email or phone (e.g. test@example.com)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('breachRadarCheckBtn'),
              onPressed: _onCheckBreach,
              icon: const Icon(Icons.security_outlined, size: 16),
              label: Text(
                isTr ? 'Sızıntı Taraması Yap' : 'Scan Data Breaches',
              ),
            ),
            if (_breachResult != null) ...[
              const SizedBox(height: 8),
              Container(
                key: const Key('breachRadarResultBox'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_breachResult!.isLeaked
                          ? CyberpunkColors.dangerRed
                          : CyberpunkColors.successGreen)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _breachResult!.isLeaked
                        ? CyberpunkColors.dangerRed
                        : CyberpunkColors.successGreen,
                  ),
                ),
                child: Text(
                  _breachResult!.isLeaked
                      ? (isTr
                          ? '🚨 UYARI (${_breachResult!.sha1Prefix}***): ${_breachResult!.breachSources.join(", ")} veri sızıntısında eşleşme bulundu!'
                          : '🚨 ALERT (${_breachResult!.sha1Prefix}***): Found in ${_breachResult!.breachSources.join(", ")}!')
                      : (isTr
                          ? '✅ GÜVENLİ (${_breachResult!.sha1Prefix}***): Bilinen sızıntı veritabanlarında eşleşme bulunmadı.'
                          : '✅ SAFE (${_breachResult!.sha1Prefix}***): No match found in known breach signatures.'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _breachResult!.isLeaked
                        ? CyberpunkColors.dangerRed
                        : CyberpunkColors.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrainMetric extends StatelessWidget {
  const _BrainMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
