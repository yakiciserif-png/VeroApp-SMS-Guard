# VeroApp SMS Guard — Gizlilik Politikası & KVKK / GDPR Aydınlatma Metni
## Privacy Policy & On-Device Data Protection Guarantee

**Uygulama / Application:** VeroApp SMS Guard (`com.veroapp.smsguard`)  
**Sürüm / Version:** 1.0.0  
**Yürürlük Tarihi / Last Updated:** 2 Kasım 2026 / November 2, 2026  
**Sertifika / Compliance ID:** `VERO-SEC-2026-OFFLINE-CERTIFIED`  
**Gizlilik İletişim / Privacy & DPO Contact:** `privacy@veroapp.com` *(Veri Sorumlusu Temsilcisi)*

---

## 🇹🇷 Türkçe — %100 Çevrimdışı ve Sıfır Veri Toplama Taahhüdü

### 1. Temel İlke: Cihaz İçi (On-Device) Yerel İşleme
VeroApp SMS Guard, kullanıcı gizliliğini temel insan hakkı ve mutlak mühendislik önceliği olarak kabul eder. Kişisel mesajlarınız, arama kayıtlarınız, rehber bilgileriniz, konumunuz veya kimlik verileriniz **asla harici bir bulut sunucusuna, şirkete veya üçüncü tarafa aktarılmaz**.
Tüm yapay zeka sınıflandırmaları (6D Semantic Intent Engine, Naive Bayes modeli, Levenshtein URL tarayıcısı, 5M SHA-1 Bloom Filter ve ikili arama tabanlı Caller ID motoru) harici ağ bağlantısı gerektirmeksizin **doğrudan cihazınızın kendi işlemcisinde ve yerel belleğinde** çalışır.

### 2. İşlenen Veriler ve İşleme Amaçları
* **Kısa Mesaj (SMS) İçerik ve Meta Verileri:** Gelen SMS metinleri, gönderen başlığı/numarası ve zaman damgası; yalnızca cihaz içi yapay zeka motorumuz tarafından oltalama (phishing), yasadışı bahis, sahte icra/hukuk ve banka OTP hırsızlığına karşı gerçek zamanlı taranması ve güvenli/şüpheli klasörlerine ayrılması amacıyla anlık olarak işlenir.
* **Telefon Numaraları ve Arama Bilgileri:** Gelen çağrıların arayan numarası, resmi Android `CallScreeningService` API'si ve yerel 100.000+ kayıtlı spam veritabanı (`spam_numbers.bin`) üzerinden <0.1 ms sürede doğrulanarak dolandırıcıların engellenmesi amacıyla işlenir.
* **Rehber Bilgileri (`READ_CONTACTS`):** Yalnızca kayıtlı kişilerinizi arama ve mesaj ekranlarında güvenli (Yeşil Rehber Rozeti) olarak ayırt etmek amacıyla cihaz yerelinde karşılaştırılır. Rehberiniz asla kopyalanmaz veya dışarı aktarılmaz.
* **Hata ve Tehdit Kayıtları:** İsteğe bağlı olarak kullanıcı tarafından engellenen tehditler veya uygulama içi çökmeler, yalnızca yerel SQLite / SharedPreferences alanında tutulur; hiçbir telemetri veya analitik sunucusuna gönderilmez.

### 3. KESİNLİKLE Toplanmayan ve İşlenmeyen Veriler
* Sesli görüşme kayıtları veya mikrofon uplink ses verileri KESİNLİKLE kaydedilmez veya dinlenmez.
* Mesaj içerikleri harici sunuculara veya veri merkezlerine KESİNLİKLE yüklenmez.
* Finansal şifreler, kredi kartı numaraları veya banka doğrulama kodları hiçbir şekilde saklanmaz veya paylaşılmaz.
* Konum (GPS), reklam kimliği (AAID/IDFA) veya cihaz parmak izi verileri KESİNLİKLE toplanmaz.

### 4. Veri Saklama ve Saklama Süresi (Retention Policy)
* Gerçek zamanlı analiz verileri: Mesaj veya çağrı geldiği anda RAM üzerinde geçici olarak analiz edilir (<20 ms) ve analiz tamamlandığında bellekten temizlenir.
* Yerel geçmiş kayıtları: Kullanıcı tarafından açıkça silinene kadar veya Ayarlar'daki döngüsel temizlik kotası (varsayılan son 100 işlem) kapsamında yalnızca cihaz hafızasında saklanır.

### 5. Kullanıcı Hakları ve Veri Silme Talebi (Data Deletion & Rights)
Kullanıcılar diledikleri zaman:
1. Uygulama içi **Ayarlar > Geçmişi Temizle** veya **Verileri Sıfırla** butonuna dokunarak cihazda tutulan tüm filtreleme geçmişini anında kalıcı olarak silebilirler.
2. Uygulama verilerini Android/iOS Sistem Ayarları üzerinden temizleyebilir veya uygulamayı kaldırarak cihazdaki tüm verileri sıfırlayabilirler.
3. Bulut sunucularımızda hiçbir kullanıcı verisi saklanmadığı için, harici bir sunucudan veri sildirme prosedürüne gerek bulunmamaktadır (Sıfır Bulut Verisi İlkesi).

### 6. Çocukların Gizliliği (COPPA Uyumluluğu)
VeroApp SMS Guard, 13 yaşın altındaki çocuklara yönelik değildir ve çocuklara ait hiçbir kişisel veriyi bilerek veya isteyerek toplamaz.

### 7. Hukuki Dayanak ve KVKK (6698) Uyumluluk Beyanı
Verileriniz, 6698 sayılı Kişisel Verilerin Korunması Kanunu'nun 5/1 (Açık Rıza) ve 5/2-f (İlgili kişinin temel hak ve özgürlüklerine zarar vermemek kaydıyla, veri sorumlusunun meşru menfaatleri için veri işlenmesinin zorunlu olması — siber dolandırıcılığa karşı meşru müdafaa ve koruma) maddeleri uyarınca işlenmektedir. KVKK Madde 11 kapsamındaki haklarınız için `privacy@veroapp.com` adresi üzerinden başvurabilirsiniz.

---

## 🌐 English — 100% On-Device & Zero Data Collection Guarantee

### 1. Core Principle: Absolute On-Device Processing
VeroApp SMS Guard is engineered on a strict **zero-telemetry, offline-first** paradigm. Your text messages, caller identifiers, contact lists, and personal data **never leave your physical handset**.
All artificial intelligence classifiers (6D Semantic Intent Engine, on-device Naive Bayes, Levenshtein URL scanner, 5M SHA-1 Bloom Filter, and binary caller lookup) execute strictly within your smartphone's local application sandbox.

### 2. Data Categories & Purpose of Processing
* **SMS Messages & Metadata:** Incoming SMS messages and sender IDs are evaluated transiently in memory to identify smishing, extortion threats, OTP theft, and illegal gambling spam.
* **Phone Numbers & Call Screening:** Incoming telephone numbers are checked against offline pre-packaged databases (`spam_numbers.bin`) via Android's native `CallScreeningService` API in <0.1 ms to block nuisance calls.
* **Contacts (`READ_CONTACTS`):** Evaluated strictly on-device to whitelist known acquaintances with a green badge. Never exported or backed up remotely.
* **Crash & Audit Logs:** Stored locally on the filesystem with zero automatic cloud upload.

### 3. What We NEVER Collect
* We DO NOT record audio, voice calls, or microphone streams.
* We DO NOT upload, aggregate, or sell your SMS messages or contacts.
* We DO NOT store credit card numbers, passwords, or government credentials.
* We DO NOT track GPS location, Advertising IDs (AAID/IDFA), or analytics metrics.

### 4. Third-Party Sharing & Transfers
**Zero Third-Party Sharing:** VeroApp SMS Guard contains no advertising SDKs, no behavioral trackers, and no cloud analytics engines. No cross-border data transfer takes place.

### 5. User Rights & Data Deletion
Users retain 100% control over their device data:
* **Immediate Deletion:** Clear local scan logs at any time via **Settings > Clear History**.
* **Total Erasure:** Uninstalling the app permanently purges all local databases, Bloom filters, and preference keys.
* Because no data is transmitted to external servers, there is no remote data footprint.

### 6. Children's Privacy (COPPA Compliance)
The app is not directed to children under the age of 13 and does not knowingly collect personal information from children.

### 7. GDPR Disclosures (Articles 13 & 14)
* **Data Controller:** VeroApp Security Engineering Team (`privacy@veroapp.com`).
* **Legal Basis for Processing (GDPR Art. 6):** User explicit consent (Art. 6(1)(a)) and legitimate interest in on-device defense against financial cybercrime (Art. 6(1)(f)).
* **Data Subject Rights:** Under GDPR Chapter III, you have the right to access, rectify, and erase your data, and to lodge a complaint with your local data protection supervisory authority.

### 8. Contact Information
For formal privacy audits, compliance verification, or inquiries:  
**Data Protection Representative:** `privacy@veroapp.com`  
**Application ID:** `com.veroapp.smsguard`
