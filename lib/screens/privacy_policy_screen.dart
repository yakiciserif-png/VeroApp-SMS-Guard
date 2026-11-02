import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../ui/cyberpunk_theme.dart';

/// Comprehensive 100% Offline Privacy Policy Screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('privacyPolicyScreen'),
      appBar: AppBar(
        title: Text(l.t('privacyPolicyTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberpunkColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CyberpunkColors.safeGreen.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: CyberpunkColors.safeGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTr
                        ? 'VeroApp SMS Guard: %100 Çevrimdışı ve Sıfır Veri Toplama Taahhüdü'
                        : 'VeroApp SMS Guard: 100% On-Device & Zero Data Collection Guarantee',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: CyberpunkColors.safeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            theme,
            title: isTr ? '1. Temel İlke: Sıfır İnternet' : '1. Core Principle: Zero Internet',
            content: isTr
                ? 'VeroApp SMS Guard uygulamasında INTERNET izni bulunmamaktadır. Hiçbir mesajınız, arama kaydınız, rehber bilginiz veya kimlik veriniz harici sunuculara aktarılmaz. Tüm yapay zeka ve filtreleme işlemleri cihazınızın kendi donanımında gerçekleşir.'
                : 'VeroApp SMS Guard does not request or hold the INTERNET permission. None of your SMS texts, call logs, contacts, or identities are transmitted to external servers. All processing executes on-device.',
          ),
          _buildSection(
            theme,
            title: isTr ? '2. Kullanılan Sistem İzinleri ve Amaçları' : '2. System Permissions & Purpose',
            content: isTr
                ? '• SMS İzni (RECEIVE_SMS, READ_SMS): Gelen kısa mesajları anlık olarak yerel yapay zeka ile dolandırıcılık testine tabi tutmak için kullanılır.\n'
                  '• Arama İzni (READ_PHONE_STATE, CALL_SCREENING): Gelen çağrılarda şüpheli numaraları ekranda kırmızı uyarı ile göstermek için kullanılır.\n'
                  '• Rehber İzni (READ_CONTACTS): Kayıtlı kişilerinizi arama ve SMS ekranlarında güvenli (yeşil) olarak ayırt etmek için yerel hafızada eşleştirilir.\n'
                  '• Erişilebilirlik Servisi: WhatsApp ve Telegram mesajlarındaki oltalama bağlantılarını (.apk, sahte banka vb.) tıklanmadan önce denetlemek için kullanılır.'
                : '• SMS Permissions: Intercepts and scores incoming SMS on-device using local AI.\n'
                  '• Call Permissions: Evaluates caller phone numbers against local spam databases.\n'
                  '• Contacts Permission: Labels your known contacts in green.\n'
                  '• Accessibility Service: Inspects suspicious links (.apk, phishing) in messaging apps before click.',
          ),
          _buildSection(
            theme,
            title: isTr ? '3. KVKK ve GDPR Uyumluluğu' : '3. KVKK & GDPR Compliance',
            content: isTr
                ? 'Uygulamamız 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) Madde 4, 5 ve 6 ile Avrupa Birliği Genel Veri Koruma Tüzüğü (GDPR) Madde 6 ve 9 hükümlerine tam uyumludur. Veri sorumlusuna veri aktarımı söz konusu değildir.'
                : 'Strictly compliant with 6698 KVKK and European GDPR Articles 6 & 9. No external data controller transfers occur.',
          ),
          _buildSection(
            theme,
            title: isTr ? '4. İletişim' : '4. Contact Information',
            content: isTr
                ? 'Gizlilik politikamızla ilgili soru ve talepleriniz için: support@veroapp.com'
                : 'For inquiries regarding this privacy policy: support@veroapp.com',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: CyberpunkColors.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: CyberpunkColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
