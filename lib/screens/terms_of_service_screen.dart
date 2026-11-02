import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../ui/cyberpunk_theme.dart';

/// Terms of Service Screen.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('termsOfServiceScreen'),
      appBar: AppBar(
        title: Text(l.t('termsOfServiceTitle')),
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
                color: CyberpunkColors.neonCyan.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.policy_outlined, color: CyberpunkColors.neonCyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTr
                        ? 'VeroApp SMS Guard Kullanım ve Lisans Sözleşmesi'
                        : 'VeroApp SMS Guard User Agreement & Terms',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: CyberpunkColors.neonCyan,
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
            title: isTr ? '1. Hizmet Kapsamı' : '1. Scope of Service',
            content: isTr
                ? 'VeroApp SMS Guard, kullanıcılara cihaz içi yapay zeka ile SMS dolandırıcılığı, çağrı spam filtreleme ve link güvenliği denetimi hizmeti sunar. Uygulama bağımsız ve çevrimdışı çalışmaktadır.'
                : 'VeroApp SMS Guard provides on-device AI SMS smishing detection, call spam protection, and link security scanning. Operates autonomously offline.',
          ),
          _buildSection(
            theme,
            title: isTr ? '2. Lisans ve Abonelikler' : '2. Licensing & Subscriptions',
            content: isTr
                ? '• Ücretsiz Sürüm: Temel koruma kalkanları ve OTP sınıflandırmasını içerir.\n'
                  '• VERO PRO (39,99 TL/ay veya 299,99 TL/yıl): Safe-Click Röntgeni Plus ve Veri Sızıntısı Radarı.\n'
                  '• VERO AİLE (799,99 TL/yıl): 4 kişiye kadar tek kodla cihaz içi koruma.\n'
                  '• VERO KURUMSAL (19,99 TL/çalışan/ay): Şirket ve çalışan güvenliği.'
                : '• Free Tier: Basic shields & OTP categorization.\n'
                  '• VERO PRO (39.99 TRY/mo or 299.99 TRY/yr): Safe-Click Plus and Breach Radar.\n'
                  '• VERO FAMILY (799.99 TRY/yr): 4 devices under 1 local code.\n'
                  '• VERO ENTERPRISE (19.99 TRY/employee/mo): Corporate protection.',
          ),
          _buildSection(
            theme,
            title: isTr ? '3. Sorumluluk Sınırları' : '3. Limitation of Liability',
            content: isTr
                ? 'Yapay zeka modellerimiz yüksek doğrulukla çalışmakla birlikte, dolandırıcılık yöntemleri sürekli değişmektedir. Uygulama bilgilendirme ve önleme amaçlı olup, nihai karar kullanıcıya aittir.'
                : 'While our AI models deliver high detection accuracy, phishing tactics evolve constantly. VeroApp serves as a preventative shield; final discretion remains with the user.',
          ),
          _buildSection(
            theme,
            title: isTr ? '4. Destek ve İletişim' : '4. Support & Contact',
            content: isTr
                ? 'Resmi iletişim adresi: support@veroapp.com'
                : 'Official contact: support@veroapp.com',
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
