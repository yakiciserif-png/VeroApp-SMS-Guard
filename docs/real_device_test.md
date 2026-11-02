# VeroApp SMS Guard — Gerçek Cihaz Manuel Test Kılavuzu (15 Adım)

Bu belge, uygulamanın fiziksel bir Android veya iOS cihazında uçtan uca doğrulanması için hazırlanmış 15 adımlık kontrol listesidir.

---

### [TEST 1] Varsayılan SMS Uygulaması Rolü (Android)
- **Hedef:** VeroApp'in sistem varsayılan SMS yöneticisi olarak atanabilmesi.
- **Adım:** Ayarlar > Varsayılan SMS Uygulaması veya uygulama açılışındaki butona tıklayın. Sistem iletişim kutusundan "VeroApp SMS Guard"ı seçin.
- **Beklenen Sonuç:** Uygulama varsayılan SMS yöneticisi olur; sistem gelen SMS'leri doğrudan `TrustSmsDeliverReceiver` üzerinden karşılar.

---

### [TEST 2] CallScreeningService Arama Engelleme Rolü (Android 10+)
- **Hedef:** İstenmeyen aramaları çalmadan önce OS düzeyinde engellemek.
- **Adım:** Ayarlar > Arama Kalkanı > "Arama Filtreleme İzni İste" butonuna dokunun. Çıkan sistem rol ekranında VeroApp'i onaylayın.
- **Beklenen Sonuç:** `ROLE_CALL_SCREENING` rolü verilir. Bilinen dolandırıcı numarası aradığında telefon çalmadan arama sessizce reddedilir.

---

### [TEST 3] 0850 ve Yurt Dışı Şüpheli Arama Uyarısı ("⚠️ Şüpheli olabilir")
- **Hedef:** Desen bazlı aramaların "🚨 SPAM" yerine "⚠️ Şüpheli olabilir" uyarısı vermesi.
- **Adım:** Simülatörden veya ikinci bir hattan `+234...` veya `0850 480...` arama testi yapın (veya Uygulama içi Arama Kalkanı sekmesinde bu numarayı sorgulayın).
- **Beklenen Sonuç:** Ekranda kırmızı alarm yerine turuncu rozetle **"⚠️ Şüpheli olabilir"** uyarısı görünür.

---

### [TEST 4] WhatsApp / Telegram Link Paylaşımı (Mod B: Share Target)
- **Hedef:** Kullanıcının mesajlaşma uygulamasından gelen bir linki paylaşarak taratması.
- **Adım:** WhatsApp'ta herhangi bir mesajdaki linke uzun basıp "Paylaş" (Share) deyin. Paylaşım menüsünden "VeroApp SMS Guard"ı seçin.
- **Beklenen Sonuç:** VeroApp Link Tarayıcı ekranı otomatik olarak açılır, URL taranır ve risk skoru (Güvenli / Şüpheli / Tehlikeli) anında görüntülenir.

---

### [TEST 5] Erişilebilirlik Servisi ile Otomatik Link Algılama (Mod A)
- **Hedef:** Ekranda beliren oltalama linklerinin otomatik tespit edilmesi.
- **Adım:** Ayarlar > Erişilebilirlik > VeroApp Link Guard servisini açın. WhatsApp'ta sahte bir e-Devlet linki içeren sohbeti açın.
- **Beklenen Sonuç:** VeroApp linki ekranda görünür görünmez yakalar ve üst bildirim çubuğunda anlık phishing uyarısı verir.

---

### [TEST 6] Zararlı .APK Dosyası İndirme Tespiti
- **Hedef:** WhatsApp'tan gelen zararlı APK kurulum linklerini yakalamak.
- **Adım:** Link tarayıcıya `https://ornek-kargo-takip.xyz/yurtici.apk` yazıp "Tara" butonuna basın.
- **Beklenen Sonuç:** Risk Skoru %95 üzeri çıkar; "🚨 TEHLİKELİ BAĞLANTI: Bu link doğrudan bir Android uygulama paketi (.APK) indirmektedir" uyarısı verilir.

---

### [TEST 7] e-Devlet Şifre Güvenliği & Sızıntı Radarı
- **Hedef:** Bloom filtresi ile yerel sızıntı kontrolü.
- **Adım:** Ayarlar > e-Devlet Güvenliği sekmesine gidin. Test amaçlı bir şifre (ör. `123456` veya `password`) girin ve "Tara" deyin.
- **Beklenen Sonuç:** 50 milyon bitlik çevrimdışı Bloom filtresi anında "🚨 Bu şifre veri sızıntılarında bulundu! Değiştirin" uyarısı verir. (İnternet kapalıyken de çalışır).

---

### [TEST 8] Ed25519 İmzalı Aile / Kurumsal Lisans Aktivasyonu
- **Hedef:** Matematiksel Ed25519 açık anahtar doğrulaması ile offline lisans açma.
- **Adım:** Geliştirici aracından üretilen geçerli lisans kodunu (`VERO-FAM-eyJ...`) kopyalayıp Ayarlar > Lisans Gir kutusuna yapıştırın.
- **Beklenen Sonuç:** "✅ Lisans Doğrulandı: VERO AİLE (4 Cihaz)" bildirimi çıkar ve PRO özelliklerin kilidi anında açılır.

---

### [TEST 9] Rastgele / Sahte Lisans Kodu Reddi
- **Hedef:** Sahte lisans kodlarının anında reddedildiğini doğrulamak.
- **Adım:** Lisans kutusuna rastgele bir metin (ör. `VERO-FAM-RANDOM123456789`) yazıp "Aktifleştir"e basın.
- **Beklenen Sonuç:** Kriptografik Ed25519 imza doğrulaması başarısız olur; "❌ Geçersiz lisans kodu veya sahte imza" uyarısı verir.

---

### [TEST 10] Akıllı Gelen Kutusu (Smart Inbox) Kategorileme
- **Hedef:** SMS'lerin Banka, Kargo, OTP, Kişisel ve Spam olarak yerel ayrıştırılması.
- **Adım:** Test amaçlı banka OTP SMS'i ("123456 nolu onay kodunuz ile..."), kargo SMS'i ("... kargonuz dağıtıma çıktı") ve spam bahis SMS'i gönderin veya yapıştırın.
- **Beklenen Sonuç:** İlgili sekmelerde (Finans / Kargo / OTP / Kişisel / Spam) doğru klasörlenir.

---

### [TEST 11] Answer Bot Deneysel Modu Kontrolü
- **Hedef:** Answer Bot'un dürüstçe "Deneysel" olarak etiketlendiğini ve arama sırasında simulasyon oynattığını doğrulamak.
- **Adım:** Ayarlar > Cevap Botu (Deneysel) menüsünü açın.
- **Beklenen Sonuç:** Ekranın üstünde "⚠️ Deneysel Özellik: Standart işletim sistemi ses kanalı uplink kısıtlaması nedeniyle simülasyon amaçlı çalışır" notu yer alır.

---

### [TEST 12] Uçak Modunda Tam Fonksiyon Testi (%100 Çevrimdışı Doğrulama)
- **Hedef:** Uygulamanın sıfır internet bağımlılığı olduğunu kanıtlamak.
- **Adım:** Telefonu "Uçak Modu"na alın (Wi-Fi ve Hücresel veri kapalı). SMS analizi, link taraması, sızıntı radarı ve lisans doğrulamasını çalıştırın.
- **Beklenen Sonuç:** Tüm fonksiyonlar hiçbir gecikme veya ağ hatası olmadan eksiksiz çalışır.

---

### [TEST 13] Google Play Billing / StoreKit Sandbox Satın Alma
- **Hedef:** Gerçek mağaza faturalandırma köprüsünün tepki vermesi.
- **Adım:** Google Play Test Hesabı veya TestFlight / Apple Sandbox hesabı ile Paywall ekranından "VERO PRO" butonuna dokunun.
- **Beklenen Sonuç:** Google Play / App Store resmi satın alma tabakası (sheet) ekranda açılır.

---

### [TEST 14] iOS MessageFilterExtension (Bilinmeyen ve İstenmeyenleri Filtrele)
- **Hedef:** Apple IdentityLookup SMS filtresi doğrulaması (iOS fiziksel cihaz).
- **Adım:** iOS Ayarlar > Mesajlar > Bilinmeyen ve İstenmeyenleri Filtrele > VeroApp SMS Guard seçeneğini aktif edin. Bilinmeyen bir numaradan SMS alın.
- **Beklenen Sonuç:** Mesajlar uygulamasında gelen SMS otomatik olarak "İstenmeyen" (Junk / Promotions) sekmesine taşınır.

---

### [TEST 15] Arka Plan Kararlılığı ve Pil Tüketimi
- **Hedef:** Arka plan servislerinin çökmeden ve aşırı pil harcamadan çalışması.
- **Adım:** Cihazda arka planda 24 saat çalıştırın. Ayarlar > Pil bölümünden tüketimi kontrol edin.
- **Beklenen Sonuç:** CPU tüketimi <%1, arka plan bellek kullanımı <30 MB seviyesindedir.
