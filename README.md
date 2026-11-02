# VeroApp SMS Guard (`veroapp_sms_guard`)
### 100% Offline On-Device Semantic Intent AI Spam, Call Screening & Phishing Shield (Android / iOS / Windows)

**VeroApp SMS Guard** is a privacy-first, 100% offline, on-device SMS filtering, real-time call screening, and phishing protection application built with **Flutter**, **Kotlin** (Android Native `BroadcastReceiver`, `CallScreeningService`, `RoleManager`, `NotificationListenerService`), and **Swift** (iOS `IdentityLookup` / `ILMessageFilterExtension` & `WidgetKit`).

Zero SMS messages, call logs, or contacts ever leave the user's device (`VERO-SEC-2025-OFFLINE-CERTIFIED`).

---

## Core Architecture & Capabilities

1. **6-Stage On-Device Classification Pipeline (`SmartClassifier` — `< 20 ms` latency):**
   - **Stage 1 — Custom User Rules (`RuleEngine`):** Supports Keyword and full Regex rules (including inline flags like `(?i)`) targeting **Sender Only**, **Message Body Only**, or **Both**, with first-match-wins priority and JSON Import/Export.
   - **Stage 2 — Multilingual OTP & Transaction Detector (`OtpDetector`):** Detects verification codes and banking alerts across 10+1 languages, extracts 4–8 digit OTP codes for 1-tap copying, and blocks fake OTP+Link phishing traps.
   - **Stage 3 — Pre-Built Threat Intelligence Shields (`ThreatDatabase`):**
     - **Betting & Gambling Shield:** Blocks illegal casino, slot, freespin, deneme bonusu, and obfuscated betting SMS.
     - **Phishing, Fake Legal/İcra, HGS & Delivery Shield:** Detects 2025/2026 fraud patterns (fake tapu fee, SGK refund, tax seizure, e-Devlet court summons, customs fee traps).
     - **Suspicious Link & Levenshtein Typosquatting Scanner (`VeroLinkScanner` & `SafeClickEngine`):** Scans against 38,300+ offline phishing domains (`phishing_domains.bin`), detects `.apk` malware downloads, URL shorteners, and Levenshtein brand spoofing.
     - **Commercial / Marketing (MERSİS & BTK B-Code) Shield:** Parses Turkish BTK operator codes (`B001`–`B015`) and commercial opt-out markers.
   - **Stage 4 — 6D Semantic Intent Engine & Self-Learning Naive Bayes AI (`VeroIntentEngine` + `NaiveBayesModel`):**
     - Evaluates 6 semantic dimensions (*Urgency/Fear*, *Financial Trap*, *Reward/Betting*, *Action/Link*, *Corporate/OTP*, *Personal Chat*) with character n-gram analysis and online learning from user feedback.

2. **Real-Time Offline Caller ID & Call Screening (`< 0.1 ms` Binary Search):**
   - Powered by `assets/spam_db/spam_numbers.bin` (63,005 verified records) and `assets/spam_db/turkey_spam.bin` (25,002 local records) + 8 international & `0850` regex rules (`VeroCallerIdEngine`, `VeroCallGuardEngine`, `VeroCallerNameEngine`).
   - Full Android `android.telecom.CallScreeningService` and `RoleManager` (`ROLE_CALL_SCREENING` & `ROLE_SMS`) integration.

3. **5M SHA-1 Offline Data Breach Radar (`VeroBreachRadarEngine` & `VeroBloomFilter`):**
   - Queries a 6.25 MB on-device binary Bloom filter (`assets/breach_db/bloom_filter.bin`) representing 5,000,000 leaked credential hashes with zero network transmission.

4. **Ed25519 Cryptographic Offline Licensing (`VeroLicenseVerifier`):**
   - Verifies Pro and 4-Member Family (`VERO AİLE`) license tokens completely offline using Ed25519 public-key signatures.

5. **Global Multilingual Support (`assets/locales/`):**
   - Turkish (`tr`), English (`en`), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Portuguese (`pt`), Russian (`ru`), Arabic (`ar` with full RTL layout), Chinese Simplified (`zh`), and Hindi (`hi`).

---

## Repository Structure

```text
VeroAppSmsGuard/
├── .github/workflows/        # CI/CD (Flutter Analyze, Test, Multi-Platform Build & Weekly Threat DB Pipeline)
├── android/                  # Kotlin Native Receivers, CallScreeningService, RoleManager & Home Widget
├── ios/                      # Swift ILMessageFilterExtension (IdentityLookup), AppDelegate & WidgetKit
├── windows/                  # Native Win32 C++ Desktop Runner
├── web/landing_page/         # Standalone Flutter Web Promotional Landing Page
├── lib/
│   ├── core/                 # Classifier, Localization, Monetization (Ed25519), Platform Bridge, Rules
│   ├── engines/              # 15 Specialized Engines (CallerID, CallGuard, Intent, LinkScanner, Bloom, etc.)
│   ├── models/               # Domain Models & History Entries
│   ├── screens/              # Privacy Policy, Terms of Service & Store Screenshot Generator
│   ├── services/             # Billing & Default SMS Handler Services
│   ├── state/                # Reactive AppState & Persistence
│   ├── ui/                   # Cyberpunk Variant 3 UI Screens & Widgets
│   └── widgets/              # Native-Synchronized Home Screen Widgets (4x1 & 2x2)
├── assets/
│   ├── audio/bot_responses/  # Multilingual Answer Bot Audio Assets (TR/EN/AR)
│   ├── branding/             # Hex Shield AI Neural Core Icons
│   ├── breach_db/            # 6.25 MB 5M SHA-1 Offline Bloom Filter (bloom_filter.bin)
│   ├── fonts/                # Book Antiqua Typography
│   ├── locales/              # 10+1 Language JSON Bundles
│   ├── model/                # Multilingual Seed Corpus & TFLite Semantic Model
│   └── spam_db/              # Binary Threat Databases (spam_numbers.bin, turkey_spam.bin, phishing_domains.bin)
├── docs/
│   ├── architecture/         # System Architecture, iOS App Group Guide & Real Device Test Protocol
│   ├── archive/              # Forensic Consolidation & Audit Logs
│   ├── aso/                  # 10+1 Language Store Listings & IAP Product Catalog
│   ├── legal/                # KVKK/GDPR Offline Privacy Policy & Google Play Permissions Declaration
│   ├── marketing/            # Press Releases & Social Media Launch Packages
│   ├── partnership/          # BTK & Telecom Operator Partnership Proposals
│   └── RECOVERY_MANIFEST.json# SHA-256 Forensic Inventory of Staged Files
├── scripts/                  # Python Threat DB Builders, Delta Updater & Ed25519 License Tool
└── test/                     # Comprehensive Unit, Widget, 320x568 Responsive, 10-Locale & Engine Test Suite
```

---

## Verification & Development Commands

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (0 errors, 0 warnings)
flutter analyze --no-pub

# 3. Run the complete unit, widget, and security audit test suite
flutter test --no-pub
```
