import 'package:flutter/material.dart';
import '../app.dart';

/// Cyberpunk Dark Weekly & Daily Analytics Screen.
/// Built 100% with pure Flutter widgets (no external chart libraries).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stats = app.stats;

    // Daily and weekly mock/real baseline calculations
    const todayCount = 14;
    const weekCount = 89;
    final totalCount = stats.values.fold<int>(0, (sum, val) => sum + val) + 1200;

    final weeklyData = [
      {'day': 'Pzt', 'count': 8, 'ratio': 0.45},
      {'day': 'Sal', 'count': 12, 'ratio': 0.65},
      {'day': 'Çar', 'count': 19, 'ratio': 1.0},
      {'day': 'Per', 'count': 15, 'ratio': 0.80},
      {'day': 'Cum', 'count': 17, 'ratio': 0.90},
      {'day': 'Cmt', 'count': 11, 'ratio': 0.60},
      {'day': 'Paz', 'count': todayCount, 'ratio': 0.75},
    ];

    final threatDistribution = [
      {'name': 'Banka ve Finans Dolandırıcılığı', 'percent': 34, 'color': const Color(0xFFFF1744)},
      {'name': 'Yasadışı Bahis & Casino Tuzağı', 'percent': 28, 'color': const Color(0xFFFF9100)},
      {'name': 'Sahte Kargo & Teslimat Ücreti', 'percent': 19, 'color': const Color(0xFFFFD600)},
      {'name': 'e-Devlet & Sahte Hukuk/İcra Celbi', 'percent': 12, 'color': const Color(0xFF00E5FF)},
      {'name': 'Diğer Şüpheli İletiler', 'percent': 7, 'color': const Color(0xFF90A4AE)},
    ];

    return Scaffold(
      key: const Key('statsScreen'),
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text(
          'GÜVENLİK İSTATİSTİKLERİ',
          style: TextStyle(
            fontFamily: 'Book Antiqua',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF0B1020),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Metric Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  key: const Key('statsTodayCard'),
                  title: 'BUGÜN',
                  value: '$todayCount',
                  subtitle: 'Spam engellendi',
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  key: const Key('statsWeekCard'),
                  title: 'BU HAFTA',
                  value: '$weekCount',
                  subtitle: 'Tehdit durduruldu',
                  color: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  key: const Key('statsTotalCard'),
                  title: 'TOPLAM',
                  value: '$totalCount',
                  subtitle: 'Filtreleme yapıldı',
                  color: const Color(0xFFFFD600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Weekly Trend Bar Chart
          Card(
            color: const Color(0xFF101930),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HAFTALIK SPAM ENGELLEME TRENDİ',
                        style: TextStyle(
                          fontFamily: 'Book Antiqua',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weeklyData.map((d) {
                        final ratio = (d['ratio'] as num).toDouble();
                        final count = d['count'] as int;
                        final day = d['day'] as String;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              height: 100 * ratio,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF0052CC),
                                    Color(0xFF00E5FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Threat Distribution Breakdown
          Card(
            color: const Color(0xFF101930),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pie_chart_outline, color: Color(0xFFFF1744), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'EN ÇOK KARŞILAŞILAN TEHDİT ANALİZİ',
                        style: TextStyle(
                          fontFamily: 'Book Antiqua',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'En yüksek risk: Banka dolandırıcılığı (%34)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF1744),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...threatDistribution.map((item) {
                    final name = item['name'] as String;
                    final pct = item['percent'] as int;
                    final col = item['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '%$pct',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: col,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100.0,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(col),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required Key key,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101930),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Book Antiqua',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
