import 'dart:async';
import 'package:flutter/material.dart';

import '../app.dart';
import '../engines/vero_community_shield.dart';
import 'cyberpunk_theme.dart';

/// [ADIM 4] ARAMA SONRASI RAPOR KARTI (Hiya benzeri).
///
/// Automatically shown after a call finishes to solicit user feedback offline:
/// "Bu arama spam miydi?"
/// - "Evet Spam" -> Persisted into local Community Shield
/// - "Hayır Güvenli" -> Added to local whitelist
/// - Automatically dismisses after 10 seconds
class PostCallReportDialog extends StatefulWidget {
  const PostCallReportDialog({
    super.key,
    required this.phoneNumber,
    this.autoDismissDuration = const Duration(seconds: 10),
    this.onFeedbackGiven,
  });

  final String phoneNumber;
  final Duration autoDismissDuration;
  final ValueChanged<bool>? onFeedbackGiven;

  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
    Duration autoDismissDuration = const Duration(seconds: 10),
    ValueChanged<bool>? onFeedbackGiven,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PostCallReportDialog(
        phoneNumber: phoneNumber,
        autoDismissDuration: autoDismissDuration,
        onFeedbackGiven: onFeedbackGiven,
      ),
    );
  }

  @override
  State<PostCallReportDialog> createState() => _PostCallReportDialogState();
}

class _PostCallReportDialogState extends State<PostCallReportDialog> {
  Timer? _dismissTimer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoDismissDuration.inSeconds;
    _dismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        Navigator.of(context).maybePop();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleFeedback(bool isSpam) async {
    _dismissTimer?.cancel();
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (isSpam) {
      await app.reportSpamPhoneNumber(
        widget.phoneNumber,
        category: 'SPAM_SCAM',
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              VeroCommunityShield.feedbackMessage,
              style: TextStyle(fontFamily: 'Book Antiqua', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Color(0xFF00E676),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      await app.addWhitelistItem(
        VeroCommunityShield.normalizeDigits(widget.phoneNumber),
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${widget.phoneNumber} yerel beyaz listeye eklendi.',
            ),
          ),
        );
      }
    }

    widget.onFeedbackGiven?.call(isSpam);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('postCallReportDialog'),
      backgroundColor: CyberpunkColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: CyberpunkColors.neonCyan, width: 1.2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_callback_rounded,
              color: CyberpunkColors.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Arama Değerlendirmesi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${_secondsRemaining}s',
            style: const TextStyle(
              color: CyberpunkColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son aranan numara: ${widget.phoneNumber}',
            style: const TextStyle(
              color: CyberpunkColors.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bu arama spam miydi?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Geri bildiriminiz yalnızca cihazınızdaki yerel AI modelini ve Topluluk Kalkanını eğitir (100% Çevrimdışı).',
            style: TextStyle(
              color: CyberpunkColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('postCallNoSafeBtn'),
                onPressed: () => _handleFeedback(false),
                icon: const Icon(Icons.shield_outlined,
                    color: Color(0xFF00FF88), size: 16),
                label: const Text(
                  'Hayır Güvenli',
                  style: TextStyle(color: Color(0xFF00FF88)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00FF88)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('postCallYesSpamBtn'),
                  onPressed: () => _handleFeedback(true),
                  icon: const Icon(Icons.gpp_bad_rounded, size: 18),
                  label: const Text(
                    '🚨 Bu Numarayı Bildir',
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
