import 'package:flutter/material.dart';

import '../app.dart';
import '../core/localization/app_localizations.dart';
import 'cyberpunk_theme.dart';

/// Modal dialog shown on first app launch to secure explicit GDPR/KVKK consent
/// regarding VeroApp's 100% offline, zero-cloud architecture.
class FirstLaunchConsentDialog extends StatelessWidget {
  const FirstLaunchConsentDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final app = AppScope.read(context);
    if (app.hasAcceptedKvkkConsent) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FirstLaunchConsentDialog(),
    );
  }

  void _handleAccept(BuildContext context) {
    final app = AppScope.read(context);
    // 1. Immediately dismiss dialog without blocking UI
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    // 2. Synchronously set consent state and trigger background loaders
    app.acceptKvkkConsent();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('firstLaunchConsentDialog'),
      backgroundColor: CyberpunkColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: CyberpunkColors.neonCyan.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          const CyberHexShieldIcon(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.t('firstLaunchConsentTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: CyberpunkColors.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CyberpunkColors.safeGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CyberpunkColors.safeGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: CyberpunkColors.safeGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTr
                          ? '%100 Çevrimdışı • Sıfır İnternet İzni • Sıfır Veri Toplama'
                          : '100% Offline • Zero Internet • Zero Data Collection',
                      style: const TextStyle(
                        color: CyberpunkColors.safeGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isTr
                  ? 'VeroApp SMS Guard, kişisel verilerinizi korumak üzere tasarlanmıştır. SMS mesajlarınız, çağrı kayıtlarınız ve rehberiniz asla telefonunuzdan dışarı çıkmaz, harici sunuculara veya üçüncü taraflara iletilmez.\n\n'
                    'Tüm yapay zeka analizleri doğrudan cihazınızda gerçekleşir. 6698 sayılı KVKK ve Avrupa Birliği GDPR standartlarına tam uyumludur.'
                  : 'VeroApp SMS Guard is engineered with absolute on-device privacy. Your messages, calls, and contacts never leave your phone and are never transmitted to external cloud servers.\n\n'
                    'All AI classifications execute locally. Fully compliant with 6698 KVKK and EU GDPR.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: CyberpunkColors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleAccept(context),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('consentAcceptBtn'),
              onPressed: () => _handleAccept(context),
              style: FilledButton.styleFrom(
                backgroundColor: CyberpunkColors.neonCyan,
                foregroundColor: CyberpunkColors.backgroundDark,
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l.t('firstLaunchConsentAccept'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
