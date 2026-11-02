import 'package:flutter/material.dart';

void main() {
  runApp(const VeroLandingApp());
}

class VeroLandingApp extends StatelessWidget {
  const VeroLandingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeroApp SMS Guard | %100 Çevrimdışı Güvenlik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        fontFamily: 'Book Antiqua',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF12182D),
        ),
      ),
      home: const LandingHomePage(),
    );
  }
}

class LandingHomePage extends StatelessWidget {
  const LandingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020).withValues(alpha: 0.9),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF00E5FF), size: 24),
            SizedBox(width: 8),
            Text(
              'VEROAPP',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Özellikler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Karşılaştırma', style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0B1020),
              ),
              child: const Text('İndir', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E2846),
                    Color(0xFF0B1020),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      '🛡️ SIFIR İNTERNET • SIFIR BULUT • %100 YEREL YAPAY ZEKA',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Türkiye\'nin %100 Çevrimdışı\nAI Güvenlik Kalkanı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: const Text(
                      'VeroApp SMS Guard, kişisel mesaj ve arama verilerinizi asla harici sunuculara göndermeden, '
                      'doğrudan cihazınızın işlemcisinde çalışan sertifikalı yerel yapay zeka ile korur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF90A4AE),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shop, color: Color(0xFF0B1020)),
                        label: const Text('Google Play İndir'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: const Color(0xFF0B1020),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple, color: Colors.white),
                        label: const Text('App Store İndir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Özellikler: 4 Kart (SMS, Arama, Link, Aile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: const Column(
                children: [
                  Text(
                    'Dört Boyutlu Sertifikalı Koruma',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Her modül bağımsız çalışır, sıfır internet tüketir.',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 14),
                  ),
                  SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureCard(
                        icon: Icons.sms_failed_outlined,
                        color: Color(0xFF00E5FF),
                        title: '1. Gerçek Zamanlı SMS Kalkanı',
                        desc: 'Tapu devri, sahte SGK iadesi ve B001-B015 manipülasyonlarını 20ms altında cihaz içi AI ile yakalar.',
                      ),
                      _FeatureCard(
                        icon: Icons.phone_callback_outlined,
                        color: Color(0xFFFF5252),
                        title: '2. Akıllı Arama & Caller ID',
                        desc: '200.000 kayıtlı spam veri tabanı ve offline oyalama botu (Answer Bot) ile dolandırıcıları engeller.',
                      ),
                      _FeatureCard(
                        icon: Icons.link_off_outlined,
                        color: Color(0xFFFFB300),
                        title: '3. Safe-Click Link Radarı',
                        desc: 'WhatsApp ve Telegram linklerini tıklamadan önce offline tarar; zararlı .APK ve kimlik avı sitelerini durdurur.',
                      ),
                      _FeatureCard(
                        icon: Icons.family_restroom_outlined,
                        color: Color(0xFF00E676),
                        title: '4. Vero Aile & Kurumsal',
                        desc: '6 haneli tek kodla 4 kişilik ailenizi veya kurumsal ekibinizi tek tıkla güvenceye alın.',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Karşılaştırma: "Biz vs Diğerleri" Tablosu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF12182D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Biz vs Diğerleri (Neden VeroApp?)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    children: const [
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Kriter', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('VeroApp', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Diğerleri (Truecaller vb.)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Gizlilik & KVKK (Sıfır Veri Satışı)', style: TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('✅ %100 Cihaz İçi', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('❌ Rehberi Buluta Yükler', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFF5252))),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Offline / Sıfır İnternet', style: TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('✅ 0 Bayt İnternet', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('❌ İnternetsiz Çalışmaz', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFF5252))),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Türkiye & BTK Uyumlu Türkçe AI', style: TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('✅ Yerel Niyet Motoru', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('⚠️ Yetersiz / Genel', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFB300))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: const Color(0xFF080C18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Gizlilik Politikası (KVKK & GDPR)', style: TextStyle(color: Color(0xFF00E5FF))),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Kullanım Şartları', style: TextStyle(color: Color(0xFF00E5FF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İletişim: support@veroapp.com • GitHub: yakiciserif-png/VeroApp-SMS-Guard',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2025 VeroApp SMS Guard. Tüm hakları saklıdır.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12182D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
