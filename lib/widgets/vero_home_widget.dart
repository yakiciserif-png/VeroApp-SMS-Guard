import 'package:flutter/material.dart';

/// Available Home Screen Widget form factors.
enum VeroWidgetSize {
  horizontal4x1,
  box2x2,
}

/// Cyberpunk-themed Home Screen Widget for Android & iOS.
///
/// Displays real-time offline protection metrics:
/// - "🛡️ VeroApp SMS Guard"
/// - "Bugün: X spam engellendi"
/// - "Bu hafta: Y tehdit durduruldu"
/// - "Kalkan Durumu: %100 Aktif"
class VeroHomeWidget extends StatelessWidget {
  const VeroHomeWidget({
    super.key,
    this.size = VeroWidgetSize.horizontal4x1,
    this.blockedToday = 14,
    this.blockedThisWeek = 89,
    this.isShieldActive = true,
  });

  final VeroWidgetSize size;
  final int blockedToday;
  final int blockedThisWeek;
  final bool isShieldActive;

  @override
  Widget build(BuildContext context) {
    if (size == VeroWidgetSize.horizontal4x1) {
      return _build4x1(context);
    } else {
      return _build2x2(context);
    }
  }

  Widget _build4x1(BuildContext context) {
    return Container(
      key: const Key('veroWidget4x1'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF00E5FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🛡️ VeroApp',
                      style: TextStyle(
                        fontFamily: 'Book Antiqua',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00E676), width: 0.8),
                      ),
                      child: const Text(
                        '%100 AKTİF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Bugün: $blockedToday engellendi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bu hafta: $blockedThisWeek tehdit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2x2(BuildContext context) {
    return Container(
      key: const Key('veroWidget2x2'),
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 132,
          height: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF00E5FF),
                    size: 24,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'GÜVENLİ',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛡️ VeroApp',
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$blockedToday',
                    style: const TextStyle(
                      fontFamily: 'Book Antiqua',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const Text(
                    'Bugün Engellenen',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 11, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      'Haftalık: $blockedThisWeek tehdit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
