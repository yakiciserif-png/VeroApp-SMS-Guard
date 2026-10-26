import 'package:flutter/material.dart';
import '../engines/vero_enterprise_engine.dart';

/// Cyberpunk Dark Enterprise (B2B) Management Screen.
class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key});

  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen> {
  final _codeController = TextEditingController();
  final _companyController = TextEditingController();
  final _engine = VeroEnterpriseEngine.instance;
  bool _syncing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _activate() {
    final code = _codeController.text;
    final company = _companyController.text.trim();
    final ok = _engine.activateCorporateCode(
      code,
      companyName: company.isNotEmpty ? company : null,
    );

    setState(() {
      if (ok) {
        _statusMessage = '✅ Kurumsal lisans başarıyla aktifleştirildi!';
      } else {
        _statusMessage = '❌ Geçersiz kod! Kod 8 haneli olmalıdır (örn: CORP8921).';
      }
    });
  }

  void _deactivate() {
    setState(() {
      _engine.deactivate();
      _statusMessage = 'Kurumsal koruma deaktif edildi.';
    });
  }

  Future<void> _syncLocal() async {
    setState(() => _syncing = true);
    final count = await _engine.syncOfflinePeerDb();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _statusMessage = '✅ Yerel ağ üzerinden $count kural çevrimdışı senkronize edildi (0 İnternet).';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _engine.isActive;

    return Scaffold(
      key: const Key('enterpriseScreen'),
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text(
          'VEROAPP ENTERPRISE (B2B)',
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
          // 1. Enterprise Badge Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101930),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_center, color: Color(0xFF00E5FF), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ŞİRKET KORUMA MODU',
                        style: TextStyle(
                          fontFamily: 'Book Antiqua',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '19,99 TL / Çalışan / Ay • MDM/EMM Uyumlu',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101930),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00E5FF)),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),

          if (!isActive) ...[
            Card(
              color: const Color(0xFF101930),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '8 Haneli Kurumsal Kodu Girin',
                      style: TextStyle(
                        fontFamily: 'Book Antiqua',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      key: const Key('enterpriseCodeInput'),
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontFamily: 'Book Antiqua',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Örn: CORP8921',
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: Color(0xFF00E5FF)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _companyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Şirket Adı (İsteğe bağlı)',
                        hintStyle: TextStyle(color: Colors.white30),
                        prefixIcon: Icon(Icons.corporate_fare_outlined, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('activateEnterpriseBtn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: const Color(0xFF0B1020),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _activate,
                      child: const Text(
                        'KURUMSAL LİSANSI BAŞLAT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              color: const Color(0xFF101930),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF00E676)),
                        const SizedBox(width: 8),
                        Text(
                          _engine.companyName ?? 'Kurumsal Şirket',
                          style: const TextStyle(
                            fontFamily: 'Book Antiqua',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AKTİF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E676),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    Text(
                      'Lisans Kodu: ${_engine.corporateCode}',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bağlı Çalışan Sayısı: ${_engine.employeeCount}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Engellenen Kurumsal Tehdit: ${_engine.corporateThreatsBlocked}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('enterpriseSyncBtn'),
                            icon: _syncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync, size: 16),
                            label: const Text('Yerel Senkronizasyon (LAN)'),
                            onPressed: _syncing ? null : _syncLocal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          key: const Key('deactivateEnterpriseBtn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF1744),
                          ),
                          onPressed: _deactivate,
                          child: const Text('Deaktif Et'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Features Summary
          const Card(
            color: Color(0xFF101930),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              side: BorderSide(color: Colors.white10),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise Güvenlik Prensipleri',
                    style: TextStyle(
                      fontFamily: 'Book Antiqua',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• %100 Çevrimdışı: Hiçbir çalışan mesajı şirket sunucularına veya üçüncü taraflara gitmez.\n'
                    '• MDM Entegrasyonu: Intune, MobileIron, Workspace ONE konfigürasyon desteği.\n'
                    '• Bluetooth / Yerel Ağ: Tehdit veritabanı harici internet olmadan kurum içinde dağıtılır.\n'
                    '• KVKK & GDPR: Sıfır veri saklama mimarisi ile hukuki sorumluluk oluşturmaz.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
