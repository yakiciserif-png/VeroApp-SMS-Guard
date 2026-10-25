import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../core/localization/app_localizations.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t('aiBrainTitle'),
                            style: theme.textTheme.titleMedium?.copyWith(
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
          header(l.t('shieldsTitle')),
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
          ] else
            ListTile(
              leading: const Icon(Icons.sms_failed_outlined),
              title: Text(l.t('settingsIosGuide')),
              subtitle: Text(l.t('settingsIosGuideDesc')),
            ),
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
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
