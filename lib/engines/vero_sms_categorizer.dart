import 'package:flutter/material.dart';

import '../core/classifier/classification.dart';
import '../core/classifier/otp_detector.dart';

enum VeroSmsCategory {
  bankFinance,      // 🏦 BANKA & FİNANS (Mavi)
  cargoLogistics,   // 📦 KARGO & LOJİSTİK (Turuncu)
  govOfficial,      // 🏛️ DEVLET & RESMİ (Gri)
  personalChat,     // 💬 KİŞİSEL & SOHBET (Yeşil)
  promoCampaign,    // 📢 PROMOSYON & KAMPANYA (Sarı)
  spamTrap,         // 🚨 SPAM & TUZAK (Kırmızı)
}

class VeroSmsCategoryInfo {
  const VeroSmsCategoryInfo({
    required this.category,
    required this.titleTr,
    required this.titleEn,
    required this.color,
    required this.icon,
  });

  final VeroSmsCategory category;
  final String titleTr;
  final String titleEn;
  final Color color;
  final IconData icon;
}

/// [ADIM 6] GELİŞMİŞ SMS KATEGORİLEME (SMS Organizer benzeri, 6 Kategori).
class VeroSmsCategorizer {
  VeroSmsCategorizer._();
  static final VeroSmsCategorizer instance = VeroSmsCategorizer._();
  factory VeroSmsCategorizer() => instance;

  static const Map<VeroSmsCategory, VeroSmsCategoryInfo> meta = {
    VeroSmsCategory.bankFinance: VeroSmsCategoryInfo(
      category: VeroSmsCategory.bankFinance,
      titleTr: '🏦 Banka & Finans',
      titleEn: '🏦 Banking & Finance',
      color: Color(0xFF00E5FF),
      icon: Icons.account_balance_outlined,
    ),
    VeroSmsCategory.cargoLogistics: VeroSmsCategoryInfo(
      category: VeroSmsCategory.cargoLogistics,
      titleTr: '📦 Kargo & Lojistik',
      titleEn: '📦 Delivery & Logistics',
      color: Color(0xFFFF9100),
      icon: Icons.local_shipping_outlined,
    ),
    VeroSmsCategory.govOfficial: VeroSmsCategoryInfo(
      category: VeroSmsCategory.govOfficial,
      titleTr: '🏛️ Devlet & Resmi',
      titleEn: '🏛️ Government & Official',
      color: Color(0xFF90A4AE),
      icon: Icons.account_balance_rounded,
    ),
    VeroSmsCategory.personalChat: VeroSmsCategoryInfo(
      category: VeroSmsCategory.personalChat,
      titleTr: '💬 Kişisel & Sohbet',
      titleEn: '💬 Personal & Chat',
      color: Color(0xFF00E676),
      icon: Icons.chat_bubble_outline,
    ),
    VeroSmsCategory.promoCampaign: VeroSmsCategoryInfo(
      category: VeroSmsCategory.promoCampaign,
      titleTr: '📢 Promosyon & Kampanya',
      titleEn: '📢 Promo & Campaign',
      color: Color(0xFFFFD600),
      icon: Icons.campaign_outlined,
    ),
    VeroSmsCategory.spamTrap: VeroSmsCategoryInfo(
      category: VeroSmsCategory.spamTrap,
      titleTr: '🚨 Spam & Tuzak',
      titleEn: '🚨 Spam & Phishing Trap',
      color: Color(0xFFFF1744),
      icon: Icons.gpp_bad_outlined,
    ),
  };

  static final List<String> _bankKeywords = [
    'bank', 'bakiye', 'hesap', 'kart', 'ekstre', 'iban', 'kredi', 'pos',
    'havale', 'eft', 'fast', 'dekont', 'mevduat', 'faiz', 'finans',
    'ziraat', 'garanti', 'isbank', 'akbank', 'yapikredi', 'vakifbank',
    'halkbank', 'qnb', 'teb', 'ing', 'papara', 'tosla', 'ininal',
  ];

  static final List<String> _cargoKeywords = [
    'kargo', 'kurye', 'takip no', 'teslimat', 'gönderi', 'dağıtıma',
    'şubede', 'paket', 'desici', 'varış', 'yurtiçi', 'aras', 'mng', 'ptt',
    'surat', 'scotty', 'hepsijet', 'trendyol express', 'kolay gelsin',
  ];

  static final List<String> _govKeywords = [
    'edevlet', 'e-devlet', 'sgk', 'gib', 'vergi', 'tapu', 'mhrs', 'hastane',
    'randevu', 'e-nabiz', 'icisleri', 'adalet', 'mahkeme', 'icra', 'uyap',
    'bakanlik', 'belediye', 'iski', 'igdas', 'tedas', 'nufus', 'pasaport',
  ];

  static final List<String> _promoKeywords = [
    'kampanya', 'indirim', 'fırsat', 'kaçırma', 'kupon', 'sepette', 'özel',
    'fiyat', 'satış', 'hediye', 'çekiliş', 'kazanın', 'ücretsiz', 'kampanyası',
    'promo', 'discount', 'sale', 'offer', 'deal', 'voucher',
  ];

  /// Categorizes an incoming SMS into one of the 6 official Vero categories.
  static VeroSmsCategory categorize(
    dynamic textOrPositional, {
    String? text,
    String? sender,
    MessageCategory? classifierCategory,
  }) {
    final String actualText = (textOrPositional is String) ? textOrPositional : (text ?? '');
    final lower = actualText.toLowerCase();
    final lowerSender = (sender ?? '').toLowerCase();

    // 1. If flagged as spam by classifier or contains illegal betting/phishing traps
    if (classifierCategory == MessageCategory.spam ||
        lower.contains('deneme bonusu') ||
        lower.contains('freespin') ||
        lower.contains('bahis') ||
        lower.contains('kazandınız tıkla') ||
        lower.contains('kartınız bloke') ||
        lower.contains('bloke') ||
        lower.contains('şüpheli işlem') ||
        lower.contains('donduruldu') ||
        lower.contains('askıya')) {
      return VeroSmsCategory.spamTrap;
    }

    // 2. OTP or Banking/Finance
    if (OtpDetector.analyze(actualText).extractedCode != null) {
      return VeroSmsCategory.bankFinance;
    }
    for (final kw in _bankKeywords) {
      if (lower.contains(kw) || lowerSender.contains(kw)) {
        return VeroSmsCategory.bankFinance;
      }
    }

    // 3. Cargo & Logistics
    for (final kw in _cargoKeywords) {
      if (lower.contains(kw) || lowerSender.contains(kw)) {
        return VeroSmsCategory.cargoLogistics;
      }
    }

    // 4. Government & Official
    for (final kw in _govKeywords) {
      if (lower.contains(kw) || lowerSender.contains(kw)) {
        return VeroSmsCategory.govOfficial;
      }
    }

    // 5. Promotional & Marketing
    for (final kw in _promoKeywords) {
      if (lower.contains(kw) || lowerSender.contains(kw)) {
        return VeroSmsCategory.promoCampaign;
      }
    }

    // 6. Personal & Chat (default for ordinary personal messages)
    return VeroSmsCategory.personalChat;
  }
}
