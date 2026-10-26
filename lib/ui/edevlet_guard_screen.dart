import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../engines/vero_edevlet_guard.dart';
import 'cyberpunk_theme.dart';

/// Screen dedicated to auditing e-Devlet password security 100% offline.
class EDevletGuardScreen extends StatefulWidget {
  const EDevletGuardScreen({super.key});

  @override
  State<EDevletGuardScreen> createState() => _EDevletGuardScreenState();
}

class _EDevletGuardScreenState extends State<EDevletGuardScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscureText = true;
  VeroEDevletAuditResult? _auditResult;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _runAudit() {
    final text = _passwordCtrl.text;
    if (text.isEmpty) return;
    setState(() {
      _auditResult = VeroEDevletGuard.auditPassword(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final result = _auditResult;

    return Scaffold(
      key: const Key('edevletGuardScreen'),
      appBar: AppBar(
        title: Text(l.t('eDevletGuardTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: CyberpunkColors.neonCyan.withValues(alpha: 0.65),
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
                          isTr
                              ? 'e-Devlet Şifre Denetimi'
                              : 'e-Devlet Password Audit',
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
                        ? 'e-Devlet şifrenizi girerek sızdırılmış veritabanlarında yer alıp almadığını ve parola karmaşıklığını 100% çevrimdışı denetleyin. Şifreniz asla kaydedilmez ve internete iletilmez.'
                        : 'Audit your e-Devlet password complexity and check whether it was leaked in breaches 100% offline. Passwords never leave this device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('eDevletPasswordInput'),
                    controller: _passwordCtrl,
                    obscureText: _obscureText,
                    style: const TextStyle(
                      fontFamily: 'Book Antiqua',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: isTr ? 'e-Devlet Şifreniz' : 'e-Devlet Password',
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, color: CyberpunkColors.neonCyan),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: CyberpunkColors.neonCyan,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('eDevletCheckBtn'),
                    onPressed: _runAudit,
                    style: FilledButton.styleFrom(
                      backgroundColor: CyberpunkColors.neonCyan,
                      foregroundColor: CyberpunkColors.backgroundDark,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.verified_user),
                    label: Text(
                      isTr ? 'Şifre Güvenliğini Denetle' : 'Check Password Security',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            Card(
              key: const Key('eDevletResultCard'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: result.isExposed
                      ? CyberpunkColors.alertRed
                      : (result.isWeak ? CyberpunkColors.warningAmber : CyberpunkColors.safeGreen),
                  width: 1.5,
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
                          result.isExposed
                              ? Icons.gpp_bad
                              : (result.isWeak ? Icons.warning_amber : Icons.verified),
                          color: result.isExposed
                              ? CyberpunkColors.alertRed
                              : (result.isWeak ? CyberpunkColors.warningAmber : CyberpunkColors.safeGreen),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.isExposed
                                ? (isTr ? 'TEHLİKE: ŞİFRE SIZDIRILMIŞ' : 'BREACH DETECTED')
                                : (result.isWeak
                                    ? (isTr ? 'DİKKAT: ZAYIF ŞİFRE' : 'WEAK PASSWORD')
                                    : (isTr ? 'GÜVENLİ ŞİFRE' : 'SECURE PASSWORD')),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: result.isExposed
                                  ? CyberpunkColors.alertRed
                                  : (result.isWeak
                                      ? CyberpunkColors.warningAmber
                                      : CyberpunkColors.safeGreen),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CyberpunkColors.backgroundDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CyberpunkColors.neonCyan.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '${result.securityScore} / 100',
                            style: const TextStyle(
                              color: CyberpunkColors.neonCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.localizedStatus(isTr),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: CyberpunkColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.recommendation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CyberpunkColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberpunkColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CyberpunkColors.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: CyberpunkColors.neonCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTr
                        ? '%100 Yerel Koruma: Parola verileri bellekten anında temizlenir. Hiçbir harici sunucuya veya üçüncü tarafa gönderilmez.'
                        : '100% On-Device Protection: Passwords are cleared from memory and never transmitted anywhere.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
