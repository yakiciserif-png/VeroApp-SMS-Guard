# VeroApp SMS Guard — Gizlilik Politikası & KVKK / GDPR Aydınlatma Metni
## Privacy Policy & On-Device Data Protection Guarantee

**Uygulama / Application:** VeroApp SMS Guard (`com.veroapp.smsguard`)  
**Sürüm / Version:** 1.0.0  
**Sertifika / Compliance:** `VERO-SEC-2025-OFFLINE-CERTIFIED`  
**İletişim / Contact:** `support@veroapp.com`

---

## 🇹🇷 Türkçe — %100 Çevrimdışı ve Sıfır Veri Toplama Taahhüdü

### 1. Temel İlke: Cihaz İçi (On-Device) İşleme & Sıfır Veri Sızıntısı
VeroApp SMS Guard, kişisel mesajlarınızı, arama kayıtlarınızı, rehber bilgilerinizi veya kimlik verilerinizi **asla harici bir bulut sunucusuna aktarmaz**. Tüm yapay zeka sınıflandırmaları (6D Semantic Intent Engine, Naive Bayes modeli, Levenshtein URL tarayıcısı, 5M SHA-1 Bloom Filter ve ikili arama tabanlı Caller ID motoru) doğrudan cihazınızın kendi donanımında (%100 yerel olarak) çalışır.

### 2. Kullanılan Sistem İzinleri ve Hassas İzin Gerekçeleri (Google Play & Apple App Store)
* **SMS İzinleri (`RECEIVE_SMS`, `READ_SMS`, `ROLE_SMS` / iOS `ILMessageFilterExtension`):** Gelen kısa mesajları cihaz içinde gerçek zamanlı olarak oltalama (phishing), yasadışı bahis, sahte icra/hukuk ve OTP hırsızlığına karşı denetlemek ve Akıllı Gelen Kutusu (Finans, Kargo, Kişisel, Spam) klasörlerine ayırmak için kullanılır.
* **Arama Tarama İzni (`android.telecom.CallScreeningService`, `ROLE_CALL_SCREENING`, `READ_PHONE_STATE`):** Gelen çağrılarda arayan numarayı yerel 100.000+ imzalı spam veritabanı ve ulusal/uluslararası dolandırıcılık kuralları (`0850`, `+234`, `+63` vb.) ile <0.1 ms sürede karşılaştırmak için kullanılır.
* **Rehber İzni (`READ_CONTACTS`):** Yalnızca kayıtlı kişilerinizi arama ve mesaj ekranlarında güvenli (Yeşil Rehber Rozeti) olarak ayırt etmek amacıyla cihaz hafızasında eşleştirilir; dışarıya gönderilmez.
* **Erişilebilirlik Servisi (`AccessibilityService` — İsteğe Bağlı):** Mesajlaşma uygulamalarındaki şüpheli bağlantıları (`.apk` indirmeleri, sahte banka/e-Devlet oltalama linkleri) tıklanmadan önce yerel olarak taramak için kullanılır.

### 3. KVKK (6698) ve GDPR Uyumluluğu
Uygulamamız 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) Madde 4, 5 ve 6 ile Avrupa Birliği Genel Veri Koruma Tüzüğü (GDPR) Madde 6 ve 9 hükümlerine tam uyumludur. Üçüncü taraf veri işleyenlere veya yurt dışı sunuculara kişisel veri aktarımı yapılmaz.

---

## 🌐 English — 100% On-Device & Zero Data Collection Guarantee

### 1. Core Principle: On-Device Processing
VeroApp SMS Guard processes all SMS messages, call screening events, URL inspections, and breach checks strictly on your mobile device. None of your SMS texts, call logs, contacts, or personal identifiers are ever uploaded, logged, or sold to external servers.

### 2. System Permissions & Strict Single-Purpose Justification
* **SMS Permissions (`RECEIVE_SMS`, `READ_SMS`, `ROLE_SMS` / iOS `IdentityLookup`):** Used exclusively to evaluate incoming messages on-device using our local Semantic Intent AI and regex/heuristic filter engine.
* **Call Screening (`CallScreeningService`, `ROLE_CALL_SCREENING`, `READ_PHONE_STATE`):** Used exclusively to identify and block robocalls, telesales, and scam numbers via on-device binary search (`spam_numbers.bin`).
* **Contacts (`READ_CONTACTS`):** Used strictly locally to whitelist known contacts and display the verified green contact badge.
* **Accessibility Service (Optional):** Used strictly locally to warn users before opening malicious `.apk` or typosquatted phishing URLs.

### 3. Contact
For privacy inquiries, compliance verification, or data protection requests: `support@veroapp.com`
