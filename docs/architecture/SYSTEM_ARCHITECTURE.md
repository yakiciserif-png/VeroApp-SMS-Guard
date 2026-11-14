# VeroApp SMS Guard — Sistem ve Güvenlik Mimarisi (`v1.0.0`)

## 1. Mimari Vizyon: %100 Offline-First & Sıfır Gecikme
VeroApp SMS Guard (`veroapp_sms_guard`), gelen SMS mesajlarını, bildirimleri, oltalama bağlantılarını ve telefon aramalarını **harici bir bulut sunucusuna tek bir bayt veri göndermeden** cihaz içinde (< 20 ms SMS sınıflandırma, < 0.1 ms ikili arama Caller ID) filtreleyen çok katmanlı bir mobil güvenlik sistemidir.

```
Gelen SMS / Çağrı / Bildirim
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│ 1. Native Platform Kancaları (Kotlin & Swift)            │
│  • Android: TrustSmsReceiver, TrustSmsDeliverReceiver,   │
│    VeroCallScreeningService (RoleManager),               │
│    TrustNotificationListener                             │
│  • iOS: ILMessageFilterExtension (IdentityLookup),       │
│    App Group (group.com.veroapp.smsguard.filter)         │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│ 2. Anti-Evasion Tokenizer & Homoglyph Normalizer         │
│  • Kiril/Yunan homoglyph temizliği (а -> a, о -> o)      │
│  • Boşluk/sembol gizleme çözümü (B.a.h.i.s -> bahis)     │
│  • BTK B-Kodu (B001-B015) ve MERSİS ayrıştırıcı          │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│ 3. 6 Aşamalı Akıllı Sınıflandırma Hattı (SmartClassifier)│
│  • Aşama 1: Kullanıcı Kuralları (Regex & Anahtar Kelime) │
│  • Aşama 2: Çok Dilli OTP & Bankacılık Kodu Çıkarıcı     │
│  • Aşama 3: Tehdit İstihbarat Kalkanları (Bahis, İcra)   │
│  • Aşama 4: 6D Semantic Intent Engine & Naive Bayes AI   │
│  • Aşama 5: Levenshtein Typosquatting & URL Tarayıcı     │
│  • Aşama 6: 100K+ İkili Spam DB & 5M SHA-1 Bloom Filter  │
└──────────────────────────────────────────────────────────┘
```

## 2. Çekirdek Motorlar (`lib/engines/` & `lib/core/`)
* **`SmartClassifier` & `SemanticIntentEngine`:** 6 boyutlu anlamsal niyet vektörü (*Urgency/Fear*, *Financial Trap*, *Reward/Betting*, *Action/Link*, *Corporate/OTP*, *Personal Chat*) ve karakter 3-gram/4-gram analizi.
* **`VeroCallerIdEngine` & `VeroCallGuardEngine`:** `assets/spam_db/spam_numbers.bin` (63.005 doğrulanmış kayıt) ve `turkey_spam.bin` (25.002 yerel kayıt) üzerinde `O(log N)` ikili arama (< 0.1 ms) + 8 uluslararası ve `0850` regex kuralı.
* **`VeroLinkScanner` & `SafeClickEngine`:** `assets/spam_db/phishing_domains.bin` (38.300+ oltalama alanı) + Levenshtein mesafesi ile banka/e-Devlet taklit (typosquatting) ve `.apk` indirme tespiti.
* **`VeroBreachRadarEngine` & `VeroBloomFilter`:** `assets/breach_db/bloom_filter.bin` (6.25 MB, 5.000.000 SHA-1 özet kapasiteli) çevrimdışı veri sızıntısı radarı.
* **`VeroLicenseVerifier`:** Ed25519 açık anahtar kriptografisi ile %100 çevrimdışı Aile ve Pro lisans doğrulama.
