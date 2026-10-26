# VeroApp SMS Guard iOS Deployment & Xcode Configuration Guide

This document describes how to build, configure, and publish **VeroApp SMS Guard** on macOS using Xcode, including the **iOS SMS Message Filter Extension (`ILMessageFilterExtension`)**.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │       VeroApp SMS Guard App          │
                      │  (Dart UI, Settings, Model Training) │
                      └──────────────────┬───────────────────┘
                                         │ syncFilterConfig
                                         ▼
                      ┌──────────────────────────────────────┐
                      │            App Group                 │
                      │  group.com.veroapp.smsguard.filter   │
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

## Step 1: Configure App Groups (Runner Target)

1. Select the top-level **Runner** project in the Xcode Project Navigator.
2. Select the **Runner** target.
3. Click the **Signing & Capabilities** tab.
4. Click **+ Capability** and double-click **App Groups**.
5. Click **+** under App Groups and enter:
   ```
   group.com.veroapp.smsguard.filter
   ```
   *(Ensure the checkbox next to `group.com.veroapp.smsguard.filter` is checked).*

---

## Step 2: Configure the Message Filter Extension Target

1. Copy the prepared files from `ios/MessageFilterExtension/` into `MessageFilterExtension`:
   - `MessageFilterExtension.swift`
   - `TrustFilterEngine.swift`
   - `Info.plist`
2. Add the **App Groups** capability to `MessageFilterExtension`:
   - Select `MessageFilterExtension` target.
   - Go to **Signing & Capabilities** > **+ Capability** > **App Groups**.
   - Check `group.com.veroapp.smsguard.filter`.

---

## Step 3: Testing the SMS Filter on iOS Simulator / Physical Device

1. In Xcode, select the **MessageFilterExtension** scheme and run it on an iPhone simulator.
2. On the Simulator, open **Settings > Apps > Messages > Unknown & Spam**.
3. Under **SMS Filtering**, toggle **VeroApp SMS Guard** to **ON**.
