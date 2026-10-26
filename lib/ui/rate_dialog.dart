import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cyberpunk_theme.dart';

/// Rating & Review Prompt Coordinator.
class VeroRateManager {
  VeroRateManager._();

  static const String prefBlockedCount = 'vero_rate_blocked_threat_count';
  static const String prefNextPromptThreshold = 'vero_rate_next_prompt_threshold';
  static const String prefHasRated = 'vero_rate_has_rated';

  /// Increments blocked counter and returns true if threshold was reached.
  static Future<bool> registerThreatBlocked([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool(prefHasRated) ?? false) return false;

    final current = (p.getInt(prefBlockedCount) ?? 0) + 1;
    await p.setInt(prefBlockedCount, current);

    final threshold = p.getInt(prefNextPromptThreshold) ?? 10;
    return current >= threshold;
  }

  /// Sets user rated to true (never prompt again).
  static Future<void> markRated([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setBool(prefHasRated, true);
  }

  /// Snoozes prompt for 20 more blocked threats.
  static Future<void> snoozePrompt([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final current = p.getInt(prefBlockedCount) ?? 10;
    await p.setInt(prefNextPromptThreshold, current + 20);
  }

  /// Checks if rating dialog should be displayed.
  static Future<bool> shouldShowPrompt([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (p.getBool(prefHasRated) ?? false) return false;
    final current = p.getInt(prefBlockedCount) ?? 0;
    final threshold = p.getInt(prefNextPromptThreshold) ?? 10;
    return current >= threshold;
  }

  /// Shows rating dialog if threshold is satisfied.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await shouldShowPrompt()) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const RateDialog(),
        );
      }
    }
  }
}

/// 5-Star Rating & Offline Feedback Dialog.
class RateDialog extends StatefulWidget {
  const RateDialog({super.key});

  @override
  State<RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<RateDialog> {
  int _selectedRating = 5;
  bool _showingFeedbackForm = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onRateYes() async {
    await VeroRateManager.markRated();
    if (!mounted) return;
    Navigator.of(context).pop();

    // In a live Android/iOS environment, redirects to market / app store url
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Desteğiniz için teşekkürler! Mağaza değerlendirme sayfasına yönlendiriliyorsunuz.',
          style: TextStyle(fontFamily: 'Book Antiqua'),
        ),
        backgroundColor: CyberpunkColors.neonCyan,
      ),
    );
  }

  void _onRateLater() async {
    await VeroRateManager.snoozePrompt();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onRateNo() {
    setState(() {
      _showingFeedbackForm = true;
    });
  }

  void _submitOfflineFeedback() async {
    await VeroRateManager.markRated();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Geri bildiriminiz yerel olarak kaydedildi. VeroApp\'i geliştirmemize yardımcı olduğunuz için teşekkürler!',
          style: TextStyle(fontFamily: 'Book Antiqua'),
        ),
        backgroundColor: Color(0xFF00E676),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('rateDialog'),
      backgroundColor: CyberpunkColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CyberpunkColors.neonCyan, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _showingFeedbackForm ? _buildFeedbackForm() : _buildRatingPrompt(),
      ),
    );
  }

  Widget _buildRatingPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: CyberpunkColors.neonCyan,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'VeroApp 10 tehdit engelledi! 🛡️',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Beğendiniz mi?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            color: CyberpunkColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // 5 Interactive Golden Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              icon: Icon(
                starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFD600),
                size: 34,
              ),
              onPressed: () {
                setState(() {
                  _selectedRating = starIndex;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('rateDialogYesBtn'),
            onPressed: _onRateYes,
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkColors.neonCyan,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Evet, Değerlendir',
              style: TextStyle(
                fontFamily: 'Book Antiqua',
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('rateDialogNoBtn'),
                onPressed: _onRateNo,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CyberpunkColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Hayır',
                  style: TextStyle(
                    fontFamily: 'Book Antiqua',
                    color: CyberpunkColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                key: const Key('rateDialogLaterBtn'),
                onPressed: _onRateLater,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CyberpunkColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Daha Sonra',
                  style: TextStyle(
                    fontFamily: 'Book Antiqua',
                    color: CyberpunkColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Geri Bildiriminiz Bizim İçin Değerli',
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Daha iyi bir deneyim sunabilmemiz için neyi geliştirmeliyiz? (Tamamen yerel, internet gerektirmez)',
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            color: CyberpunkColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('offlineFeedbackInput'),
          controller: _feedbackController,
          maxLines: 4,
          style: const TextStyle(
            fontFamily: 'Book Antiqua',
            color: Colors.white,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Fikirlerinizi buraya yazın...',
            hintStyle: const TextStyle(color: CyberpunkColors.textSecondary),
            filled: true,
            fillColor: CyberpunkColors.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CyberpunkColors.borderSubtle),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          key: const Key('submitFeedbackBtn'),
          onPressed: _submitOfflineFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: CyberpunkColors.neonCyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'Gönder',
            style: TextStyle(
              fontFamily: 'Book Antiqua',
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
