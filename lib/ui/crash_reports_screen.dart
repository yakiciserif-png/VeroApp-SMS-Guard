import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_localizations.dart';
import '../engines/vero_crash_logger.dart';
import 'cyberpunk_theme.dart';

/// Screen allowing users to inspect, clear, and optionally export crash logs.
class CrashReportsScreen extends StatefulWidget {
  const CrashReportsScreen({super.key});

  @override
  State<CrashReportsScreen> createState() => _CrashReportsScreenState();
}

class _CrashReportsScreenState extends State<CrashReportsScreen> {
  void _clearLogs() {
    setState(() {
      VeroCrashLogger.clearLogs();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hata raporları başarıyla temizlendi.')),
    );
  }

  void _exportLogs() {
    final text = VeroCrashLogger.exportLogsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hata raporları panoya kopyalandı! Destek ekibimize (support@veroapp.com) e-posta ile gönderebilirsiniz.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final count = VeroCrashLogger.getLogCountLast7Days();
    final records = VeroCrashLogger.records;

    return Scaffold(
      key: const Key('crashReportsScreen'),
      appBar: AppBar(
        title: Text(l.t('crashReportsTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: count > 0 ? CyberpunkColors.alertRed : CyberpunkColors.safeGreen,
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
                      Icon(
                        count > 0 ? Icons.bug_report : Icons.check_circle_outline,
                        color: count > 0 ? CyberpunkColors.alertRed : CyberpunkColors.safeGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isTr
                              ? 'Son 7 günde $count hata oluştu'
                              : '$count error(s) in last 7 days',
                          key: const Key('crashLogCountText'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: CyberpunkColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isTr
                        ? 'VeroApp tamamen çevrimdışıdır. Çökmeler veya istisnalar yalnızca cihazınızda saklanır ve asla otomatik olarak bir sunucuya yüklenmez.'
                        : 'VeroApp operates 100% offline. Exception logs stay strictly on your phone and are never automatically transmitted.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('clearCrashLogsBtn'),
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(isTr ? 'Temizle' : 'Clear'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('exportCrashLogsBtn'),
                          onPressed: _exportLogs,
                          style: FilledButton.styleFrom(
                            backgroundColor: CyberpunkColors.neonCyan,
                            foregroundColor: CyberpunkColors.backgroundDark,
                          ),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(
                            isTr ? 'Dışa Aktar' : 'Export',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  isTr
                      ? 'Harika! Kaydedilmiş herhangi bir çökme veya hata bulunmuyor.'
                      : 'Great! No recorded crashes or unhandled exceptions.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: CyberpunkColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            Text(
              isTr ? 'Kayıtlı Hata Günlüğü' : 'Logged Exceptions',
              style: theme.textTheme.titleSmall?.copyWith(
                color: CyberpunkColors.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in records.reversed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: CyberpunkColors.surfaceDark,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.timestamp.toIso8601String().split('.').first.replaceFirst('T', ' '),
                            style: const TextStyle(
                              color: CyberpunkColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            r.deviceInfo,
                            style: const TextStyle(
                              color: CyberpunkColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.errorMessage,
                        style: const TextStyle(
                          color: CyberpunkColors.alertRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (r.stackTrace.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.stackTrace,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            color: CyberpunkColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
