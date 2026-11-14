# VeroApp SMS Guard — iOS Production Release & Build Checklist

> **Target Platform:** iOS 14.0+ / iPadOS 14.0+  
> **Bundle Identifier:** `com.veroapp.smsguard`  
> **Message Filter Extension:** `com.veroapp.smsguard.MessageFilterExtension`  
> **Shared App Group:** `group.com.veroapp.smsguard.filter`  
> **Host Environment Requirement:** macOS 14+ (Sonoma/Sequoia) with Xcode 15.0+  

---

## 1. Apple Developer Portal Configuration (Pre-Requisite)

Before opening the project in Xcode, configure the following in [Apple Developer Account](https://developer.apple.com/account):

### A. Register App Group
1. Go to **Certificates, Identifiers & Profiles > Identifiers**.
2. Select **App Groups** from the dropdown and click `+`.
3. Description: `VeroApp SMS Guard App Group`
4. Identifier: `group.com.veroapp.smsguard.filter`
5. Click **Continue** and **Register**.

### B. Register App Identifiers
1. **Main Application:**
   - Identifier: `com.veroapp.smsguard`
   - Description: `VeroApp SMS Guard`
   - Capabilities:
     - [x] **App Groups** (Assign `group.com.veroapp.smsguard.filter`)
     - [x] **In-App Purchase**
2. **IdentityLookup Extension:**
   - Identifier: `com.veroapp.smsguard.MessageFilterExtension`
   - Description: `VeroApp SMS Message Filter Extension`
   - Capabilities:
     - [x] **App Groups** (Assign `group.com.veroapp.smsguard.filter`)

### C. Provisioning Profiles
- Generate two Distribution Profiles (or let Xcode manage Automatic Signing):
  - `VeroApp SMS Guard AppStore Profile` (for `com.veroapp.smsguard`)
  - `VeroApp MessageFilter AppStore Profile` (for `com.veroapp.smsguard.MessageFilterExtension`)

---

## 2. Local macOS Environment Setup

Ensure Flutter and CocoaPods are installed on your macOS machine:
```bash
# Verify Flutter and Xcode
flutter doctor -v

# Navigate to project root
cd /path/to/VeroAppSmsGuard

# Fetch dependencies
flutter pub get

# Install CocoaPods
cd ios
pod install --repo-update
cd ..
```

---

## 3. Xcode Capabilities & Target Inspection

Open `ios/Runner.xcworkspace` in Xcode:

1. **Target: `Runner` (Main App)**
   - **Signing & Capabilities:**
     - Team: Select your Apple Developer Team.
     - Bundle Identifier: `com.veroapp.smsguard`
     - Verify **App Groups** is active and check `group.com.veroapp.smsguard.filter`.
     - Verify **In-App Purchase** capability is present.
   - **General:**
     - Minimum Deployments: iOS 14.0 or higher.
     - Version: `1.0.0`
     - Build: `1` (or matching `pubspec.yaml`).

2. **Target: `MessageFilterExtension` (IdentityLookup Extension)**
   - **Signing & Capabilities:**
     - Team: Select your Apple Developer Team.
     - Bundle Identifier: `com.veroapp.smsguard.MessageFilterExtension`
     - Verify **App Groups** is active and check `group.com.veroapp.smsguard.filter`.
   - **Build Settings:**
     - `IPHONEOS_DEPLOYMENT_TARGET` = `14.0`
     - `PRODUCT_MODULE_NAME` = `MessageFilterExtension`

---

## 4. Release Build & IPA Generation

### Method A: Command-Line Interface (Fastest)
```bash
# Clean previous build artifacts
flutter clean
flutter pub get

# Build iOS Archive (.ipa)
flutter build ipa --release
```
The output `.ipa` will be generated at `build/ios/ipa/VeroApp SMS Guard.ipa`.

### Method B: Xcode GUI Archive
1. Select target **Any iOS Device (arm64)** from the scheme menu.
2. Select menu **Product > Clean Build Folder** (`Cmd + Shift + K`).
3. Select menu **Product > Archive**.
4. Once the Organizer window appears:
   - Click **Validate App** to verify certificates and entitlements.
   - Click **Distribute App > App Store Connect > Upload**.

---

## 5. Verification on Physical iPhone (TestFlight / Development)

Apple IdentityLookup extensions cannot be verified in the Simulator; you MUST test on a physical iPhone:

1. Install the build via TestFlight or Xcode direct run.
2. Open iOS **Settings > Messages > Unknown & Spam**.
3. Under **SMS Filtering**, turn ON **VeroApp SMS Guard**.
4. Confirm the system alert granting permission to filter unknown senders.
5. Send a test SMS containing a known phishing URL or spam trigger.
6. Verify the message is sorted into the **Junk** or **Promotion** tab without alerting.

---

## 6. App Store Connect Submission Checklist

- [x] **Privacy Policy URL:** `https://yakiciserif-png.github.io/VeroAppSmsGuard/`
- [x] **App Privacy Nutrition Labels:** Select **"Data Not Collected"** (100% offline, zero cloud collection).
- [x] **Export Compliance:** Set `<key>ITSAppUsesNonExemptEncryption</key><false/>` in `Runner/Info.plist`.
- [x] **In-App Purchases:** Submit StoreKit in-app subscriptions matching `docs/aso/product_ids.txt`:
  - `vero_pro_monthly`
  - `vero_pro_yearly`
  - `vero_family_yearly` (Ensure Family Sharing checkbox is checked)
  - `vero_enterprise_monthly`
- [x] **Review Notes:** Mention that the app requires physical SMS testing with IdentityLookup extension enabled.
