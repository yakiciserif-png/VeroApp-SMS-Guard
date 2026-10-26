import 'package:flutter/material.dart';

import '../engines/vero_caller_name_engine.dart';
import 'cyberpunk_theme.dart';

/// [ADIM 2] SPAM ARAMA KIRMIZI EKRAN UYARISI (Truecaller / Siber Güvenlik benzeri).
///
/// Full-screen red alert overlay displayed when an incoming call is flagged as spam.
class CallOverlayScreen extends StatefulWidget {
  const CallOverlayScreen({
    super.key,
    required this.phoneNumber,
    this.category = 'SPAM_SCAM',
    this.confidence = 0.98,
    this.onReject,
    this.onAccept,
    this.onAnswerBot,
  });

  final String phoneNumber;
  final String category;
  final double confidence;
  final VoidCallback? onReject;
  final VoidCallback? onAccept;
  final VoidCallback? onAnswerBot;

  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
    String category = 'SPAM_SCAM',
    double confidence = 0.98,
    VoidCallback? onAnswerBot,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => CallOverlayScreen(
          phoneNumber: phoneNumber,
          category: category,
          confidence: confidence,
          onAnswerBot: onAnswerBot,
        ),
      ),
    );
  }

  @override
  State<CallOverlayScreen> createState() => _CallOverlayScreenState();
}

class _CallOverlayScreenState extends State<CallOverlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerInfo = VeroCallerNameEngine.identify(widget.phoneNumber);

    return Scaffold(
      key: const Key('callOverlayScreen'),
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2 * _pulseAnimation.value,
                colors: const [
                  Color(0xFF6A0D1F),
                  Color(0xFF26050C),
                  CyberpunkColors.bgPrimary,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header: "🚨 DOLANDIRICILIK UYARISI"
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFFF1744),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF1744), size: 22),
                          SizedBox(width: 8),
                          Text(
                            '🚨 DOLANDIRICILIK UYARISI',
                            style: TextStyle(
                              color: Color(0xFFFF1744),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VERO GÜVENLİK SİSTEMİ TARAFINDAN ENGELLENDİ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CyberpunkColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Center Info: Phone + Category + Confidence + Caller Name ID
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF1744).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFFFF1744),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_disabled_rounded,
                        color: Color(0xFFFF1744),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.phoneNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CyberpunkColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CyberpunkColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        callerInfo.displayName,
                        style: TextStyle(
                          color: callerInfo.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kategori: ${widget.category}',
                      style: const TextStyle(
                        color: CyberpunkColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Güven Skoru: %${(widget.confidence * 100).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: CyberpunkColors.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Bottom Buttons: "Reddet" (large red), "Oyala" (Answer Bot), "Yine de Aç" (small grey)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        key: const Key('callOverlayAnswerBotBtn'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onAnswerBot != null) {
                            widget.onAnswerBot!();
                          }
                        },
                        icon: const Icon(Icons.smart_toy_outlined,
                            color: CyberpunkColors.neonCyan),
                        label: const Text(
                          '🤖 Bot ile Oyala (Answer Bot)',
                          style: TextStyle(
                            color: CyberpunkColors.neonCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: CyberpunkColors.neonCyan,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        key: const Key('callOverlayRejectBtn'),
                        onPressed: () {
                          if (widget.onReject != null) {
                            widget.onReject!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        label: const Text(
                          'Reddet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1744),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor:
                              const Color(0xFFFF1744).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      key: const Key('callOverlayAcceptBtn'),
                      onPressed: () {
                        if (widget.onAccept != null) {
                          widget.onAccept!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        'Yine de Aç',
                        style: TextStyle(
                          color: CyberpunkColors.textSecondary,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
