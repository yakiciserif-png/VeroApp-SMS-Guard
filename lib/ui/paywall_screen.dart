import 'package:flutter/material.dart';

import '../app.dart';
import '../core/monetization/feature_gates.dart';
import '../core/monetization/purchase_service.dart';
import 'cyberpunk_theme.dart';

/// [ADIM 2] PAYWALL & FEATURE GATES COMPARISON SCREEN
///
/// Features a 3-column matrix (Free: Grey, PRO: Neon Cyan, Family: Gold)
/// with "Günde 20 SMS yeterli mi?" call to action.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    const goldColor = Color(0xFFFFD700);
    const greyColor = Color(0xFF9E9E9E);

    return Scaffold(
      key: const Key('paywallScreen'),
      backgroundColor: CyberpunkColors.backgroundDark,
      appBar: AppBar(
        title: Text(isTr ? 'Planlar ve Özellikler' : 'Plans & Features'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Motivational Hook Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CyberpunkColors.surfaceDark,
                    CyberpunkColors.neonCyan.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CyberHexShieldIcon(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isTr ? 'Günde 20 SMS yeterli mi?' : 'Is 20 SMS/day enough?',
                        style: const TextStyle(
                          color: CyberpunkColors.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Bankalar, kargo bildirimleri ve günlük mesajlar arasında sınırları kaldırın. '
                          '%100 çevrimdışı, sıfır veri transferi ile cihazınızı tam korumaya alın.'
                        : 'Remove artificial limits for banks, OTPs, and delivery messages. '
                          '100% offline, zero data transfer for maximum peace of mind.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3-Column Plan Cards Header
            Row(
              children: [
                Expanded(
                  child: _PlanHeaderBadge(
                    title: 'ÜCRETSİZ',
                    subtitle: 'Temel',
                    color: greyColor,
                    isCurrent: app.subscriptionTier == VeroSubscriptionTier.free && !app.isFamilyMember,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanHeaderBadge(
                    title: 'VERO PRO',
                    subtitle: '39,99 TL/ay',
                    color: CyberpunkColors.neonCyan,
                    isCurrent: (app.subscriptionTier == VeroSubscriptionTier.proMonthly ||
                            app.subscriptionTier == VeroSubscriptionTier.proYearly) &&
                        !app.isFamilyMember,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanHeaderBadge(
                    title: 'VERO AİLE',
                    subtitle: '799,99 TL/yıl',
                    color: goldColor,
                    isCurrent: app.isFamilyOwner || app.isFamilyMember,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comparison Table
            Card(
              key: const Key('paywallComparisonMatrix'),
              color: CyberpunkColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  children: [
                    // 3-Column Table Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: greyColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FREE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: greyColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: CyberpunkColors.neonCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AİLE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: goldColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Color(0xFF1E2846),
                      height: 12,
                      thickness: 1,
                    ),
                    for (int i = 0; i < VeroFeatureGates.comparisonRows.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          color: Color(0xFF1E2846),
                          height: 16,
                          thickness: 0.8,
                        ),
                      _ComparisonRowWidget(
                        row: VeroFeatureGates.comparisonRows[i],
                        isTr: isTr,
                        goldColor: goldColor,
                        greyColor: greyColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Upgrade Buttons
            Text(
              isTr ? 'Plan Seçin & Anında Aktifleştirin' : 'Select Plan & Activate Instantly',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),

            // PRO Monthly Button
            FilledButton.icon(
              key: const Key('upgradeProMonthlyBtn'),
              onPressed: () async {
                await app.upgradeSubscription(VeroSubscriptionTier.proMonthly);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTr ? 'VERO PRO Aylık üyeliğiniz aktifleşti!' : 'VERO PRO Monthly activated!'),
                    backgroundColor: CyberpunkColors.neonCyan,
                  ),
                );
              },
              icon: const Icon(Icons.flash_on, color: CyberpunkColors.backgroundDark),
              label: Text(
                isTr ? 'VERO PRO Aylık — 39,99 TL / ay' : 'VERO PRO Monthly — 39.99 TRY / mo',
                style: const TextStyle(fontWeight: FontWeight.bold, color: CyberpunkColors.backgroundDark),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: CyberpunkColors.neonCyan,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 8),

            // PRO Yearly Button (Best Value)
            OutlinedButton.icon(
              key: const Key('upgradeProYearlyBtn'),
              onPressed: () async {
                await app.upgradeSubscription(VeroSubscriptionTier.proYearly);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTr ? 'VERO PRO Yıllık üyeliğiniz aktifleşti!' : 'VERO PRO Yearly activated!'),
                    backgroundColor: CyberpunkColors.safeGreen,
                  ),
                );
              },
              icon: const Icon(Icons.star, color: CyberpunkColors.neonCyan),
              label: Text(
                isTr ? 'VERO PRO Yıllık — 299,99 TL / yıl (%37 Tasarruf)' : 'VERO PRO Yearly — 299.99 TRY / yr',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CyberpunkColors.neonCyan, width: 1.5),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 8),

            // Family Yearly Button
            FilledButton.icon(
              key: const Key('upgradeFamilyYearlyBtn'),
              onPressed: () async {
                await app.upgradeSubscription(VeroSubscriptionTier.familyYearly);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTr ? 'VERO AİLE üyeliğiniz aktifleşti (4 Cihaz)!' : 'VERO FAMILY Plan activated!'),
                    backgroundColor: goldColor,
                  ),
                );
              },
              icon: const Icon(Icons.family_restroom, color: CyberpunkColors.backgroundDark),
              label: Text(
                isTr ? 'VERO AİLE Yıllık — 799,99 TL / yıl (4 Kişilik)' : 'VERO FAMILY Yearly — 799.99 TRY / yr',
                style: const TextStyle(color: CyberpunkColors.backgroundDark, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: goldColor,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlanHeaderBadge extends StatelessWidget {
  const _PlanHeaderBadge({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isCurrent,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCurrent ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isCurrent ? 0.9 : 0.4),
          width: isCurrent ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: CyberpunkColors.textSecondary,
              fontSize: 10,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AKTİF',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRowWidget extends StatelessWidget {
  const _ComparisonRowWidget({
    required this.row,
    required this.isTr,
    required this.goldColor,
    required this.greyColor,
  });

  final FeatureComparisonRow row;
  final bool isTr;
  final Color goldColor;
  final Color greyColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? row.featureTr : row.featureEn,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Free Column
            Expanded(
              child: _MatrixCell(
                text: row.freeText,
                allowed: row.freeAllowed,
                color: greyColor,
              ),
            ),
            const SizedBox(width: 6),
            // PRO Column
            Expanded(
              child: _MatrixCell(
                text: row.proText,
                allowed: row.proAllowed,
                color: CyberpunkColors.neonCyan,
              ),
            ),
            const SizedBox(width: 6),
            // Family Column
            Expanded(
              child: _MatrixCell(
                text: row.familyText,
                allowed: row.familyAllowed,
                color: goldColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.text,
    required this.allowed,
    required this.color,
  });

  final String text;
  final bool allowed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? color : const Color(0xFF616161),
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: allowed ? Colors.white : CyberpunkColors.textSecondary,
              fontSize: 10,
              fontWeight: allowed ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
