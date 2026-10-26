import 'package:flutter/material.dart';

import '../ui/call_overlay_screen.dart';
import '../ui/cyberpunk_theme.dart';

/// Resolution presets for Play Store & App Store screenshot captures.
enum ScreenshotResolution {
  playStore('Play Store (1080 x 1920)', 1080, 1920),
  appStore('App Store (1242 x 2688)', 1242, 2688);

  const ScreenshotResolution(this.label, this.width, this.height);
  final String label;
  final double width;
  final double height;
}

/// 5 Demo Screenshot Stages showcasing VeroApp's core features.
enum ScreenshotStage {
  dashboard(
    titleTr: 'SIFIR İNTERNET, %100 YEREL KORUMA',
    subtitleTr: '12 Tehdit ve Dolandırıcılık Girişimi Engellendi',
    badgeTr: '🛡️ ON-DEVICE AI',
  ),
  smsAnalysis(
    titleTr: 'GERÇEK ZAMANLI SMS KALKANI',
    subtitleTr: 'Sahte Tapu Harcı ve B002 Oltalama Tuzağı Tespit Edildi',
    badgeTr: '🚨 KRİTİK TEHDİT',
  ),
  callGuard(
    titleTr: 'TAM EKRAN ÇAĞRI KORUMASI',
    subtitleTr: 'Yurt Dışı Sahte Çağrı Merkezi ve Bahis Tuzağı',
    badgeTr: '📞 SPAM RADARI',
  ),
  linkScanner(
    titleTr: 'WHATSAPP & TELEGRAM LİNK RADARI',
    subtitleTr: 'Zararlı .APK ve Oltalama Linkleri Tıklanmadan Engellenir',
    badgeTr: '🔗 SAFE-CLICK',
  ),
  familyPlan(
    titleTr: 'VERO AİLE & KURUMSAL GÜVENLİK',
    subtitleTr: '6 Haneli Tek Kod ile 4 Kişilik Cihaz İçi Koruma Ağı',
    badgeTr: '👨‍👩‍👧‍👦 AİLE KORUMASI',
  );

  const ScreenshotStage({
    required this.titleTr,
    required this.subtitleTr,
    required this.badgeTr,
  });

  final String titleTr;
  final String subtitleTr;
  final String badgeTr;
}

/// Dedicated Screen / Overlay Mode for generating high-resolution App Store & Play Store screenshots.
class ScreenshotModeScreen extends StatefulWidget {
  const ScreenshotModeScreen({super.key});

  @override
  State<ScreenshotModeScreen> createState() => _ScreenshotModeScreenState();
}

class _ScreenshotModeScreenState extends State<ScreenshotModeScreen> {
  ScreenshotStage _currentStage = ScreenshotStage.dashboard;
  ScreenshotResolution _resolution = ScreenshotResolution.playStore;

  void _nextStage() {
    final nextIndex = (_currentStage.index + 1) % ScreenshotStage.values.length;
    setState(() {
      _currentStage = ScreenshotStage.values[nextIndex];
    });
  }

  void _prevStage() {
    final prevIndex = (_currentStage.index - 1 + ScreenshotStage.values.length) %
        ScreenshotStage.values.length;
    setState(() {
      _currentStage = ScreenshotStage.values[prevIndex];
    });
  }

  void _toggleResolution() {
    setState(() {
      _resolution = _resolution == ScreenshotResolution.playStore
          ? ScreenshotResolution.appStore
          : ScreenshotResolution.playStore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screenshotModeScreen'),
      backgroundColor: CyberpunkColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Mağaza Ekran Görüntüsü Modu'),
        actions: [
          TextButton.icon(
            key: const Key('resolutionSwitchBtn'),
            onPressed: _toggleResolution,
            icon: const Icon(Icons.aspect_ratio, color: CyberpunkColors.neonCyan),
            label: Text(
              _resolution == ScreenshotResolution.playStore ? '1080x1920' : '1242x2688',
              style: const TextStyle(color: CyberpunkColors.neonCyan),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stage Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: CyberpunkColors.surfaceDark,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final stage in ScreenshotStage.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('screenshotStage_${stage.index + 1}'),
                        label: Text(stage.badgeTr),
                        selected: _currentStage == stage,
                        onSelected: (val) {
                          if (val) setState(() => _currentStage = stage);
                        },
                        selectedColor: CyberpunkColors.neonCyan.withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          color: _currentStage == stage
                              ? CyberpunkColors.neonCyan
                              : CyberpunkColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Main Screenshot Canvas with Neon Overlay
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: _resolution.width / _resolution.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: CyberpunkColors.backgroundDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CyberpunkColors.neonCyan.withValues(alpha: 0.7),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CyberpunkColors.neonCyan.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Neon Top Header Overlay (Marketing Banner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CyberpunkColors.surfaceDark,
                              CyberpunkColors.neonCyan.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: CyberpunkColors.neonCyan.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: CyberpunkColors.neonCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _currentStage.badgeTr,
                                style: const TextStyle(
                                  color: CyberpunkColors.neonCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentStage.titleTr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentStage.subtitleTr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CyberpunkColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Screen Stage Content
                      Expanded(
                        child: _buildStageContent(_currentStage),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  key: const Key('screenshotPrevBtn'),
                  onPressed: _prevStage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Önceki'),
                ),
                Text(
                  '${_currentStage.index + 1} / ${ScreenshotStage.values.length}',
                  style: const TextStyle(
                    color: CyberpunkColors.neonCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  key: const Key('screenshotNextBtn'),
                  onPressed: _nextStage,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Sonraki'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent(ScreenshotStage stage) {
    return switch (stage) {
      ScreenshotStage.dashboard => _buildDashboardDemo(),
      ScreenshotStage.smsAnalysis => _buildSmsAnalysisDemo(),
      ScreenshotStage.callGuard => _buildCallGuardDemo(),
      ScreenshotStage.linkScanner => _buildLinkScannerDemo(),
      ScreenshotStage.familyPlan => _buildFamilyPlanDemo(),
    };
  }

  Widget _buildDashboardDemo() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CyberHexShieldIcon(size: 64),
          ),
        ),
        Center(
          child: Text(
            'VeroApp SMS Guard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CyberpunkColors.neonCyan,
            ),
          ),
        ),
        Center(
          child: Text(
            '100% Çevrimdışı Kalkan Aktif',
            style: TextStyle(color: CyberpunkColors.safeGreen, fontSize: 12),
          ),
        ),
        SizedBox(height: 12),
        Card(
          color: CyberpunkColors.surfaceDark,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _DemoStat(label: 'Bugün', value: '12', color: CyberpunkColors.alertRed)),
                Expanded(child: _DemoStat(label: 'Bu Hafta', value: '47', color: CyberpunkColors.warningAmber)),
                Expanded(child: _DemoStat(label: 'Toplam', value: '189', color: CyberpunkColors.neonCyan)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsAnalysisDemo() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: CyberpunkColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CyberpunkColors.alertRed, width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gpp_bad, color: CyberpunkColors.alertRed, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🚨 DOLANDIRICILIK UYARISI',
                        style: TextStyle(
                          color: CyberpunkColors.alertRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Kimden: +905329990011 (B002)',
                  style: TextStyle(color: CyberpunkColors.textSecondary, fontSize: 11),
                ),
                SizedBox(height: 6),
                Text(
                  '"Sayin vatandasimiz, adiniza kayitli tapu devir harci odenmemistir. Icraya verilmemek icin tiklayiniz: https://e-deviet-tapu.cc"',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                SizedBox(height: 8),
                Text(
                  'Tehdit: Sahte Tapu Harcı + Taklit Domain + Kiril Maskelemesi (%98 Güven)',
                  style: TextStyle(color: CyberpunkColors.warningAmber, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallGuardDemo() {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 360,
        height: 640,
        child: CallOverlayScreen(
          phoneNumber: '+234 803 123 4567',
          category: 'Nijerya Finansal Dolandırıcılık Hattı',
          confidence: 0.98,
        ),
      ),
    );
  }

  Widget _buildLinkScannerDemo() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: CyberpunkColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CyberpunkColors.alertRed, width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_off, color: CyberpunkColors.alertRed, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🚨 ZARARLI LİNK ENGELLENDİ',
                        style: TextStyle(
                          color: CyberpunkColors.alertRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Uygulama: WhatsApp Web / Mobil',
                  style: TextStyle(color: CyberpunkColors.textSecondary, fontSize: 11),
                ),
                SizedBox(height: 6),
                Text(
                  'Link: http://ziraat-bankasi-odul.apk',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                SizedBox(height: 8),
                Text(
                  'DİKKAT: Bu link virüslü Android paketi (.APK) barındırıyor ve sahte banka sitesi taklit ediyor!',
                  style: TextStyle(color: CyberpunkColors.warningAmber, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyPlanDemo() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: CyberpunkColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CyberpunkColors.neonCyan, width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(Icons.family_restroom, color: CyberpunkColors.neonCyan, size: 36),
                SizedBox(height: 8),
                Text(
                  'VERO AİLE PAKETİ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aile Kodu: VERO-7842',
                  style: TextStyle(
                    color: CyberpunkColors.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '4 Aile Bireyi Korumada • Sıfır Bulut Senkronizasyonu',
                  style: TextStyle(color: CyberpunkColors.safeGreen, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoStat extends StatelessWidget {
  const _DemoStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: CyberpunkColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
