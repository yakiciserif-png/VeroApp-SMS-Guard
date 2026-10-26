import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../engines/vero_link_scanner.dart';
import 'cyberpunk_theme.dart';

/// [ADIM 4] LINK SCANNER SCREEN (MOD B: Paylaşım Menüsü & Manuel Yapıştırma Fallback)
class LinkScannerScreen extends StatefulWidget {
  const LinkScannerScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  State<LinkScannerScreen> createState() => _LinkScannerScreenState();
}

class _LinkScannerScreenState extends State<LinkScannerScreen> {
  late final TextEditingController _controller;
  LinkScanResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
    if (widget.initialUrl != null && widget.initialUrl!.trim().isNotEmpty) {
      _result = VeroLinkScanner.instance.scan(widget.initialUrl!.trim());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scan([String? overrideUrl]) {
    final url = (overrideUrl ?? _controller.text).trim();
    if (url.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final res = VeroLinkScanner.instance.scan(url);
    setState(() {
      _result = res;
    });
  }

  Future<void> _pasteAndScan() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pano boş, kopyalanmış bir link bulunamadı.')),
        );
      }
      return;
    }
    _controller.text = text;
    _scan(text);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final theme = Theme.of(context);
    final app = AppScope.of(context);

    return Scaffold(
      key: const Key('linkScannerScreen'),
      backgroundColor: CyberpunkColors.backgroundDark,
      appBar: AppBar(
        title: Text(isTr ? 'Link Radarı (Safe-Click)' : 'Link Radar (Safe-Click)'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Instructions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CyberpunkColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CyberpunkColors.neonCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, color: CyberpunkColors.neonCyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isTr ? 'Link yapıştırın veya paylaşın' : 'Paste or share a link',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTr
                        ? 'WhatsApp, Telegram veya tarayıcınızda şüpheli gördüğünüz bağlantıyı kopyalayıp buraya yapıştırın veya Paylaş menüsünden VeroApp\'i seçin.'
                        : 'Copy any suspicious link from WhatsApp, Telegram, or your browser and paste it here, or choose VeroApp from the Share menu.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: CyberpunkColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CyberpunkColors.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTr
                          ? 'Mod: ${app.linkScannerMode == LinkScannerMode.automatic ? "Otomatik (Erişilebilirlik)" : "Manuel (Paylaşım / Yapıştır)"}'
                          : 'Mode: ${app.linkScannerMode == LinkScannerMode.automatic ? "Automatic (Accessibility)" : "Manual (Share / Paste)"}',
                      style: const TextStyle(
                        color: CyberpunkColors.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Field & Paste Action
            TextField(
              key: const Key('linkInput'),
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isTr ? 'https://ornek-site.com/takip' : 'https://example.com/track',
                hintStyle: const TextStyle(color: CyberpunkColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: CyberpunkColors.neonCyan),
                suffixIcon: IconButton(
                  key: const Key('pasteLinkBtn'),
                  tooltip: isTr ? 'Panodan Yapıştır' : 'Paste from clipboard',
                  icon: const Icon(Icons.content_paste_outlined, color: CyberpunkColors.neonCyan),
                  onPressed: _pasteAndScan,
                ),
                filled: true,
                fillColor: CyberpunkColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: CyberpunkColors.neonCyan.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: CyberpunkColors.neonCyan,
                    width: 1.8,
                  ),
                ),
              ),
              onSubmitted: (_) => _scan(),
            ),
            const SizedBox(height: 12),

            // Scan Button
            FilledButton.icon(
              key: const Key('scanLinkBtn'),
              onPressed: () => _scan(),
              icon: const Icon(Icons.radar_outlined, color: CyberpunkColors.backgroundDark),
              label: Text(
                isTr ? 'Bağlantıyı Tara' : 'Scan Link',
                style: const TextStyle(
                  color: CyberpunkColors.backgroundDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: CyberpunkColors.neonCyan,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 20),

            // Result Display
            if (_result != null) ...[
              _buildResultCard(_result!, isTr),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(LinkScanResult res, bool isTr) {
    final (Color badgeColor, String badgeTitle, IconData icon) = switch (res.riskLevel) {
      LinkRiskLevel.safe => (
          CyberpunkColors.safeGreen,
          isTr ? 'GÜVENLİ (Tehdit Bulunamadı)' : 'SAFE (No Threat Found)',
          Icons.verified_user_outlined,
        ),
      LinkRiskLevel.suspicious => (
          CyberpunkColors.warningAmber,
          isTr ? 'ŞÜPHELİ (Dikkatli Olun)' : 'SUSPICIOUS (Exercise Caution)',
          Icons.warning_amber_rounded,
        ),
      LinkRiskLevel.dangerous => (
          CyberpunkColors.alertRed,
          isTr ? 'TEHLİKELİ (Tıklamayın!)' : 'DANGEROUS (Do Not Tap!)',
          Icons.gpp_bad_rounded,
        ),
    };

    return Container(
      key: const Key('linkScanResultCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  badgeTitle,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isTr ? "Domain:" : "Domain:"} ${res.domain}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isTr ? "Risk Skoru:" : "Risk Score:"} %${res.riskScore.toStringAsFixed(0)}',
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E2846)),
          const SizedBox(height: 4),
          Text(
            isTr ? 'Tespit Edilen Belirtiler:' : 'Identified Signals:',
            style: const TextStyle(
              color: CyberpunkColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          if (res.reasons.isEmpty)
            Text(
              isTr
                  ? '• Bilinen oltalama veya zararlı dosya örüntüsüne rastlanmadı.'
                  : '• No phishing or malicious signatures found.',
              style: const TextStyle(color: CyberpunkColors.safeGreen, fontSize: 11),
            )
          else
            for (final reason in res.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fiber_manual_record, color: badgeColor, size: 8),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
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
