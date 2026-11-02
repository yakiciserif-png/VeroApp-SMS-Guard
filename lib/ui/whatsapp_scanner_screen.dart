import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engines/vero_whatsapp_scanner.dart';
import 'cyberpunk_theme.dart';

/// WhatsApp / Messenger Chat & Link Scanner Screen.
///
/// Supports:
/// - Direct clipboard paste & scan
/// - External Android Share Intent handling
class WhatsAppScannerScreen extends StatefulWidget {
  const WhatsAppScannerScreen({super.key, this.initialText});

  final String? initialText;

  @override
  State<WhatsAppScannerScreen> createState() => _WhatsAppScannerScreenState();
}

class _WhatsAppScannerScreenState extends State<WhatsAppScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  WhatsAppScanResult? _scanResult;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textController.text = widget.initialText!;
      _performScan();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _performScan() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isScanning = true;
    });

    final result = VeroWhatsAppScanner.scanMessage(text);

    setState(() {
      _scanResult = result;
      _isScanning = false;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _textController.text = data.text!;
      _performScan();
    }
  }

  void _clear() {
    _textController.clear();
    setState(() {
      _scanResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('whatsAppScannerScreen'),
      backgroundColor: CyberpunkColors.bgPrimary,
      appBar: AppBar(
        title: const Text(
          'WhatsApp & Mesaj Tarayıcı',
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: CyberpunkColors.bgSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: CyberpunkColors.neonCyan),
            tooltip: 'Temizle',
            onPressed: _clear,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informative header banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CyberpunkColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CyberpunkColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: CyberpunkColors.neonCyan, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Şüpheli WhatsApp / Telegram mesajlarını veya bağlantılarını yapıştırın. %100 çevrimdışı 6D motor anında analiz eder.',
                      style: TextStyle(
                        fontFamily: 'Book Antiqua',
                        color: CyberpunkColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Text input area
            TextField(
              key: const Key('whatsAppMessageInput'),
              controller: _textController,
              maxLines: 5,
              style: const TextStyle(
                fontFamily: 'Book Antiqua',
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'WhatsApp mesajını buraya yapıştırın...',
                hintStyle: const TextStyle(color: CyberpunkColors.textSecondary),
                filled: true,
                fillColor: CyberpunkColors.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CyberpunkColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CyberpunkColors.neonCyan, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('pasteAndScanBtn'),
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, color: CyberpunkColors.neonCyan),
                    label: const Text(
                      'Yapıştır',
                      style: TextStyle(fontFamily: 'Book Antiqua', color: CyberpunkColors.neonCyan),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CyberpunkColors.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    key: const Key('scanMessageBtn'),
                    onPressed: _performScan,
                    icon: const Icon(Icons.search_rounded, color: Colors.black),
                    label: const Text(
                      'Mesajı Tara',
                      style: TextStyle(
                        fontFamily: 'Book Antiqua',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberpunkColors.neonCyan,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Result Display Card
            if (_isScanning)
              const Center(child: CircularProgressIndicator(color: CyberpunkColors.neonCyan))
            else if (_scanResult != null)
              _buildResultCard(_scanResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(WhatsAppScanResult result) {
    Color badgeColor = const Color(0xFF00E676);
    if (result.isSuspicious) badgeColor = const Color(0xFFFF9100);
    if (result.isDangerous) badgeColor = const Color(0xFFFF1744);

    return Container(
      key: const Key('whatsAppScanResultCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberpunkColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  result.badgeText,
                  style: TextStyle(
                    fontFamily: 'Book Antiqua',
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                'Risk: %${result.riskScore.toInt()}',
                style: TextStyle(
                  fontFamily: 'Book Antiqua',
                  color: badgeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            result.threatSummary,
            style: const TextStyle(
              fontFamily: 'Book Antiqua',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Action note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberpunkColors.bgPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  result.isDangerous ? Icons.dangerous_rounded : Icons.info_outline_rounded,
                  color: badgeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendedAction,
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      color: CyberpunkColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: result.isDangerous ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Tespit Edilen Bulgular:',
              style: TextStyle(
                fontFamily: 'Book Antiqua',
                color: CyberpunkColors.neonCyan,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...result.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontFamily: 'Book Antiqua',
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
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
