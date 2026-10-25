# TrustLens Mobile (Junkman Pro / TrustLens Shield)
### On-Device AI Spam, Betting & Phishing Filtering Mobile App

TrustLens is a privacy-first, 100% offline, on-device SMS and notification spam/fraud detection mobile application built with Flutter, Kotlin, and Swift. Inspired by and surpassing App Store's **Junkman**, it combines a self-learning multi-class Naive Bayes AI engine, an anti-evasion de-obfuscation tokenizer, 4 pre-built Threat Intelligence Shields, a sender/body rule engine with regex support, 1-tap OTP verification code extraction, and an AI X-Ray probability inspector.

---

## Key Features (Junkman Reverse-Analysis + Pro Upgrades)

1. **4-Stage Smart Classification Pipeline (`SmartClassifier`):**
   - **Stage 1 — Custom User Rules (`RuleEngine`):** Supports Keyword and full Regex rules (including inline flags like `(?i)`) targeting **Sender Only**, **Message Body Only**, or **Both**, with first-match-wins priority and 1-tap Junkman Rule Presets + JSON Import/Export.
   - **Stage 2 — Multilingual OTP & Transaction Detector (`OtpDetector`):** Detects verification codes and banking alerts across 10 languages, **extracts the 4–8 digit OTP code** for 1-tap clipboard copying, and blocks fake OTP+Link phishing traps.
   - **Stage 3 — Pre-Built Threat & Spam Intelligence Database (`ThreatDatabase`):**
     - **🎰 Betting & Gambling Shield:** Catches illegal casino, slot, freespin, deneme bonusu, çevrimsiz bonus, Sweet Bonanza, and obfuscated betting SMS.
     - **🎣 Phishing, Fake Legal/İcra, HGS & Delivery Shield:** Catches fake uzlaştırma/icra files, HGS toll scams, customs fee traps, and bank suspension phishing.
     - **🔗 Suspicious Link & Shortener Shield:** Detects `bit.ly`, `cutt.ly`, `tinyurl.com`, high-risk TLDs (`.xyz`, `.top`, `.vip`, `.icu`, `.loan`), and fake OTP+Link traps.
     - **🛍️ Commercial / Marketing (MERSİS & B-Code) Shield:** Optional toggle to filter commercial promotions containing `MERSIS`, `B001`/`B002` codes, or `RET`/`STOP` opt-out instructions.
   - **Stage 4 — Self-Learning On-Device Naive Bayes AI (`NaiveBayesModel`):**
     - Incremental online learning from user corrections (`weight: 3`) with Laplace smoothing and automatic weight export to native iOS/Android background extensions.

2. **Anti-Evasion De-Obfuscation (`Tokenizer`):**
   - Automatically normalizes zero-width characters, spaced-out words (`B O N U S`, `f.r.e.e.s.p.i.n` → `bonus`, `freespin`), and leetspeak (`b0nus` → `bonus`).

3. **X-Ray Deep Analysis & Live Simulator:**
   - **Junkman Live Simulator** on the Home Screen with optional Sender field and 1-tap realistic test scenario chips (*Betting*, *Fake Legal/HGS*, *Bank OTP*, *Promo/B-Code*, *Normal Chat*).
   - **AI X-Ray Probability Breakdown** bars showing exact confidence across `Normal`, `Transaction / OTP`, and `Spam`.
   - **Diagnostic Signal Badges** explaining every risk or trust factor detected in the message.

4. **Dual Platform Native Integration:**
   - **iOS (`ILMessageFilterExtension` + `TrustFilterEngine.swift`):** Uses Apple's official `IdentityLookup` framework with iOS 14+ granular sub-actions (`.junk`, `.promotionOffers`, `.transactionalFinance`, `.transactionalOthers`) synchronized via App Group (`group.com.trustlens.filter`).
   - **Android (`TrustNotificationListener.kt` + `TrustFilterEngine.kt`):** Filters incoming notifications in real time via `NotificationListenerService` and automatically dismisses spam without requiring invasive `READ_SMS` permissions.

5. **Global 10-Language Support:**
   - Turkish (`tr`), English (`en`), Spanish (`es`), German (`de`), French (`fr`), Italian (`it`), Russian (`ru`), Chinese Simplified (`zh`), Arabic (`ar` with RTL), Portuguese (`pt`).

---

## Running & Testing

```bash
# Static analysis
flutter analyze

# Full unit & widget test suite
flutter test

# Run live on Windows / Chrome / Android / iOS
flutter run -d chrome
```
