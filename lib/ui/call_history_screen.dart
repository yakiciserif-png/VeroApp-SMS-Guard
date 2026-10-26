import 'package:flutter/material.dart';

import '../engines/vero_caller_id_engine.dart';
import '../engines/vero_caller_name_engine.dart';
import '../engines/vero_community_shield.dart';
import 'call_overlay_screen.dart';
import 'cyberpunk_theme.dart';
import 'post_call_report.dart';

enum CallLogType { incoming, outgoing, missed }

enum CallTrustStatus { safe, spam, suspicious }

class CallLogItem {
  const CallLogItem({
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.type,
    this.customName,
  });

  final String phoneNumber;
  final DateTime timestamp;
  final int durationSeconds;
  final CallLogType type;
  final String? customName;
}

/// [ADIM 3] ARAMA GEÇMİŞİ SPAM ETİKETLEME (Truecaller benzeri).
///
/// Labels each call entry with:
/// ✅ Güvenli (yeşil kalkan)
/// 🚨 Spam (kırmızı çarpı)
/// ⚠️ Şüpheli (sarı ünlem)
class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallHistoryScreen()),
    );
  }

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  String _filter = 'all'; // all, spam, safe

  // Pre-seeded device call logs for offline inspection
  final List<CallLogItem> _logs = [
    CallLogItem(
      phoneNumber: '0850 480 99 88',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      durationSeconds: 0,
      type: CallLogType.missed,
    ),
    CallLogItem(
      phoneNumber: '+63 917 000 1122',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      durationSeconds: 0,
      type: CallLogType.missed,
    ),
    CallLogItem(
      phoneNumber: '905321112233',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      durationSeconds: 142,
      type: CallLogType.incoming,
    ),
    CallLogItem(
      phoneNumber: '0850 532 00 10',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      durationSeconds: 12,
      type: CallLogType.incoming,
    ),
    CallLogItem(
      phoneNumber: '4440000',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      durationSeconds: 310,
      type: CallLogType.outgoing,
    ),
    CallLogItem(
      phoneNumber: '0212 901 00 15',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      durationSeconds: 4,
      type: CallLogType.incoming,
    ),
    CallLogItem(
      phoneNumber: '+90 555 987 65 43',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      durationSeconds: 45,
      type: CallLogType.incoming,
    ),
  ];

  CallTrustStatus _evaluateStatus(String number) {
    final callerId = VeroCallerIdEngine.lookup(number);
    if (callerId.isSpam) {
      if (callerId.category == SpamCallerCategory.unknown) {
        return CallTrustStatus.suspicious;
      }
      return CallTrustStatus.spam;
    }
    return CallTrustStatus.safe;
  }

  void _showDetailSheet(CallLogItem item) {
    final callerInfo = VeroCallerNameEngine.identify(item.phoneNumber);
    final status = _evaluateStatus(item.phoneNumber);
    final isReported = VeroCommunityShield.lookupReported(item.phoneNumber) != null;
    final reportCount = status == CallTrustStatus.spam ? (isReported ? 124 : 87) : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: status == CallTrustStatus.spam
                        ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                        : (status == CallTrustStatus.suspicious
                            ? const Color(0xFFFFD600).withValues(alpha: 0.2)
                            : const Color(0xFF00FF88).withValues(alpha: 0.2)),
                    child: Icon(
                      status == CallTrustStatus.spam
                          ? Icons.close_rounded
                          : (status == CallTrustStatus.suspicious
                              ? Icons.priority_high_rounded
                              : Icons.verified_user_rounded),
                      color: status == CallTrustStatus.spam
                          ? const Color(0xFFFF1744)
                          : (status == CallTrustStatus.suspicious
                              ? const Color(0xFFFFD600)
                              : const Color(0xFF00FF88)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callerInfo.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.phoneNumber,
                          style: const TextStyle(
                            color: CyberpunkColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CyberpunkColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CyberpunkColors.borderSubtle),
                ),
                child: Text(
                  status == CallTrustStatus.spam
                      ? 'Bu numara $reportCount kez spam bildirildi.'
                      : (status == CallTrustStatus.suspicious
                          ? 'Şüpheli otomatik arama veya doğrulanmamış hat.'
                          : 'Doğrulanmış veya güvenli numara.'),
                  style: TextStyle(
                    color: status == CallTrustStatus.spam
                        ? const Color(0xFFFF1744)
                        : CyberpunkColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('btnTestCallOverlay'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        CallOverlayScreen.show(
                          context,
                          phoneNumber: item.phoneNumber,
                        );
                      },
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('Kırmızı Ekran'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('btnTestPostCallReport'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        PostCallReportDialog.show(
                          context,
                          phoneNumber: item.phoneNumber,
                        );
                      },
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Rapor Kartı'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _logs.where((item) {
      if (_filter == 'all') return true;
      final status = _evaluateStatus(item.phoneNumber);
      if (_filter == 'spam') {
        return status == CallTrustStatus.spam ||
            status == CallTrustStatus.suspicious;
      }
      return status == CallTrustStatus.safe;
    }).toList();

    return Scaffold(
      key: const Key('callHistoryScreen'),
      backgroundColor: CyberpunkColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Arama Geçmişi & Spam Tespiti'),
        backgroundColor: CyberpunkColors.bgSecondary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('chipFilterAll'),
                  label: const Text('Tümü'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: const Key('chipFilterSpam'),
                  label: const Text('🚨 Spam / Şüpheli'),
                  selected: _filter == 'spam',
                  onSelected: (_) => setState(() => _filter = 'spam'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: const Key('chipFilterSafe'),
                  label: const Text('✅ Güvenli'),
                  selected: _filter == 'safe',
                  onSelected: (_) => setState(() => _filter = 'safe'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final callerInfo =
                    VeroCallerNameEngine.identify(item.phoneNumber);
                final status = _evaluateStatus(item.phoneNumber);

                final isSpam = status == CallTrustStatus.spam;
                final isSuspicious = status == CallTrustStatus.suspicious;

                final badgeIcon = isSpam
                    ? Icons.close_rounded
                    : (isSuspicious
                        ? Icons.priority_high_rounded
                        : Icons.verified_user_rounded);

                final badgeColor = isSpam
                    ? const Color(0xFFFF1744)
                    : (isSuspicious
                        ? const Color(0xFFFFD600)
                        : const Color(0xFF00FF88));

                final badgeText = isSpam
                    ? '🚨 Spam'
                    : (isSuspicious ? '⚠️ Şüpheli' : '✅ Güvenli');

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSpam
                        ? const Color(0xFFFF1744).withValues(alpha: 0.12)
                        : CyberpunkColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSpam
                          ? const Color(0xFFFF1744).withValues(alpha: 0.5)
                          : CyberpunkColors.borderSubtle,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      onTap: () => _showDetailSheet(item),
                      leading: CircleAvatar(
                        backgroundColor: badgeColor.withValues(alpha: 0.18),
                        child: Icon(badgeIcon, color: badgeColor, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              callerInfo.displayName,
                              style: TextStyle(
                                color: callerInfo.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: badgeColor),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${item.phoneNumber} • ${item.durationSeconds > 0 ? '${item.durationSeconds} sn' : 'Cevapsız'}',
                        style: const TextStyle(
                          color: CyberpunkColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: CyberpunkColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
