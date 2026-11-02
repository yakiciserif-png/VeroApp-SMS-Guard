import 'package:flutter/material.dart';

import '../engines/vero_threat_updater.dart';

/// [ADIM 7] VeroApp Threat Database Statistics Screen (FAZA 7)
///
/// Displays real-time on-device database metrics:
/// - Total spam numbers
/// - Total phishing domains
/// - Total fraud patterns
/// - Last update timestamp
/// - Source distribution (Open source 60%, Turkey special 25%, Community shield 15%)
/// - Manual update trigger ("Şimdi Güncelle")
/// - Update history log
class DatabaseStatsScreen extends StatefulWidget {
  const DatabaseStatsScreen({super.key});

  @override
  State<DatabaseStatsScreen> createState() => _DatabaseStatsScreenState();
}

class _DatabaseStatsScreenState extends State<DatabaseStatsScreen> {
  bool _isChecking = false;
  String? _statusBanner;

  final updater = VeroThreatUpdater.instance;

  Future<void> _handleManualUpdate() async {
    setState(() {
      _isChecking = true;
      _statusBanner = 'Güncellemeler kontrol ediliyor...';
    });

    try {
      final info = await updater.checkForUpdate(forceCheck: true);
      if (!mounted) return;

      if (info != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            ),
            title: const Text(
              'Yeni Tehdit Güncellemesi',
              style: TextStyle(
                fontFamily: 'Book Antiqua',
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '${info.promptMessage}\n\nİndirmek ve yerel korumayı güncellemek istiyor musunuz?',
              style: const TextStyle(
                fontFamily: 'Book Antiqua',
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Daha Sonra', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('İndir ve Güncelle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          setState(() => _statusBanner = 'Paket indiriliyor ve doğrulanıyor...');
          final pkg = await updater.downloadAndVerify(info.downloadUrl);
          if (pkg != null) {
            final res = await updater.applyPackage(pkg);
            if (mounted) {
              setState(() {
                _statusBanner = res.message;
              });
            }
          } else {
            if (mounted) {
              setState(() => _statusBanner = 'Güncelleme paketi doğrulanamadı.');
            }
          }
        } else {
          if (mounted) setState(() => _statusBanner = 'Güncelleme ertelendi.');
        }
      } else {
        setState(() {
          _statusBanner = '✅ Veritabanınız zaten güncel. Ek tehdit paketi bulunamadı.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusBanner = 'Bağlantı sağlanamadı. Çevrimdışı koruma aktif.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0B1020);
    const cardBg = Color(0xFF131C31);
    const cyan = Color(0xFF00E5FF);
    const textLight = Color(0xFFE2E8F0);

    final spamCount = updater.totalSpamNumbers;
    final domainCount = updater.totalPhishingDomains;
    final patternCount = updater.totalFraudPatterns;
    final totalCount = updater.totalThreatSignatures;
    final lastDate = updater.formattedLastUpdateDate;
    final historyList = updater.updateHistory;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: const Text(
          'Veritabanı İstatistikleri',
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            color: textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Status feedback banner
            if (_statusBanner != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyan.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: cyan, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusBanner!,
                        style: const TextStyle(
                          fontFamily: 'Book Antiqua',
                          color: textLight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hero Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Toplam Tehdit İmzası',
                          style: TextStyle(
                            fontFamily: 'Book Antiqua',
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Son: $lastDate',
                          style: const TextStyle(
                            fontFamily: 'Book Antiqua',
                            color: cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalCount.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        ),
                    style: const TextStyle(
                      fontFamily: 'Book Antiqua',
                      color: cyan,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '%100 Yerel Bellekte Aktif Koruma',
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3-Metric Metric Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Spam Numara',
                    count: spamCount,
                    icon: Icons.phone_disabled,
                    color: const Color(0xFFFF5252),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Phishing Domain',
                    count: domainCount,
                    icon: Icons.link_off,
                    color: const Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Dolandırıcılık Kalıbı',
                    count: patternCount,
                    icon: Icons.rule,
                    color: const Color(0xFF69F0AE),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Source Distribution Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kaynak Dağılımı',
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      color: cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDistributionBar(
                    label: 'Açık Kaynak İstihbarat (Spamhaus, OpenPhish)',
                    percent: 60,
                    color: cyan,
                  ),
                  const SizedBox(height: 12),
                  _buildDistributionBar(
                    label: 'Türkiye Özel Kaynaklar (BTK, EGM, USOM, Şikayetvar)',
                    percent: 25,
                    color: const Color(0xFFFF7043),
                  ),
                  const SizedBox(height: 12),
                  _buildDistributionBar(
                    label: 'Topluluk Kalkanı Anonim Bildirimleri',
                    percent: 15,
                    color: const Color(0xFFAB47BC),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Update Trigger Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isChecking ? null : _handleManualUpdate,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.refresh, size: 22),
                label: Text(
                  _isChecking ? 'Kontrol Ediliyor...' : 'Şimdi Güncelle',
                  style: const TextStyle(
                    fontFamily: 'Book Antiqua',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Update History List
            const Text(
              'Güncelleme Geçmişi',
              style: TextStyle(
                fontFamily: 'Book Antiqua',
                color: cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: historyList.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: cyan, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry,
                            style: const TextStyle(
                              fontFamily: 'Book Antiqua',
                              color: textLight,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            count.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]}.',
                ),
            style: TextStyle(
              fontFamily: 'Book Antiqua',
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Book Antiqua',
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar({
    required String label,
    required int percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Book Antiqua',
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '%$percent',
              style: TextStyle(
                fontFamily: 'Book Antiqua',
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
