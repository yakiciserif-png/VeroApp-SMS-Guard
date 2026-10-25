# TrustLens iOS Deployment & Xcode Configuration Guide

This document describes how to build, configure, and publish **TrustLens Mobile** on macOS using Xcode, including the **iOS SMS Message Filter Extension (`ILMessageFilterExtension`)**.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │          TrustLens Flutter App       │
                      │  (Dart UI, Settings, Model Training) │
                      └──────────────────┬───────────────────┘
                                         │ syncFilterConfig
                                         ▼
                      ┌──────────────────────────────────────┐
                      │            App Group                 │
                      │   group.com.trustlens.filter         │
                      │  (Shared UserDefaults / Config JSON) │
                      └──────────────────┬───────────────────┘
                                         │ reads weights & rules
                                         ▼
                      ┌──────────────────────────────────────┐
                      │    iOS Message Filter Extension      │
                      │    (IdentityLookup Framework)        │
                      │  - Native Swift Tokenizer & Model    │
                      │  - Runs offline without Flutter VM   │
                      └──────────────────────────────────────┘
```

---

## Prerequisites (macOS Machine)

1. **Mac computer running macOS Sonoma (14+) or Sequoia (15+)**
2. **Xcode 15 or 16** (available on the Mac App Store)
3. **Flutter SDK** (`flutter doctor` should show all green checkmarks)
4. **Apple Developer Account** (required to enable the App Groups entitlement on physical devices)

---

## Step 1: Open the Project in Xcode

1. Clone or copy this repository to your Mac.
2. In the terminal, navigate to the project directory and fetch dependencies:
   ```bash
   cd trustlens_mobile
   flutter pub get
   ```
3. Open the iOS workspace in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   *(If `Runner.xcworkspace` does not exist yet, open `ios/Runner.xcodeproj`)*

---

## Step 2: Configure App Groups (Runner Target)

1. Select the top-level **Runner** project in the Xcode Project Navigator.
2. Select the **Runner** target.
3. Click the **Signing & Capabilities** tab.
4. Click **+ Capability** and double-click **App Groups**.
5. Click **+** under App Groups and enter:
   ```
   group.com.trustlens.filter
   ```
   *(Ensure the checkbox next to `group.com.trustlens.filter` is checked).*

---

## Step 3: Add the Message Filter Extension Target (if adding from scratch)

1. In Xcode menu, click **File > New > Target...**
2. In the template search box, type **Message Filter Extension** (under iOS / Application Extension) and click **Next**.
3. Configure the extension:
   - **Product Name:** `MessageFilterExtension`
   - **Language:** `Swift`
   - **Project:** `Runner`
   - **Embed in Application:** `Runner`
4. Click **Finish**. If prompted to activate the scheme, click **Activate**.
5. Copy the prepared files from `ios/MessageFilterExtension/` into this target:
   - `MessageFilterExtension.swift`
   - `TrustFilterEngine.swift`
   - `Info.plist`
6. Make sure both Swift files have their **Target Membership** set to `MessageFilterExtension`.
7. Add the **App Groups** capability to `MessageFilterExtension`:
   - Select `MessageFilterExtension` target.
   - Go to **Signing & Capabilities** > **+ Capability** > **App Groups**.
   - Check `group.com.trustlens.filter`.

---

## Step 4: Testing the SMS Filter on iOS Simulator / Physical Device

### On iOS Simulator:
1. In Xcode, select the **MessageFilterExtension** scheme and run it on an iPhone simulator.
2. Xcode prompts you to select an app to run with: choose **Messages**.
3. On the Simulator, open **Settings > Apps > Messages > Unknown & Spam** (or **Unknown & Junk**).
4. Under **SMS Filtering**, toggle **TrustLens** to **ON**.
5. Send test SMS messages via Xcode's simulation interface or terminal:
   ```bash
   xcrun simctl pbx <sim_id> ...
   ```

### Verification Scenarios:
- **Spam Message:** `"Congratulations! You won a $1000 prize at bit.ly/test"` -> Filtered into the **Junk** tab in Messages app.
- **OTP Message:** `"Your verification code is 482913"` -> Categorized into **Transactions** (iOS 14+).
- **Normal Message:** `"Hey are you free for coffee today?"` -> Placed into the standard **Inbox**.

---

## Step 5: Archiving & App Store Submission

1. In Xcode, select **Any iOS Device (arm64)** as the build target.
2. Select **Product > Archive**.
3. Once the archive succeeds in the Xcode Organizer, click **Distribute App**.
4. Select **App Store Connect** > **Upload** and follow the standard signing flow.
