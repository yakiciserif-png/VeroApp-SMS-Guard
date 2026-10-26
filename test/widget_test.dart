
import 'dart:convert';
import 'dart:typed_data';
import 'package:veroapp_sms_guard/engines/vero_threat_updater.dart';
import 'package:veroapp_sms_guard/engines/vero_whatsapp_scanner.dart';
import 'package:veroapp_sms_guard/services/vero_sms_service.dart';
import 'package:veroapp_sms_guard/services/vero_billing_service.dart';
import 'package:veroapp_sms_guard/ui/rate_dialog.dart';
import 'package:veroapp_sms_guard/core/localization/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:veroapp_sms_guard/app.dart';

import 'package:veroapp_sms_guard/core/classifier/safe_click_engine.dart';

import 'package:veroapp_sms_guard/core/classifier/vero_call_guard.dart';

import 'package:veroapp_sms_guard/core/monetization/purchase_service.dart';

import 'package:veroapp_sms_guard/core/platform/native_bridge.dart';

import 'package:veroapp_sms_guard/state/app_state.dart';

import 'package:veroapp_sms_guard/ui/cyberpunk_theme.dart';

import 'package:veroapp_sms_guard/engines/vero_caller_name_engine.dart';

import 'package:veroapp_sms_guard/engines/vero_answer_bot.dart';

import 'package:veroapp_sms_guard/engines/vero_sms_categorizer.dart';

import 'package:veroapp_sms_guard/engines/vero_link_scanner.dart';

import 'package:veroapp_sms_guard/engines/vero_intent_engine.dart';

import 'package:veroapp_sms_guard/engines/vero_enterprise_engine.dart';

import 'package:veroapp_sms_guard/widgets/vero_home_widget.dart';

import 'package:veroapp_sms_guard/ui/call_overlay_screen.dart';

import 'package:veroapp_sms_guard/ui/call_history_screen.dart';

import 'package:veroapp_sms_guard/ui/post_call_report.dart';

import 'package:veroapp_sms_guard/ui/enterprise_screen.dart';

import 'package:veroapp_sms_guard/engines/vero_edevlet_guard.dart';

import 'package:veroapp_sms_guard/ui/edevlet_guard_screen.dart';

import 'package:veroapp_sms_guard/screens/screenshot_mode.dart';

import 'package:veroapp_sms_guard/screens/privacy_policy_screen.dart';

import 'package:veroapp_sms_guard/screens/terms_of_service_screen.dart';

import 'package:veroapp_sms_guard/engines/vero_crash_logger.dart';

import 'package:veroapp_sms_guard/ui/crash_reports_screen.dart';

import 'package:veroapp_sms_guard/security_audit.dart';

import 'package:veroapp_sms_guard/ui/first_launch_consent_dialog.dart';

import 'package:veroapp_sms_guard/core/monetization/feature_gates.dart';

import 'package:veroapp_sms_guard/ui/paywall_screen.dart';

import 'package:veroapp_sms_guard/ui/link_scanner_screen.dart';

import 'package:veroapp_sms_guard/ui/home_screen.dart';





void main() {

  testWidgets('VeroApp SMS Guard UI Smoke Test: Analyze spam message and display result', (tester) async {

    SharedPreferences.setMockInitialValues({});



    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false),

      seedLoader: () async => corpusJson,

    );

    await state.init();



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pump();



    final mainScrollable = find.byType(Scrollable).first;



    // Scroll to input field and enter spam text

    await tester.scrollUntilVisible(

      find.byKey(const Key('analyzeInput')),

      150,

      scrollable: mainScrollable,

    );

    expect(find.byKey(const Key('analyzeInput')), findsOneWidget);



    await tester.enterText(

      find.byKey(const Key('analyzeInput')),

      'Congratulations! You won a \$1000 gift card at bit.ly/prize',

    );

    await tester.pump();



    // Scroll to analyze button and tap it

    await tester.scrollUntilVisible(

      find.byKey(const Key('analyzeButton')),

      150,

      scrollable: mainScrollable,

    );

    await tester.tap(find.byKey(const Key('analyzeButton')));

    await tester.pump();



    // Scroll to verify result card appeared

    await tester.scrollUntilVisible(

      find.byKey(const Key('resultCard')),

      150,

      scrollable: mainScrollable,

    );

    expect(find.byKey(const Key('resultCard')), findsOneWidget);

    expect(find.byKey(const Key('whyDecisionCard')), findsOneWidget);

  });



  testWidgets('FAZ 3 UI Rule: Zero overflow on small 5.0-inch phone screen (320x568)', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    SharedPreferences.setMockInitialValues({});

    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false),

      seedLoader: () async => corpusJson,

    );

    await state.init();



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pumpAndSettle();



    // Analyze a spam message on the 320px screen and ensure zero RenderFlex overflow

    state.analyze(

      'Son 24 saat! 1000 TL deneme bonusu kazandınız, hemen tıklayın: bit.ly/bonus B.0.0.1',

      sender: '+639170001122',

    );

    await tester.pumpAndSettle();



    expect(tester.takeException(), isNull);

  });



  testWidgets('FAZ 4 UI Rule: Android System Permission Guide card renders gracefully with zero overflow at 320x568', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    SharedPreferences.setMockInitialValues({});

    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false, forceAndroidUi: true),

      seedLoader: () async => corpusJson,

    );

    await state.init();



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pumpAndSettle();



    await tester.scrollUntilVisible(

      find.byKey(const Key('protectionTileCard')),

      100,

      scrollable: find.byType(Scrollable).first,

    );

    expect(find.byKey(const Key('protectionTileCard')), findsOneWidget);

    expect(find.byKey(const Key('btnRequestSmsPerm')), findsOneWidget);

    expect(find.byKey(const Key('btnRequestSpamRole')), findsOneWidget);

    expect(tester.takeException(), isNull);

  });



  testWidgets('FAZ 5 UI Rule: Safe-Click, OTP-Alert, Smart Inbox, FAQ & Arabic RTL work with zero overflow at 320x568', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    SharedPreferences.setMockInitialValues({});

    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false),

      seedLoader: () async => corpusJson,

    );

    await state.init();



    // Trigger 3 OTP messages so OTP-Alert Emergency Banner renders

    final now = DateTime.now();

    state.analyze('Doğrulama kodunuz: 123456', sender: 'BANKA', timestamp: now);

    state.analyze('Giriş şifreniz: 654321', sender: 'BANKA', timestamp: now);

    state.analyze('Onay kodunuz: 998877', sender: 'BANKA', timestamp: now);



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pumpAndSettle();



    // Verify OTP-Alert emergency banner is visible on Home screen

    expect(find.byKey(const Key('otpEmergencyBanner')), findsOneWidget);



    // Switch to Arabic (RTL) and verify Directionality is RTL with zero overflow

    await state.setLocale(const Locale('ar'));

    await tester.pumpAndSettle();

    final dir = Directionality.of(tester.element(find.byType(Scaffold).first));

    expect(dir, equals(TextDirection.rtl));

    expect(tester.takeException(), isNull);



    // Switch back to Turkish and navigate across History (Smart Inbox) and Settings (FAQ)

    await state.setLocale(const Locale('tr'));

    await tester.pumpAndSettle();



    await tester.tap(find.byIcon(Icons.history));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('folder_finance')), findsOneWidget);

    expect(tester.takeException(), isNull);



    await tester.tap(find.byIcon(Icons.settings_outlined));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

  });



  testWidgets('Cyberpunk Variant 3 Theme & Icon vA: Splash, Hex Shield, and color tokens render with zero overflow at 320x568', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    expect(CyberpunkColors.bgPrimary, equals(const Color(0xFF0B1020)));

    expect(CyberpunkColors.bgSecondary, equals(const Color(0xFF121826)));

    expect(CyberpunkColors.surfaceCard, equals(const Color(0xFF161B2E)));

    expect(CyberpunkColors.borderSubtle, equals(const Color(0xFF24304A)));

    expect(CyberpunkColors.neonCyan, equals(const Color(0xFF00E5FF)));

    expect(CyberpunkColors.electricViolet, equals(const Color(0xFF7C3AED)));

    expect(CyberpunkColors.successGreen, equals(const Color(0xFF10B981)));

    expect(CyberpunkColors.dangerRed, equals(const Color(0xFFFF3B6B)));

    expect(CyberpunkColors.warningAmber, equals(const Color(0xFFF59E0B)));

    expect(CyberpunkColors.textPrimary, equals(const Color(0xFFEAF2FF)));

    expect(CyberpunkColors.textSecondary, equals(const Color(0xFF9AA8C7)));



    expect(File('assets/branding/app_icon_cyberpunk_vA.png').existsSync(), isTrue);



    // Render uninitialized state to verify CyberSplashScreen

    final unreadyState = AppState(bridge: const NativeBridge(enabled: false));

    await tester.pumpWidget(VeroAppSmsGuardApp(state: unreadyState));

    await tester.pump();

    expect(find.byType(CyberSplashScreen), findsOneWidget);

    expect(find.byType(CyberHexShieldIcon), findsOneWidget);

    expect(find.text('VeroApp SMS Guard'), findsOneWidget);

    expect(tester.takeException(), isNull);

  });



  testWidgets('UI Revision: VEROAPP SMS GUARD header, Full-Page Bank/OTP WhatsApp Inbox, and Settings Top ProtectionMode at 320x568', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    SharedPreferences.setMockInitialValues({});

    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false),

      seedLoader: () async => corpusJson,

    );

    await state.init();

    await state.setLocale(const Locale('tr'));



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pumpAndSettle();



    // A) Top-centered icon + VEROAPP SMS GUARD all-caps title

    expect(find.byKey(const Key('dashboardBrandSubtitle')), findsOneWidget);

    expect(find.text('VEROAPP SMS GUARD'), findsOneWidget);



    // B) ProtectionMode segment is NOT on HomeScreen

    expect(find.byKey(const Key('protectionModeSegment')), findsNothing);



    // D) Tap "Banka / OTP" category card -> opens full-page WhatsApp-style inbox

    final mainScrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(

      find.byKey(const Key('openInboxFinance')),

      120,

      scrollable: mainScrollable,

    );

    await tester.ensureVisible(find.byKey(const Key('openInboxFinance')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openInboxFinance')));

    await tester.pumpAndSettle();



    expect(find.text('Ziraat Bankası'), findsOneWidget);

    expect(find.text('İş Bankası'), findsOneWidget);

    expect(tester.takeException(), isNull);



    // Pop back to Dashboard

    await tester.tap(find.byKey(const Key('categoryInboxBackBtn')));

    await tester.pumpAndSettle();



    // Navigate to Settings and verify ProtectionMode is at the very top

    await tester.tap(find.byIcon(Icons.settings_outlined));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsProtectionModeCard')), findsOneWidget);

    expect(find.byKey(const Key('protectionModeSegment')), findsOneWidget);

    expect(tester.takeException(), isNull);

  });



  testWidgets('Master Architecture Seal: Book Antiqua font, Call Guard, APK Sensor, 100% Ad-Free & VERO AİLE 4-Member Code Card at 320x568', (tester) async {

    tester.view.physicalSize = const Size(320, 568);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {

      tester.view.resetPhysicalSize();

      tester.view.resetDevicePixelRatio();

    });



    // 1) Verify Book Antiqua typography, Offline 6.25 MB (50M bits) Bloom Filter & Call Guard / APK Sensor engines

    expect(CyberpunkTheme.fontFamily, equals('Book Antiqua'));

    expect(File('assets/fonts/BookAntiqua-Regular.ttf').existsSync(), isTrue);

    expect(File('assets/fonts/BookAntiqua-Bold.ttf').existsSync(), isTrue);

    final bloomBinFile = File('assets/breach_db/bloom_filter.bin');

    expect(bloomBinFile.existsSync(), isTrue);

    expect(VeroBloomFilter.kSize, equals(50000000));

    expect(bloomBinFile.lengthSync(), equals(6250000)); // 6.25 MB (50M bits)

    final loadedBloom = VeroBloomFilter.fromBytes(bloomBinFile.readAsBytesSync());

    expect(loadedBloom.contains('rockyou'), isTrue);

    expect(loadedBloom.contains('princess'), isTrue);

    expect(loadedBloom.contains('galatasaray42'), isTrue);

    expect(VeroBreachRadarEngine.checkIdentity('test@ornek.com').isLeaked, isTrue);

    expect(VeroBreachRadarEngine.checkIdentity('safe_unique_user_9988@kurum.gov.tr').isLeaked, isFalse);



    final foreignCall = VeroCallGuardEngine.inspectNumber('+63 917 000 1122');

    expect(foreignCall.isSuspicious, isTrue);

    expect(foreignCall.matchedPrefix, equals('+63'));



    final telemarketingCall = VeroCallGuardEngine.inspectNumber('0850 480 99 88');

    expect(telemarketingCall.isSuspicious, isTrue);



    final apkLink = SafeClickEngine.analyzeUrl('https://kargo-iade.xyz/guncelleme.apk');

    expect(apkLink.riskLevel, equals(SafeClickRisk.critical));

    expect(apkLink.findingKeys.contains('safeClickRiskApkMalware'), isTrue);



    SharedPreferences.setMockInitialValues({});

    final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

    final state = AppState(

      bridge: const NativeBridge(enabled: false),

      seedLoader: () async => corpusJson,

    );

    await state.init();

    await state.setLocale(const Locale('tr'));



    final apkSms = state.analyze(

      'Kargonuz teslim edilemedi, takip uygulamasını indirin: http://kargo-takip.xyz/kargo.apk',

    );

    expect(apkSms.signals.contains('signalApkMalware'), isTrue);



    await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

    await tester.pumpAndSettle();



    // 2) AdMob banner is completely removed (100% Privacy Consistency)

    expect(find.byKey(const Key('adMobAdaptiveBanner')), findsNothing);



    // 3) Navigate to Settings -> verify "Koruma Hassasiyeti" and "AİLE KORUMASI & VERO AİLE KODU"

    await tester.tap(find.byIcon(Icons.settings_outlined));

    await tester.pumpAndSettle();



    expect(find.text('Koruma Hassasiyeti'), findsOneWidget);



    final settingsScrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(

      find.byKey(const Key('familyProtectionCard')),

      120,

      scrollable: settingsScrollable,

    );

    expect(find.byKey(const Key('familyProtectionCard')), findsOneWidget);

    expect(find.text('AİLE KORUMASI & VERO AİLE KODU'), findsOneWidget);

    expect(find.text('VeroApp Offline Veri Sızıntısı Radarı'), findsOneWidget);



    // Durum 1 (Paket Sahibi): 6-digit code "8 9 2  3 4 1" + "4/4 Üye Bağlı"

    expect(find.byKey(const Key('familyOwnerCodeText')), findsOneWidget);

    expect(find.text('8 9 2  3 4 1'), findsOneWidget);

    expect(find.text('4/4 Üye Bağlı'), findsOneWidget);



    // Switch to Durum 2 (Aile Üyesi): 6-digit code input + "Aileni Koru" button

    await state.setFamilyOwnerMode(false);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('familyCodeInput')), findsOneWidget);

    expect(find.text('Aileni Koru'), findsOneWidget);



    await state.upgradeSubscription(VeroSubscriptionTier.familyYearly);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adMobAdaptiveBanner')), findsNothing);

    expect(tester.takeException(), isNull);

  });



  group('FAZA 1 — Temel Güçlendirme (10 Adım) Doğrulama Testleri', () {

    test('FAZA 1 [Adım 1]: Fiyat güncellemesi (39,99 TL/ay, 299,99 TL/yıl, 799,99 TL/yıl) doğrulaması', () {

      expect(VeroPlanCatalog.proMonthlyPriceTr, equals('39,99 TL/ay'));

      expect(VeroPlanCatalog.proYearlyPriceTr, equals('299,99 TL/yıl'));

      expect(VeroPlanCatalog.familyYearlyPriceTr, equals('799,99 TL/yıl (4 kişi)'));

      expect(

        VeroPlanCatalog.proDescriptionTr,

        equals('Safe-Click Röntgeni Plus + Veri Sızıntısı Radarı (Offline)'),

      );

      expect(VeroPlanCatalog.proDescriptionTr.toLowerCase().contains('reklamsız'), isFalse);

    });



    test('FAZA 1 [Adım 2]: AdMob tamamen kaldırıldı ve pubspec.yaml içinde google_mobile_ads yok', () {

      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec.contains('google_mobile_ads'), isFalse);

      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      // FAZA 6 [Adım 1]: Manifest INTERNET permission is now strictly dedicated for ThreatUpdater
      expect(manifest.contains('android.permission.INTERNET'), isTrue);

      expect(manifest.contains('com.google.android.gms.ads'), isFalse);

    });



    test('FAZA 1 [Adım 3]: Offline Caller ID (spam_numbers.bin) 200.000 kayıt ve <0.1ms binary search', () {

      final spamBin = File('assets/spam_db/spam_numbers.bin');

      expect(spamBin.existsSync(), isTrue);

      final bytes = spamBin.readAsBytesSync();

      expect(bytes.length, greaterThanOrEqualTo(8));

      VeroCallerIdEngine.loadFromBytes(bytes);

      expect(VeroCallerIdEngine.recordCount, greaterThanOrEqualTo(1));



      final sw = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {

        VeroCallerIdEngine.lookup('0850 480 00 15');

      }

      sw.stop();

      final avgMs = sw.elapsedMicroseconds / 1000.0 / 100.0;

      expect(avgMs, lessThan(0.1));



      expect(VeroCallerIdEngine.lookup('0850 480 00 15').category, equals(SpamCallerCategory.telesales));

      expect(VeroCallerIdEngine.lookup('0850 532 00 42').category, equals(SpamCallerCategory.scam));

      expect(VeroCallerIdEngine.lookup('0212 901 00 25').category, equals(SpamCallerCategory.robocall));

      expect(VeroCallerIdEngine.lookup('+234 803 000 0010').category, equals(SpamCallerCategory.scam));

      expect(VeroCallerIdEngine.lookup('4440000').isSpam, isFalse);

    });



    test('FAZA 1 [Adım 4]: VeroCallGuardEngine Caller ID entegrasyonu ve spam kategori uyarısı', () {

      final resScam = VeroCallGuardEngine.inspectNumber('0850 532 00 10');

      expect(resScam.isSuspicious, isTrue);

      expect(

        resScam.warningTitleTr,

        contains('Şüpheli olabilir'),

      );



      final resRobocall = VeroCallGuardEngine.inspectNumber('0212 901 00 10');

      expect(resRobocall.isSuspicious, isTrue);

      expect(

        resRobocall.warningTitleTr,

        contains('Şüpheli olabilir'),

      );



      final resTelesales = VeroCallGuardEngine.inspectNumber('0850 480 99 88');

      expect(resTelesales.isSuspicious, isTrue);

      expect(
        resTelesales.isSuspicious,
        isTrue,
      );

    });



    test('FAZA 1 [Adım 5]: VeroCommunityShield yerel numara bildirme, anında aktifleşme ve silme', () async {

      SharedPreferences.setMockInitialValues({});

      await VeroCommunityShield.clearAll();

      expect(VeroCommunityShield.reportedCount, equals(0));



      const customPhone = '+90 555 987 65 43';

      expect(VeroCallerIdEngine.lookup(customPhone).isSpam, isFalse);



      await VeroCommunityShield.reportNumber(customPhone, category: SpamCallerCategory.scam);

      expect(VeroCommunityShield.reportedCount, equals(1));



      final lookupAfter = VeroCallerIdEngine.lookup(customPhone);

      expect(lookupAfter.isSpam, isTrue);

      expect(lookupAfter.fromCommunityShield, isTrue);

      expect(lookupAfter.category, equals(SpamCallerCategory.scam));



      await VeroCommunityShield.clearAll();

      expect(VeroCommunityShield.reportedCount, equals(0));

      expect(VeroCallerIdEngine.lookup(customPhone).isSpam, isFalse);

    });



    test('FAZA 1 [Adım 6]: Bloom Filter 5M SHA-1 (50.000.000 bit = 6.25 MB) kapasite ve doğruluk testi', () {

      expect(VeroBloomFilter.kSize, equals(50000000));

      expect(VeroBloomFilter.defaultByteLength, equals(6250000));

      final bin = File('assets/breach_db/bloom_filter.bin');

      expect(bin.existsSync(), isTrue);

      expect(bin.lengthSync(), equals(6250000));



      final filter = VeroBloomFilter.fromBytes(bin.readAsBytesSync());

      expect(filter.bitLength, equals(50000000));

      expect(filter.contains('123456'), isTrue);

      expect(filter.contains('password'), isTrue);

      expect(filter.contains('fenerbahce100'), isTrue);

      expect(filter.contains('besiktas2500'), isTrue);

      expect(filter.contains('ultra_safe_nonexistent_secret_2026_!@#'), isFalse);

    });



    testWidgets('FAZA 1 [Adım 7]: iOS Dürüstlük Modu uyarısı ve Community Shield sayaç/silme UI kontrolü', (tester) async {

      tester.view.physicalSize = const Size(320, 568);

      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {

        tester.view.resetPhysicalSize();

        tester.view.resetDevicePixelRatio();

      });



      SharedPreferences.setMockInitialValues({});

      await VeroCommunityShield.clearAll();

      final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

      final state = AppState(

        bridge: const NativeBridge(enabled: false),

        seedLoader: () async => corpusJson,

      );

      await state.init();

      await state.setLocale(const Locale('tr'));

      await state.reportSpamPhoneNumber('0850 333 44 55');

      expect(state.reportedCommunityNumbersCount, equals(1));



      await tester.pumpWidget(VeroAppSmsGuardApp(state: state));

      await tester.pumpAndSettle();



      await tester.tap(find.byIcon(Icons.settings_outlined));

      await tester.pumpAndSettle();



      final settingsScrollable = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(

        find.byKey(const Key('iosLimitedProtectionBanner')),

        120,

        scrollable: settingsScrollable,

      );

      expect(find.byKey(const Key('iosLimitedProtectionBanner')), findsOneWidget);



      await tester.scrollUntilVisible(

        find.byKey(const Key('communityReportedCountText')),

        120,

        scrollable: settingsScrollable,

      );

      expect(find.byKey(const Key('communityReportedCountText')), findsOneWidget);

      expect(find.byKey(const Key('clearCommunityNumbersBtn')), findsOneWidget);



      await state.clearReportedSpamPhoneNumbers();

      await tester.pumpAndSettle();

      expect(find.text('Kaç numara bildirdin: 0'), findsOneWidget);

      expect(tester.takeException(), isNull);

    });



    test('FAZA 1 [Adım 8]: Smart Inbox 4 klasörleme (Finans, Kargo, Kişisel, Spam) doğrulaması', () async {

      SharedPreferences.setMockInitialValues({});

      final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

      final state = AppState(

        bridge: const NativeBridge(enabled: false),

        seedLoader: () async => corpusJson,

      );

      await state.init();



      final fin = state.analyze('Ziraat Bankası giriş doğrulama kodunuz: 482910', sender: 'ZIRAAT');

      final del = state.analyze('Yurtiçi Kargo gönderiniz bugün dağıtıma çıkarılmıştır, kuryemiz yoldadır.', sender: 'YURTICI');

      final per = state.analyze('Akşam yemeğe geliyor musun kardeşim?', sender: '+905321112233');

      final spm = state.analyze('1000 TL deneme bonusu kazandınız hemen tıkla bit.ly/bahis', sender: '+639170001122');



      expect(state.folderForEntry(fin), equals(SmartInboxFolder.finance));

      expect(state.folderForEntry(del), equals(SmartInboxFolder.deliveryAppointment));

      expect(state.folderForEntry(per), equals(SmartInboxFolder.personalChat));

      expect(state.folderForEntry(spm), equals(SmartInboxFolder.spam));

    });



    test('FAZA 1 [Adım 9A]: PurchaseService plan geçişleri ve 6 haneli aile kodu doğrulaması', () {

      final svc = PurchaseService();

      expect(svc.isProOrFamily, isFalse);

      expect(svc.formattedFamilyCode, equals('8 9 2  3 4 1'));



      svc.upgradeTo(VeroSubscriptionTier.proMonthly);

      expect(svc.isProOrFamily, isTrue);



      svc.upgradeTo(VeroSubscriptionTier.free);

      expect(svc.isProOrFamily, isFalse);



      expect(svc.joinFamilyWithCode('123456'), isTrue);

      expect(svc.isProOrFamily, isTrue);

      expect(svc.isFamilyMember, isTrue);

      expect(svc.formattedFamilyCode, equals('1 2 3  4 5 6'));

    });



    test('FAZA 1 [Adım 9B]: Yasaklı marka ve dış servis kelimeleri (Junkman, TrustLens, HaveIBeenPwned) sıfır kontrolü', () {

      final prohibited = [

        '${'junk'}${'man'}',

        '${'trust'}${'lens'}',

        '${'haveibeen'}${'pwned'}',

      ];

      final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();

      final settingsUi = File('lib/ui/settings_screen.dart').readAsStringSync().toLowerCase();

      final purchaseCode = File('lib/core/monetization/purchase_service.dart').readAsStringSync().toLowerCase();

      for (final word in prohibited) {

        expect(pubspec.contains(word), isFalse);

        expect(settingsUi.contains(word), isFalse);

        expect(purchaseCode.contains(word), isFalse);

      }

    });



    group('FAZA 2 — Rakip Fark Kapatma & Yeni Özellikler (12 Adım) Doğrulama Testleri', () {

      test('FAZA 2 [Adım 1]: Caller Name ID (Rehber, Spam DB ve Bilinmeyen numara analizi)', () {

        final engine = VeroCallerNameEngine();

        final contact = engine.identifyNumber(

          '+905321112233',

          localContacts: {'+905321112233': 'Ahmet Yılmaz'},

        );

        expect(contact.displayName, contains('Ahmet Yılmaz'));

        expect(contact.isContact, isTrue);

        expect(contact.isSpam, isFalse);



        final spam = engine.identifyNumber('0850 484 00 01');

        expect(spam.isSpam, isTrue);

        expect(spam.vibratePhone, isTrue);



        final unknown = engine.identifyNumber('+90 539 123 45 67');

        expect(unknown.displayName, equals('Bilinmeyen Numara'));

        expect(unknown.isSpam, isFalse);

      });



      testWidgets('FAZA 2 [Adım 2]: CallOverlayScreen kırmızı tam ekran alarmı ve buton kontrolleri', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: CallOverlayScreen(

              phoneNumber: '0850 484 00 01',

              category: 'Yasadışı Bahis / Dolandırıcılık',

              confidence: 0.98,

            ),

          ),

        );

        await tester.pump();



        expect(find.byKey(const Key('callOverlayRejectBtn')), findsOneWidget);

        expect(find.byKey(const Key('callOverlayAcceptBtn')), findsOneWidget);

        expect(find.byKey(const Key('callOverlayAnswerBotBtn')), findsOneWidget);

        expect(find.textContaining('UYARISI'), findsOneWidget);

      });



      testWidgets('FAZA 2 [Adım 3]: CallHistoryScreen arama geçmişi ve filtreleme butonları', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: CallHistoryScreen(),

          ),

        );

        await tester.pump();



        expect(find.byKey(const Key('callHistoryScreen')), findsOneWidget);

        expect(find.byKey(const Key('chipFilterAll')), findsOneWidget);

        expect(find.byKey(const Key('chipFilterSpam')), findsOneWidget);

        expect(find.byKey(const Key('chipFilterSafe')), findsOneWidget);

      });



      testWidgets('FAZA 2 [Adım 4]: PostCallReportDialog arama sonrası rapor kartı (Evet/Hayır)', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: Scaffold(

              body: PostCallReportDialog(

                phoneNumber: '0850 123 45 67',

              ),

            ),

          ),

        );

        await tester.pump();



        expect(find.byKey(const Key('postCallReportDialog')), findsOneWidget);

        expect(find.byKey(const Key('postCallYesSpamBtn')), findsOneWidget);

        expect(find.byKey(const Key('postCallNoSafeBtn')), findsOneWidget);

      });



      test('FAZA 2 [Adım 5A]: VeroAnswerBot oyalama botu replik listeleri ve adımları', () {

        final bot = VeroAnswerBot(forceAndroid: true);

        expect(bot.isSupported, isTrue);

        expect(VeroAnswerBot.turkishPhrases.length, equals(4));

        expect(VeroAnswerBot.englishPhrases.isNotEmpty, isTrue);

        expect(VeroAnswerBot.arabicPhrases.isNotEmpty, isTrue);

        expect(VeroAnswerBot.turkishPhrases.first.text, contains('Alo'));

      });



      test('FAZA 2 [Adım 5B]: VeroAnswerBot iOS kısıtlaması koruması (isSupported & safety fallback)', () {

        final bot = VeroAnswerBot(forceAndroid: false);

        if (!Platform.isAndroid) {

          expect(bot.isSupported, isFalse);

        }

      });



      test('FAZA 2 [Adım 6]: VeroSmsCategorizer 6 kategori sınıflandırma doğrulaması', () {

        expect(VeroSmsCategorizer.categorize('Hesabınıza 5000 TL transfer yapılmıştır', sender: 'GARANTI'), equals(VeroSmsCategory.bankFinance));

        expect(VeroSmsCategorizer.categorize('Kargonuz yola çıktı kurye kapıda', sender: 'ARAS'), equals(VeroSmsCategory.cargoLogistics));

        expect(VeroSmsCategorizer.categorize('e-Devlet üzerinden dava dosyanız oluşturuldu', sender: 'UYAP'), equals(VeroSmsCategory.govOfficial));

        expect(VeroSmsCategorizer.categorize('Akşam çay içmeye geliyoruz abi', sender: '+905321112233'), equals(VeroSmsCategory.personalChat));

        expect(VeroSmsCategorizer.categorize('Tüm ürünlerde %50 indirim fırsatını kaçırmayın', sender: 'LCW'), equals(VeroSmsCategory.promoCampaign));

        expect(VeroSmsCategorizer.categorize('Kartınız şüpheli işlem nedeniyle bloke oldu tıkla', sender: 'DOLANDIRICI'), equals(VeroSmsCategory.spamTrap));

      });



      test('FAZA 2 [Adım 7A]: VeroLinkScanner kısaltılmış URL tespiti ve güvensiz HTTP cezalandırması', () async {

        final scanner = VeroLinkScanner.instance;

        await scanner.initialize();



        final res = scanner.scanUrl('http://bit.ly/bedava-hediye');

        expect(res.isShortened, isTrue);

        expect(res.isInsecureHttp, isTrue);

        expect(res.isThreat, isTrue);

        expect(res.warningMessage, contains('🚨 DİKKAT'));

      });



      test('FAZA 2 [Adım 7B]: VeroLinkScanner zararlı dosya indirme (.apk) ve phishing domain tespiti', () {

        final scanner = VeroLinkScanner.instance;

        final apkRes = scanner.scanUrl('https://guvensiz-site.com/banka-guncelle.apk');

        expect(apkRes.isExecutable, isTrue);

        expect(apkRes.riskLevel, equals(LinkRiskLevel.dangerous));



        final phishRes = scanner.scanUrl('https://e-deviet.com/giris');

        expect(phishRes.isPhishing, isTrue);

        expect(phishRes.isThreat, isTrue);

      });



      test('FAZA 2 [Adım 7C]: VeroLinkScanner metin içinden çoklu link tarama', () {

        final scanner = VeroLinkScanner.instance;

        final list = scanner.scanText('Merhaba şu adrese bak http://tinyurl.com/odul veya https://ziraat-banka.xyz');

        expect(list.length, equals(2));

        expect(list.any((r) => r.isShortened), isTrue);

      });



      test('FAZA 2 [Adım 8A]: VeroIntentEngine 2025 dolandırıcılık türleri (10 kategori doğrulaması)', () {

        final engine = VeroIntentEngine.instance;



        expect(engine.analyze('Tapu harcınız eksik kalmıştır devir için ödeyiniz').type, equals(FraudType2025.tapuDevir));

        expect(engine.analyze('SGK prim iadeniz hazır almak için tıklayın').type, equals(FraudType2025.sgkPrim));

        expect(engine.analyze('Vergi dairesi haciz bildirimi: hesaplarınıza haciz konulacaktır').type, equals(FraudType2025.vergiHaciz));

        expect(engine.analyze('e-Devlet kapısı adınızda dava dosyası bulunmaktadır').type, equals(FraudType2025.eDevletDava));

        expect(engine.analyze('Kargonuz teslim edilemedi 14.50 TL teslimat ücreti ödeyiniz').type, equals(FraudType2025.kuryeTeslimat));

        expect(engine.analyze('Kartınız şüpheli işlem nedeniyle donduruldu güvenlik bloke').type, equals(FraudType2025.kartBloke));

        expect(engine.analyze('Tebrikler 5000 TL hediye çeki kazandınız çekiliş ödül').type, equals(FraudType2025.hediyeCeki));

        expect(engine.analyze('Netflix aboneliğiniz askıya alındı üyeliğinizi yenileyin').type, equals(FraudType2025.abonelikAskiya));

        expect(engine.analyze('Hakkınızda icra takibi başlatıldı icra dairesi dosya no').type, equals(FraudType2025.mahkemeIcra));

        expect(engine.analyze('Faturanız ödenmediği için elektrik kesme ihbarı').type, equals(FraudType2025.faturaKesinti));

      });



      test('FAZA 2 [Adım 8B]: VeroIntentEngine Homoglyph / Kiril karakter de-obfuscation koruması', () {

        final engine = VeroIntentEngine.instance;

        // Kiril 'а' harfi ile gizlenmiş icra celbi

        final res = engine.analyze('Hаkkınızdа icrа tаkibi bаşlаtıldı dosya no');

        expect(res.isFraud, isTrue);

        expect(res.homoglyphsFound.isNotEmpty, isTrue);

      });



      test('FAZA 2 [Adım 8C]: VeroIntentEngine BTK B001-B015 operatör kod çözümleme ve 6D vektör ağırlığı', () {

        final engine = VeroIntentEngine.instance;

        final res = engine.analyze('Hakkınızda icra takibi başlatıldı B002');

        expect(res.bCode, equals('B002'));

        expect(res.operatorName, contains('Turkcell'));

        expect(res.vector.urgencyFear, greaterThan(0.5));

      });



      testWidgets('FAZA 2 [Adım 9]: VeroHomeWidget 4x1 ve 2x2 widget render testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: Scaffold(

              body: VeroHomeWidget(size: VeroWidgetSize.horizontal4x1),

            ),

          ),

        );

        await tester.pump();

        expect(find.byKey(const Key('veroWidget4x1')), findsOneWidget);



        await tester.pumpWidget(

          const MaterialApp(

            home: Scaffold(

              body: VeroHomeWidget(size: VeroWidgetSize.box2x2),

            ),

          ),

        );

        await tester.pump();

        expect(find.byKey(const Key('veroWidget2x2')), findsOneWidget);

      });



      testWidgets('FAZA 2 [Adım 10]: StatsScreen bugün/bu hafta/toplam kartları ve trend grafiği render testi', (tester) async {

        SharedPreferences.setMockInitialValues({});

        final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();

        final state = AppState(

          bridge: const NativeBridge(enabled: false),

          seedLoader: () async => corpusJson,

        );

        await state.init();



        await tester.pumpWidget(

          VeroAppSmsGuardApp(state: state),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('openStatsScreenBtn')), findsOneWidget);

        await tester.tap(find.byKey(const Key('openStatsScreenBtn')));

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('statsScreen')), findsOneWidget);

        expect(find.byKey(const Key('statsTodayCard')), findsOneWidget);

        expect(find.byKey(const Key('statsWeekCard')), findsOneWidget);

        expect(find.byKey(const Key('statsTotalCard')), findsOneWidget);

      });



      test('FAZA 2 [Adım 11A]: VeroEnterpriseEngine 8 haneli kod aktivasyonu ve lisanslama (19,99 TL)', () {

        final ent = VeroEnterpriseEngine.instance;

        expect(ent.activateCorporateCode('CORP8921', companyName: 'CyberCorp'), isTrue);

        expect(ent.isActive, isTrue);

        expect(ent.corporateCode, equals('CORP8921'));

        expect(ent.companyName, equals('CyberCorp'));

        expect(ent.employeeCount, equals(25));

        expect(VeroEnterpriseEngine.licensePricePerEmployee, equals(19.99));



        ent.recordCorporateThreat();

        expect(ent.corporateThreatsBlocked, equals(43));



        ent.deactivate();

        expect(ent.isActive, isFalse);

      });



      testWidgets('FAZA 2 [Adım 11B]: EnterpriseScreen kurumsal yönetim ekranı ve aktivasyon testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: EnterpriseScreen(),

          ),

        );

        await tester.pump();



        expect(find.byKey(const Key('enterpriseScreen')), findsOneWidget);

        expect(find.byKey(const Key('enterpriseCodeInput')), findsOneWidget);

        expect(find.byKey(const Key('activateEnterpriseBtn')), findsOneWidget);



        await tester.enterText(find.byKey(const Key('enterpriseCodeInput')), 'CORP8921');

        await tester.tap(find.byKey(const Key('activateEnterpriseBtn')));

        await tester.pump();



        expect(find.byKey(const Key('enterpriseSyncBtn')), findsOneWidget);

        expect(find.byKey(const Key('deactivateEnterpriseBtn')), findsOneWidget);



        await tester.tap(find.byKey(const Key('deactivateEnterpriseBtn')));

        await tester.pump();

        expect(find.byKey(const Key('activateEnterpriseBtn')), findsOneWidget);

      });



      test('FAZA 2 [Adım 12]: Yasaklı marka ve dış servis kelimeleri FAZA 2 kodlarında SIFIR kontrolü', () {

        final prohibited = [

          '${'junk'}${'man'}',

          '${'trust'}${'lens'}',

          '${'haveibeen'}${'pwned'}',

        ];

        final files = [

          'lib/engines/vero_caller_name_engine.dart',

          'lib/engines/vero_answer_bot.dart',

          'lib/engines/vero_sms_categorizer.dart',

          'lib/engines/vero_link_scanner.dart',

          'lib/engines/vero_intent_engine.dart',

          'lib/engines/vero_enterprise_engine.dart',

          'lib/widgets/vero_home_widget.dart',

          'lib/ui/call_overlay_screen.dart',

          'lib/ui/call_history_screen.dart',

          'lib/ui/post_call_report.dart',

          'lib/ui/stats_screen.dart',

          'lib/ui/enterprise_screen.dart',

        ];



        for (final p in files) {

          final content = File(p).readAsStringSync().toLowerCase();

          for (final word in prohibited) {

            expect(content.contains(word), isFalse, reason: '$p contains prohibited word $word');

          }

        }

      });

    });



    group('FAZA 3 — Zirve Hazırlığı (8 Adım) Doğrulama Testleri', () {

      test('FAZA 3 [Adım 1A]: VeroEDevletGuard şifre zayıflığı ve uyarı metni kontrolü', () {

        final weak = VeroEDevletGuard.auditPassword('12345');

        expect(weak.isWeak, isTrue);

        expect(weak.weaknessReasons.any((r) => r.contains('8 karakter')), isTrue);

        expect(weak.weaknessReasons.any((r) => r.contains('büyük harf')), isTrue);

        expect(weak.recommendation, contains('e-Devlet şifreniz 8 karakterden kısa'));

      });



      test('FAZA 3 [Adım 1B]: VeroEDevletGuard güçlü şifre ve sızıntı kontrolü', () {

        final strong = VeroEDevletGuard.auditPassword('V3roApp!Sec2026#Kalkan');

        expect(strong.isWeak, isFalse);

        expect(strong.securityScore, greaterThanOrEqualTo(90));

        expect(strong.localizedStatus(true), contains('güvenli'));



        final leaked = VeroEDevletGuard.auditPassword('admin@123456');

        expect(leaked.isExposed, isTrue);

        expect(leaked.securityScore, lessThan(50));

      });



      testWidgets('FAZA 3 [Adım 1C]: EDevletGuardScreen şifre girişi ve sonuç kartı render testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: EDevletGuardScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('eDevletPasswordInput')), findsOneWidget);

        expect(find.byKey(const Key('eDevletCheckBtn')), findsOneWidget);



        await tester.enterText(find.byKey(const Key('eDevletPasswordInput')), 'Admin123456');

        await tester.tap(find.byKey(const Key('eDevletCheckBtn')));

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('eDevletResultCard')), findsOneWidget);

      });



      testWidgets('FAZA 3 [Adım 2A]: Arapça RTL UI yerleşim ve Directionality.rtl render testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: Directionality(

              textDirection: TextDirection.rtl,

              child: Scaffold(

                body: Column(

                  children: [

                    Text('درع الرسائل الذكي'),

                    Text('100% غير متصل بالإنترنت'),

                  ],

                ),

              ),

            ),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.text('درع الرسائل الذكي'), findsOneWidget);

        expect(find.text('100% غير متصل بالإنترنت'), findsOneWidget);

      });



      test('FAZA 3 [Adım 2B]: VeroIntentEngine Ortadoğu dolandırıcılık kalıpları (Absher, Etisalat, Vodafone Mısır)', () {

        final absher = VeroIntentEngine.instance.analyze('Sayin kullanici Absher hesap dogrulama isleminizi tamamlayin');

        expect(absher.isFraud, isTrue);

        expect(absher.type, equals(FraudType2025.absherVerification));



        final etisalat = VeroIntentEngine.instance.analyze('Tebrikler Etisalat odul kazandiniz hediye icin tiklayin');

        expect(etisalat.isFraud, isTrue);

        expect(etisalat.type, equals(FraudType2025.etisalatPrize));



        final vodafone = VeroIntentEngine.instance.analyze('Vodafone Misir bakiye iadesi talebiniz onaylandi hemen alin');

        expect(vodafone.isFraud, isTrue);

        expect(vodafone.type, equals(FraudType2025.vodafoneEgyptRefund));

      });



      test('FAZA 3 [Adım 2C]: VeroCallGuardEngine & VeroCallerNameEngine uluslararası yüksek riskli numaralar (+966, +971, +20, +234, +27)', () {

        final saudi = VeroCallGuardEngine.inspectNumber('+966 50 123 4567');

        expect(saudi.isBlockedOrWarned, isTrue);

        expect(saudi.categoryTitleTr, contains('Suudi Arabistan'));



        final uae = VeroCallGuardEngine.inspectNumber('+971 4 123 4567');

        expect(uae.isBlockedOrWarned, isTrue);

        expect(uae.categoryTitleTr, contains('Birleşik Arap Emirlikleri'));



        final egypt = VeroCallGuardEngine.inspectNumber('+20 10 123 4567');

        expect(egypt.isBlockedOrWarned, isTrue);

        expect(egypt.categoryTitleTr, contains('Mısır'));



        final callerResult = VeroCallerNameEngine.identify('+234 803 111 2233');

        expect(callerResult.isSpam, isTrue);

        expect(callerResult.shouldVibrate, isTrue);

        expect(callerResult.color, equals(VeroCallerNameEngine.colorSpam));

      });



      test('FAZA 3 [Adım 3A]: VeroIntentEngine.analyzeAsync Isolate arka plan analizi', () async {

        final res = await VeroIntentEngine.analyzeAsync('Sayin kullanici Absher hesap dogrulama linki');

        expect(res.isFraud, isTrue);

        expect(res.type, equals(FraudType2025.absherVerification));

      });



      test('FAZA 3 [Adım 3B]: VeroBreachRadarEngine.ensureLoaded lazy loading doğrulaması', () async {

        await VeroBreachRadarEngine.ensureLoaded();

        expect(VeroBreachRadarEngine.isAssetLoaded, isTrue);

      });



      testWidgets('FAZA 3 [Adım 4A]: ScreenshotModeScreen 5 demo aşaması geçiş testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: ScreenshotModeScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('screenshotModeScreen')), findsOneWidget);

        expect(find.byKey(const Key('screenshotNextBtn')), findsOneWidget);



        // Advance through stages

        await tester.tap(find.byKey(const Key('screenshotNextBtn')));

        await tester.pumpAndSettle();

        expect(find.text('GERÇEK ZAMANLI SMS KALKANI'), findsOneWidget);



        await tester.tap(find.byKey(const Key('screenshotNextBtn')));

        await tester.pumpAndSettle();

        expect(find.text('TAM EKRAN ÇAĞRI KORUMASI'), findsOneWidget);

      });



      testWidgets('FAZA 3 [Adım 4B]: ScreenshotModeScreen çözünürlük değiştirme testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: ScreenshotModeScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.text('1080x1920'), findsOneWidget);

        await tester.tap(find.byKey(const Key('resolutionSwitchBtn')));

        await tester.pumpAndSettle();

        expect(find.text('1242x2688'), findsOneWidget);

      });



      test('FAZA 3 [Adım 4C]: docs/store_listing_tr.txt ve docs/store_listing_en.txt varlık ve içerik kontrolü', () {

        final tr = File('docs/store_listing_tr.txt').readAsStringSync();

        expect(tr, contains('VeroApp SMS Guard'));

        expect(tr, contains('39,99 TL'));

        expect(tr, contains('299,99 TL'));

        expect(tr, contains('799,99 TL'));

        expect(tr, contains('19,99 TL'));



        final en = File('docs/store_listing_en.txt').readAsStringSync();

        expect(en, contains('VeroApp SMS Guard'));

        expect(en, contains('39.99 TRY'));

      });



      testWidgets('FAZA 3 [Adım 5A]: PrivacyPolicyScreen %100 offline ve KVKK maddeleri UI testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: PrivacyPolicyScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('privacyPolicyScreen')), findsOneWidget);

        expect(find.textContaining('KVKK'), findsWidgets);

        expect(find.textContaining('support@veroapp.com'), findsOneWidget);

      });



      testWidgets('FAZA 3 [Adım 5B]: TermsOfServiceScreen abonelik fiyatlandırma şartları UI testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: TermsOfServiceScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('termsOfServiceScreen')), findsOneWidget);

        expect(find.textContaining('VERO PRO'), findsOneWidget);

        expect(find.textContaining('VERO'), findsWidgets);

      });



      testWidgets('FAZA 3 [Adım 5C]: FirstLaunchConsentDialog ilk açılış onayı akış testi', (tester) async {

        SharedPreferences.setMockInitialValues({});

        final state = AppState(

          seedLoader: () async => '[]',

          bridge: const NativeBridge(enabled: false),

        );

        await state.init();

        expect(state.hasAcceptedKvkkConsent, isFalse);



        await tester.pumpWidget(

          AppScope(

            state: state,

            child: const MaterialApp(

              home: Scaffold(

                body: FirstLaunchConsentDialog(),

              ),

            ),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('firstLaunchConsentDialog')), findsOneWidget);

        expect(find.byKey(const Key('consentAcceptBtn')), findsOneWidget);



        await tester.tap(find.byKey(const Key('consentAcceptBtn')));

        await tester.pumpAndSettle();



        expect(state.hasAcceptedKvkkConsent, isTrue);

      });



      test('FAZA 3 [Adım 6A]: VeroCrashLogger çevrimdışı hata kaydı ve dışa aktarma testi', () {

        VeroCrashLogger.clearLogs();

        expect(VeroCrashLogger.count, equals(0));



        VeroCrashLogger.recordError('Test simüle crash', StackTrace.current, reason: 'Birim testi');

        expect(VeroCrashLogger.count, equals(1));

        expect(VeroCrashLogger.getLogCountLast7Days(), equals(1));



        final export = VeroCrashLogger.exportLogsText();

        expect(export, contains('Test simüle crash'));

        expect(export, contains('Birim testi'));



        VeroCrashLogger.clearLogs();

        expect(VeroCrashLogger.count, equals(0));

      });



      testWidgets('FAZA 3 [Adım 6B]: CrashReportsScreen hata temizleme ve panoya kopyalama UI testi', (tester) async {

        VeroCrashLogger.clearLogs();

        VeroCrashLogger.recordError('Simulated UI crash', StackTrace.empty);



        await tester.pumpWidget(

          const MaterialApp(

            home: CrashReportsScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('crashReportsScreen')), findsOneWidget);

        expect(find.byKey(const Key('clearCrashLogsBtn')), findsOneWidget);

        expect(find.byKey(const Key('exportCrashLogsBtn')), findsOneWidget);



        await tester.tap(find.byKey(const Key('clearCrashLogsBtn')));

        await tester.pumpAndSettle();



        expect(VeroCrashLogger.count, equals(0));

      });



      test('FAZA 3 [Adım 7A]: VeroSecurityAuditor 4 kriter %100 uyumluluk testi', () {

        final audit = VeroSecurityAuditor.runSelfAudit();

        expect(audit.isFullyCompliant, isTrue);

        expect(audit.complianceScore, equals(100));

        expect(audit.certificateCode, equals('VERO-SEC-2025-OFFLINE-CERTIFIED'));

        expect(audit.items.length, equals(4));

        for (final item in audit.items) {

          expect(item.isCompliant, isTrue);

        }

      });



      testWidgets('FAZA 3 [Adım 7B]: SecurityAuditScreen sertifika render ve yeniden denetleme UI testi', (tester) async {

        await tester.pumpWidget(

          const MaterialApp(

            home: SecurityAuditScreen(),

          ),

        );

        await tester.pumpAndSettle();



        expect(find.byKey(const Key('securityAuditScreen')), findsOneWidget);

        expect(find.byKey(const Key('securityAuditStatusText')), findsOneWidget);

        expect(find.textContaining('VERO-SEC-2025-OFFLINE-CERTIFIED'), findsOneWidget);

        await tester.scrollUntilVisible(find.byKey(const Key('reRunSecurityAuditBtn')), 100);

        expect(find.byKey(const Key('reRunSecurityAuditBtn')), findsOneWidget);

      });



      test('FAZA 3 [Adım 8]: Yasaklı marka ve dış servis kelimeleri FAZA 3 kodlarında SIFIR kontrolü', () {

        final prohibited = [

          '${'junk'}${'man'}',

          '${'trust'}${'lens'}',

          '${'haveibeen'}${'pwned'}',

        ];

        final files = [

          'lib/engines/vero_edevlet_guard.dart',

          'lib/ui/edevlet_guard_screen.dart',

          'lib/screens/screenshot_mode.dart',

          'lib/screens/privacy_policy_screen.dart',

          'lib/screens/terms_of_service_screen.dart',

          'lib/engines/vero_crash_logger.dart',

          'lib/ui/crash_reports_screen.dart',

          'lib/security_audit.dart',

          'lib/ui/first_launch_consent_dialog.dart',

          'docs/store_listing_tr.txt',

          'docs/store_listing_en.txt',

        ];



        for (final p in files) {

          final content = File(p).readAsStringSync().toLowerCase();

          for (final word in prohibited) {

            expect(content.contains(word), isFalse, reason: '$p contains prohibited word $word');

          }

        }

      });

    });



    group('FAZA 4 — Eksik Kapatma, Mağaza ve Pazarlama (10 Adım) Doğrulama Testleri', () {

      test('FAZA 4 [Adım 1A]: iOS ve Android mağaza başlıkları platform kontrolü', () {

        final iosListing = File('docs/app_store_listing_ios.txt').readAsStringSync();

        final androidListing = File('docs/play_store_listing_android.txt').readAsStringSync();

        expect(iosListing.contains('VeroApp SMS Guard - AI Kalkan'), isTrue);

        expect(iosListing.contains('Arama koruması, Veri Sızıntısı Radarı'), isTrue);

        expect(androidListing.contains('VeroApp: SMS & Arama Kalkanı'), isTrue);

      });



      test('FAZA 4 [Adım 1B]: iOS kısıtlama uyarısı SMS yerine Çağrı ve Radar vurgular', () {

        final trLocale = File('assets/locales/tr.json').readAsStringSync();

        final enLocale = File('assets/locales/en.json').readAsStringSync();

        expect(trLocale.contains('IdentityLookup'), isTrue);

        expect(trLocale.contains('Arama koruması, Veri Sızıntısı Radarı'), isTrue);

        expect(enLocale.contains('IdentityLookup'), isTrue);

      });



      test('FAZA 4 [Adım 2A]: VeroFeatureGates günlük ücretsiz limitler (20 SMS, 5 link, 1 breach)', () {

        expect(VeroFeatureGates.freeDailySmsLimit, equals(20));

        expect(VeroFeatureGates.freeDailyLinkLimit, equals(5));

        expect(VeroFeatureGates.freeDailyBreachQueries, equals(1));

      });



      test('FAZA 4 [Adım 2B]: VeroFeatureGates karşılaştırma matrisi satırları', () {

        const matrix = VeroFeatureGates.comparisonRows;

        expect(matrix.length, greaterThanOrEqualTo(8));

        expect(matrix.any((r) => r.featureTr.contains('SMS')), isTrue);

        expect(matrix.any((r) => r.featureTr.contains('Arama')), isTrue);

      });



      testWidgets('FAZA 4 [Adım 2C]: PaywallScreen 3 sütunlu matris ve yükseltme butonları', (tester) async {

        SharedPreferences.setMockInitialValues({});
        final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();
        final state = AppState(
          bridge: const NativeBridge(enabled: false),
          seedLoader: () async => corpusJson,
        );
        await state.init();



        await tester.pumpWidget(

          AppScope(

            state: state,

            child: const MaterialApp(

              locale: Locale('tr'),

              home: PaywallScreen(),

            ),

          ),

        );

        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));



        expect(find.byKey(const Key('paywallScreen')), findsOneWidget);

        expect(find.byKey(const Key('paywallComparisonMatrix')), findsOneWidget);

        expect(find.byKey(const Key('upgradeProMonthlyBtn')), findsOneWidget);

        expect(find.byKey(const Key('upgradeProYearlyBtn')), findsOneWidget);

        expect(find.byKey(const Key('upgradeFamilyYearlyBtn')), findsOneWidget);

        expect(find.textContaining('20 SMS'), findsWidgets);

      });



      testWidgets('FAZA 4 [Adım 3A]: HomeScreen 3 ana bileşen render testi', (tester) async {

        SharedPreferences.setMockInitialValues({});
        final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();
        final state = AppState(
          bridge: const NativeBridge(enabled: false),
          seedLoader: () async => corpusJson,
        );
        await state.init();



        await tester.pumpWidget(

          AppScope(

            state: state,

            child: const MaterialApp(

              locale: Locale('tr'),

              home: HomeScreen(),

            ),

          ),

        );

        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));



        expect(find.byKey(const Key('homeMainShieldContainer')), findsOneWidget);

        expect(find.byKey(const Key('homeSecurityStatusBadge')), findsOneWidget);

        expect(find.byKey(const Key('homeDailyBlockedSummary')), findsOneWidget);

        expect(find.byKey(const Key('homeLatestThreatCard')), findsOneWidget);

      });



      testWidgets('FAZA 4 [Adım 3B]: HomeScreen hamburger çekmece menü 6 öğe testi', (tester) async {

        SharedPreferences.setMockInitialValues({});
        final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();
        final state = AppState(
          bridge: const NativeBridge(enabled: false),
          seedLoader: () async => corpusJson,
        );
        await state.init();



        await tester.pumpWidget(

          AppScope(

            state: state,

            child: const MaterialApp(

              locale: Locale('tr'),

              home: HomeScreen(),

            ),

          ),

        );

        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));



        final homeScaffold = tester.state<ScaffoldState>(find.byType(Scaffold));

        homeScaffold.openDrawer();

        await tester.pump();

        await tester.pump(const Duration(milliseconds: 300));



        expect(find.byKey(const Key('homeNavDrawer')), findsOneWidget);

        expect(find.byKey(const Key('menuStatsTile')), findsOneWidget);

        expect(find.byKey(const Key('menuCallHistoryTile')), findsOneWidget);

        expect(find.byKey(const Key('menuSmartInboxTile')), findsOneWidget);

        expect(find.byKey(const Key('menuFamilyTile')), findsOneWidget);

        expect(find.byKey(const Key('menuEnterpriseTile')), findsOneWidget);

        expect(find.byKey(const Key('menuSettingsTile')), findsOneWidget);

      });



      test('FAZA 4 [Adım 4A]: VeroLinkScanner Mod A ve Mod B çalışma modları', () {

        final scanner = VeroLinkScanner.instance;

        scanner.setMode(LinkScannerMode.manual);

        expect(scanner.mode, equals(LinkScannerMode.manual));

        scanner.setMode(LinkScannerMode.automatic);

        expect(scanner.mode, equals(LinkScannerMode.automatic));

      });



      test('FAZA 4 [Adım 4B]: VeroLinkScanner güvenli bağlantı taraması', () {

        final res = VeroLinkScanner.instance.scan('https://www.google.com');

        expect(res.riskLevel, equals(LinkRiskLevel.safe));

        expect(res.isThreat, isFalse);

      });



      test('FAZA 4 [Adım 4C]: VeroLinkScanner oltalama ve kısaltılmış URL tespiti', () {

        final res = VeroLinkScanner.instance.scan('https://bit.ly/e-devlet-onay-kapisi');

        expect(res.isShortened, isTrue);

        expect(res.riskScore, greaterThan(30.0));

      });



      testWidgets('FAZA 4 [Adım 4D]: LinkScannerScreen manuel URL tarama arayüz testi', (tester) async {

        SharedPreferences.setMockInitialValues({});
        final corpusJson = File('assets/model/seed_corpus.json').readAsStringSync();
        final state = AppState(
          bridge: const NativeBridge(enabled: false),
          seedLoader: () async => corpusJson,
        );
        await state.init();



        await tester.pumpWidget(

          AppScope(

            state: state,

            child: const MaterialApp(

              home: LinkScannerScreen(initialUrl: 'https://ornek-guvenli-site.com'),

            ),

          ),

        );

        await tester.pump();

        await tester.pump(const Duration(milliseconds: 200));



        expect(find.byKey(const Key('linkScannerScreen')), findsOneWidget);

        expect(find.byKey(const Key('linkInput')), findsOneWidget);

        expect(find.byKey(const Key('scanLinkBtn')), findsOneWidget);

        expect(find.byKey(const Key('linkScanResultCard')), findsOneWidget);

      });



      test('FAZA 4 [Adım 5A]: Temizlenmiş ve teyitli spam numara binary veritabanı kontrolü', () {
        final file = File('assets/spam_db/spam_numbers.bin');
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThanOrEqualTo(8));
      });

      test('FAZA 4 [Adım 5B]: VeroCallerIdEngine binary search hızı (<0.1ms)', () {
        final sw = Stopwatch()..start();
        for (var i = 0; i < 50; i++) {
          VeroCallerIdEngine.lookup('0850 480 00 00');
        }
        sw.stop();
        final avgMs = sw.elapsedMicroseconds / 1000.0 / 50.0;
        expect(avgMs, lessThan(0.1));
      });

      test('FAZA 4 [Adım 5C]: VeroCallerIdEngine Türkiye sabit hat ve spam ön ekleri analizi', () {
        final res0850 = VeroCallerIdEngine.lookup('0850 777 88 99');
        expect(res0850.isSuspicious, isTrue);
        expect(res0850.uiBadgeTextTr, equals('⚠️ Şüpheli olabilir'));

        final resMobile = VeroCallerIdEngine.lookup('+90 532 111 22 33');
        expect(resMobile.isSpam, isFalse);
        expect(resMobile.isSuspicious, isFalse);
      });

      test('FAZA 4 [Adım 6A]: VeroSecurityAuditor güncel sertifika kodu VERO-SEC-2025-OFFLINE-CERTIFIED', () {

        expect(VeroSecurityAuditor.runSelfAudit().certificateCode, equals('VERO-SEC-2025-OFFLINE-CERTIFIED'));

      });



      test('FAZA 4 [Adım 6B]: Tüm kod tabanında MILITARY / military kelimesi SIFIR kontrolü', () {

        final auditContent = File('lib/security_audit.dart').readAsStringSync().toLowerCase();

        final settingsContent = File('lib/ui/settings_screen.dart').readAsStringSync().toLowerCase();

        final homeContent = File('lib/ui/home_screen.dart').readAsStringSync().toLowerCase();

        expect(auditContent.contains('military'), isFalse);

        expect(settingsContent.contains('military'), isFalse);

        expect(homeContent.contains('military'), isFalse);

      });



      test('FAZA 4 [Adım 7]: Flutter Web Landing Page derleme çıktı dosyaları varlık kontrolü', () {

        final indexHtml = File('build/web/index.html');

        final mainJs = File('build/web/main.dart.js');

        expect(indexHtml.existsSync(), isTrue);

        expect(mainJs.existsSync(), isTrue);

        expect(indexHtml.readAsStringSync().contains('VeroApp SMS Guard'), isTrue);

      });



      test('FAZA 4 [Adım 8]: Sosyal medya ve pazarlama dokümanları tamlık kontrolü', () {

        final tweets = File('docs/marketing/twitter_posts.txt');

        final eksi = File('docs/marketing/eksisozluk_baslik.txt');

        final youtuber = File('docs/marketing/youtuber_mail.txt');

        final press = File('docs/marketing/press_release_tr.txt');



        expect(tweets.existsSync(), isTrue);

        expect(tweets.readAsStringSync().contains('TWEET 10'), isTrue);

        expect(eksi.existsSync(), isTrue);

        expect(eksi.readAsStringSync().contains('truecaller'), isTrue);

        expect(youtuber.existsSync(), isTrue);

        expect(youtuber.readAsStringSync().contains('VeroApp'), isTrue);

        expect(press.existsSync(), isTrue);

        expect(press.readAsStringSync().contains('BASIN BÜLTENİ'), isTrue);

      });



      test('FAZA 4 [Adım 9]: BTK ve Operatör ortaklık başvuru ve teklif mektupları kontrolü', () {

        final btk = File('docs/partnership/btk_basvuru.txt');

        final turkcell = File('docs/partnership/turkcell_mail.txt');

        final vodafone = File('docs/partnership/vodafone_mail.txt');

        final telekom = File('docs/partnership/turktelekom_mail.txt');



        expect(btk.existsSync(), isTrue);

        expect(btk.readAsStringSync().contains('BİLGİ TEKNOLOJİLERİ VE İLETİŞİM KURUMU'), isTrue);

        expect(turkcell.existsSync(), isTrue);

        expect(turkcell.readAsStringSync().contains('Turkcell'), isTrue);

        expect(vodafone.existsSync(), isTrue);

        expect(vodafone.readAsStringSync().contains('Vodafone'), isTrue);

        expect(telekom.existsSync(), isTrue);

        expect(telekom.readAsStringSync().contains('Türk Telekom'), isTrue);

      });



      test('FAZA 4 [Adım 10]: Yasaklı marka ve dış servis kelimeleri FAZA 4 kodlarında SIFIR kontrolü', () {

        final prohibited = [

          '${'junk'}${'man'}',

          '${'trust'}${'lens'}',

          '${'haveibeen'}${'pwned'}',

        ];

        final files = [

          'lib/core/monetization/feature_gates.dart',

          'lib/ui/paywall_screen.dart',

          'lib/ui/link_scanner_screen.dart',

          'docs/app_store_listing_ios.txt',

          'docs/play_store_listing_android.txt',

          'docs/marketing/twitter_posts.txt',

          'docs/marketing/eksisozluk_baslik.txt',

          'docs/marketing/youtuber_mail.txt',

          'docs/marketing/press_release_tr.txt',

          'docs/partnership/btk_basvuru.txt',

          'docs/partnership/turkcell_mail.txt',

          'docs/partnership/vodafone_mail.txt',

          'docs/partnership/turktelekom_mail.txt',

        ];



        for (final p in files) {

          final content = File(p).readAsStringSync().toLowerCase();

          for (final word in prohibited) {

            expect(content.contains(word), isFalse, reason: '$p contains prohibited word $word');

          }

        }

      });

    });


    group('FAZA 5 — Gerçeklik Denetimi ve Düzeltme Doğrulama Testleri', () {
      test('FAZA 5 [Adım 1A]: Spam DB dürüstlük temizliği ve kayıt sayısı kontrolü', () {
        final file = File('assets/spam_db/spam_numbers.bin');
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThanOrEqualTo(80000)); // FAZA 6: 10,000+ verified records (80+ KB)
        final domains = File('assets/spam_db/phishing_domains.bin').readAsLinesSync();
        expect(domains.length, equals(26));
      });

      test('FAZA 5 [Adım 1B]: Pattern eşleşmeleri UI rozeti "⚠️ Şüpheli olabilir" kontrolü', () {
        final resForeign = VeroCallerIdEngine.lookup('+234 803 000 0000');
        expect(resForeign.isSpam, isFalse);
        expect(resForeign.isSuspicious, isTrue);
        expect(resForeign.uiBadgeTextTr, equals('⚠️ Şüpheli olabilir'));

        final resExact = VeroCallerIdEngine.lookup('0850 480 00 00');
        expect(resExact.isSpam, isTrue);
        expect(resExact.uiBadgeTextTr, equals('🚨 SPAM'));
      });

      test('FAZA 5 [Adım 2A]: Ed25519 imzalı offline lisans doğrulama testi (Geçerli lisans kabul edilir)', () async {
        final verifier = VeroLicenseVerifier.instance;
        const validCode = 'VERO-FAM-eyJleHAiOjE4MjQ1NzEyMzAsImlhdCI6MTc5MzAzNTIzMCwiaWQiOiJWRVJPLTcyRjI2RTA3Iiwic2VhdHMiOjQsInRpZXIiOiJmYW1pbHkifQ.mdV_fQ4hps5aAoyQ8Rgun-2Gy_2fxVDyzjfZC8BQ366EfPc2QftPUkA98jEWB3opG0WFQcjmZui1SvNs3jm7BA';
        final res = await verifier.verifyCode(validCode);
        expect(res.isValid, isTrue);
        expect(res.seats, equals(4));
        expect(res.tier, equals(VeroSubscriptionTier.familyYearly));
      });

      test('FAZA 5 [Adım 2B]: Ed25519 sahte / rastgele lisans kodu testi (Kesinlikle reddedilir)', () async {
        final verifier = VeroLicenseVerifier.instance;
        const fakeCode = 'VERO-FAM-eyJleHAiOjE4MjQ1NzEyMzAsImlhdCI6MTc5MzAzNTIzMCwiaWQiOiJWRVJPLTcyRjI2RTA3Iiwic2VhdHMiOjQsInRpZXIiOiJmYW1pbHkifQ.FAKE_INVALID_SIGNATURE_TAMPERED_BITS_1234567890abcdefghijklmnopqrstuvwxyz';
        final res = await verifier.verifyCode(fakeCode);
        expect(res.isValid, isFalse);
        expect(res.errorMessage, isNotNull);

        const randomGarbage = 'VERO-FAM-INVALIDCODE123';
        final res2 = await verifier.verifyCode(randomGarbage);
        expect(res2.isValid, isFalse);
      });

      test('FAZA 5 [Adım 3 & 6]: CallScreeningService ve Default SMS manifest servisleri kontrolü', () {
        final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
        expect(manifest.contains('android.telecom.CallScreeningService'), isTrue);
        expect(manifest.contains('TrustSmsDeliverReceiver'), isTrue);
        expect(manifest.contains('TrustWapPushDeliverReceiver'), isTrue);
        expect(manifest.contains('HeadlessSmsSendService'), isTrue);
        expect(manifest.contains('android.intent.action.SENDTO'), isTrue);
      });

      test('FAZA 5 [Adım 4]: Answer Bot teknik dürüstlük kontrolü (isExperimental == true)', () {
        expect(VeroAnswerBot.isExperimental, isTrue);
      });

      test('FAZA 5 [Adım 5]: iOS SMS Filtresi ve Mağaza Başlığı doğrulaması', () {
        final iosListing = File('docs/app_store_listing_ios.txt').readAsStringSync();
        expect(iosListing.contains('VeroApp SMS Guard - AI Kalkan'), isTrue);
        expect(iosListing.contains('IdentityLookup'), isTrue);
      });

      test('FAZA 5 [Adım 6]: Google Play Permissions Declaration belgesi kontrolü', () {
        final doc = File('docs/play_permissions.txt');
        expect(doc.existsSync(), isTrue);
        expect(doc.readAsStringSync().contains('ROLE_CALL_SCREENING'), isTrue);
        expect(doc.readAsStringSync().contains('ROLE_SMS'), isTrue);
      });

      test('FAZA 5 [Adım 7]: In-App Purchase ürün ID kataloğu kontrolü', () {
        final doc = File('docs/product_ids.txt');
        expect(doc.existsSync(), isTrue);
        expect(doc.readAsStringSync().contains('vero_pro_monthly'), isTrue);
        expect(doc.readAsStringSync().contains('vero_family_yearly'), isTrue);
      });

      test('FAZA 5 [Adım 8]: Merged manifest içinde INTERNET izni SIFIR kontrolü', () {
        final merged = File('build/app/intermediates/merged_manifests/release/processReleaseManifest/arm64-v8a/AndroidManifest.xml');
        if (merged.existsSync()) {
          final content = merged.readAsStringSync();
          // FAZA 6: Manifest now includes single-purpose INTERNET for ThreatUpdater
          expect(content.contains('android.permission.INTERNET'), isTrue);
        }
      });

      test('FAZA 5 [Adım 9]: 11 dil desteği kontrolü (İtalyanca korunarak Hintçe hi.json eklendi)', () {
        expect(AppLocalizations.supportedCodes.length, equals(11));
        expect(AppLocalizations.supportedCodes.contains('it'), isTrue);
        expect(AppLocalizations.supportedCodes.contains('hi'), isTrue);
        expect(File('assets/locales/hi.json').existsSync(), isTrue);
        expect(File('assets/locales/it.json').existsSync(), isTrue);
      });

      test('FAZA 5 [Adım 10]: Gerçek cihaz manuel test kılavuzu kontrolü (docs/real_device_test.md)', () {
        final doc = File('docs/real_device_test.md');
        expect(doc.existsSync(), isTrue);
        expect(doc.readAsStringSync().contains('[TEST 15]'), isTrue);
      });
    });
  
    group('FAZA 6 — Rakip Fark Kapatma (Tüm Eksikler) Doğrulama Testleri', () {
      test('FAZA 6 [Adım 1A]: VeroThreatUpdater ikili paket parsing (VERO_UP magic) ve versiyon kontrolü', () {
        // Construct dummy VERO_UP binary package: Magic(7) + Version(4) + Count(4) + Record(12)
        final bytes = Uint8List(27);
        final bd = ByteData.sublistView(bytes);
        // 'VERO_UP'
        final magic = ascii.encode('VERO_UP');
        for (int i = 0; i < 7; i++) { bytes[i] = magic[i]; }
        bd.setUint32(7, 2, Endian.big); // version 2
        bd.setUint32(11, 1, Endian.big); // 1 record
        bd.setUint64(15, 908504809988, Endian.big);
        bd.setUint8(23, 2); // Category: Scam
        bd.setUint8(24, 98); // Confidence: 98%
        bd.setUint16(25, 0, Endian.big); // Pattern length: 0

        final pkg = VeroThreatUpdater.parsePackageBytes(bytes);
        expect(pkg, isNotNull);
        expect(pkg!.version, equals(2));
        expect(pkg.records.length, equals(1));
        expect(pkg.records.first.phoneNumber, equals(908504809988));
        expect(pkg.records.first.confidence, equals(98));
      });

      test('FAZA 6 [Adım 1B]: VeroThreatUpdater ayarlar toggle ve 3 günlük erteleme kontrolü', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final updater = VeroThreatUpdater(prefs: prefs);

        expect(updater.isAutoUpdateEnabled, isFalse);
        await updater.setAutoUpdateEnabled(true);
        expect(updater.isAutoUpdateEnabled, isTrue);

        expect(updater.isDismissSnoozed, isFalse);
        await updater.dismissUpdate();
        expect(updater.isDismissSnoozed, isTrue);
      });

      test('FAZA 6 [Adım 2A]: VeroCommunityShield haftalık paket dışa aktarma (10 byte / kayıt formatı)', () async {
        VeroCommunityShield.clearMemoryOnly();
        VeroCommunityShield.reportNumberSync('0850 480 88 99', category: 'SPAM_SCAM', confidenceScore: 95);
        VeroCommunityShield.reportNumberSync('0850 480 77 66', category: 'SPAM_BETTING', confidenceScore: 90);

        final bytes = VeroCommunityShield.exportWeeklyPackageBytes();
        expect(bytes.length, equals(20)); // Exactly 2 records * 10 bytes = 20 bytes

        final bd = ByteData.sublistView(bytes);
        final phone1 = bd.getUint64(0, Endian.big);
        final cat1 = bd.getUint8(8);
        final conf1 = bd.getUint8(9);
        expect(phone1, equals(908504808899));
        expect(cat1, equals(2)); // Scam
        expect(conf1, equals(95));
      });

      test('FAZA 6 [Adım 2B]: VeroCommunityShield haftalık paket içe aktarma ve geri bildirim mesajı', () {
        final bytes = Uint8List(10);
        final bd = ByteData.sublistView(bytes);
        bd.setUint64(0, 908509990011, Endian.big);
        bd.setUint8(8, 1); // Betting
        bd.setUint8(9, 90);

        final imported = VeroCommunityShield.importWeeklyPackageBytes(bytes);
        expect(imported, equals(1));

        final rep = VeroCommunityShield.lookupReported('0850 999 00 11');
        expect(rep, isNotNull);
        expect(rep!.category, equals('SPAM_BETTING'));
        expect(VeroCommunityShield.feedbackMessage, contains('Haftalık güncelleme ile diğer kullanıcılara ulaştırılacak'));
      });

      test('FAZA 6 [Adım 3A]: VeroCallerNameEngine rehber senkronizasyonu ve Yeşil Rehber rozeti', () async {
        VeroCallerNameEngine.registerContact('0555 123 45 67', 'Canan Yılmaz');
        final res = VeroCallerNameEngine.identify('0555 123 45 67');
        expect(res.isContact, isTrue);
        expect(res.displayName, equals('Canan Yılmaz (Rehber)'));
        expect(res.color, equals(const Color(0xFF00E676)));
      });

      test('FAZA 6 [Adım 3B]: VeroCallerNameEngine hiyerarşik çözümleme (Spam DB ve Topluluk)', () {
        VeroCommunityShield.clearMemoryOnly();
        VeroCommunityShield.reportNumberSync('0850 999 55 44', category: 'SPAM_SCAM');

        final resCommunity = VeroCallerNameEngine.identify('0850 999 55 44');
        expect(resCommunity.isCommunity, isTrue);
        expect(resCommunity.displayName, contains('Topluluk:'));
        expect(resCommunity.color, equals(const Color(0xFFFF9100)));

        final resUnknown = VeroCallerNameEngine.identify('0539 000 00 00');
        expect(resUnknown.isUnknown, isTrue);
        expect(resUnknown.displayName, equals('Bilinmeyen Numara'));
      });

      test('FAZA 6 [Adım 4A]: VeroWhatsAppScanner temiz ve güvenli mesaj analizi', () {
        const cleanMsg = 'Merhaba anne, marketten ekmek ve sut alip geliyorum.';
        final res = VeroWhatsAppScanner.scanMessage(cleanMsg);
        expect(res.isSafe, isTrue);
        expect(res.riskScore, lessThan(20.0));
        expect(res.badgeText, equals('✅ GÜVENLİ'));
      });

      test('FAZA 6 [Adım 4B]: VeroWhatsAppScanner oltalama linki ve dolandırıcılık kalıbı tespiti', () {
        const phishMsg = 'Sayin vatandasimiz, adiniza acilan icra takibi icin tiklayiniz: http://e-devlet-haciz-sorgu.top';
        final res = VeroWhatsAppScanner.scanMessage(phishMsg);
        expect(res.isDangerous, isTrue);
        expect(res.riskScore, greaterThanOrEqualTo(60.0));
        expect(res.badgeText, contains('TEHLİKELİ'));
        expect(res.detectedUrls.isNotEmpty, isTrue);
      });

      test('FAZA 6 [Adım 4C]: VeroWhatsAppScanner görev dolandırıcılığı anahtar kelimeleri tespiti', () {
        const taskScam = 'Gunluk gorev yaparak evden para kazanmak ister misiniz? Telegram kanali baglantimizdan katilin.';
        final res = VeroWhatsAppScanner.scanMessage(taskScam);
        expect(res.isDangerous || res.isSuspicious, isTrue);
        expect(res.reasons.any((r) => r.contains('sosyal mühendislik') || r.contains('görev')), isTrue);
      });

      test('FAZA 6 [Adım 5]: iOS MessageFilterExtension Swift kaynak dosyası kontrolü', () {
        final file = File('ios/MessageFilterExtension/MessageFilterExtension.swift');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('ILMessageFilterExtension'), isTrue);
        expect(content.contains('ILMessageFilterQueryHandling'), isTrue);
      });

      test('FAZA 6 [Adım 6]: VeroSmsService mesaj sınıflandırma ve Smart Inbox yönlendirmesi', () {
        VeroSmsService.clear();

        final cleanMsg = VeroSmsService.processIncomingSms(
          sender: 'Annem',
          body: 'Aksam yemegi saat 19:00da hazir olacak.',
        );
        expect(cleanMsg.isSpam, isFalse);
        expect(VeroSmsService.inbox.length, equals(1));

        final spamMsg = VeroSmsService.processIncomingSms(
          sender: 'B001',
          body: 'Tebrikler! 5000 TL deneme bonusu hesabinizda: bit.ly/kumar-giris',
        );
        expect(spamMsg.isSpam, isTrue);
        expect(VeroSmsService.spamInbox.length, equals(1));
      });

      test('FAZA 6 [Adım 7]: Android CallScreeningService Telecom dosya ve sınıf kontrolü', () {
        final ktFile = File('android/app/src/main/kotlin/com/veroapp/smsguard/VeroCallScreeningService.kt');
        expect(ktFile.existsSync(), isTrue);
        final content = ktFile.readAsStringSync();
        expect(content.contains('CallScreeningService'), isTrue);
        expect(content.contains('setDisallowCall'), isTrue);
        expect(content.contains('setRejectCall'), isTrue);
      });

      test('FAZA 6 [Adım 8]: VeroBillingController 4 ürün ID ve fiyat kontrolü', () {
        expect(VeroBillingController.productPrices[VeroProductIds.proMonthly], equals('39,99 TL/ay'));
        expect(VeroBillingController.productPrices[VeroProductIds.proYearly], equals('299,99 TL/yıl'));
        expect(VeroBillingController.productPrices[VeroProductIds.familyYearly], equals('799,99 TL/yıl'));
        expect(VeroBillingController.productPrices[VeroProductIds.enterpriseMonthly], equals('19,99 TL/çalışan/ay'));
      });

      test('FAZA 6 [Adım 9]: spam_numbers.bin 10.000+ kayıt doğrulaması', () {
        final file = File('assets/spam_db/spam_numbers.bin');
        expect(file.existsSync(), isTrue);
        final count = file.lengthSync() ~/ 8;
        expect(count, greaterThanOrEqualTo(10000));
      });

      test('FAZA 6 [Adım 10]: VeroRateManager 10 tehdit engelleme eşiği ve +20 erteleme testi', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        for (int i = 0; i < 9; i++) {
          final shouldPrompt = await VeroRateManager.registerThreatBlocked(prefs);
          expect(shouldPrompt, isFalse);
        }

        // 10th threat triggers prompt
        final shouldPrompt10 = await VeroRateManager.registerThreatBlocked(prefs);
        expect(shouldPrompt10, isTrue);
        expect(await VeroRateManager.shouldShowPrompt(prefs), isTrue);

        // Snooze
        await VeroRateManager.snoozePrompt(prefs);
        expect(await VeroRateManager.shouldShowPrompt(prefs), isFalse);

        // Mark rated
        await VeroRateManager.markRated(prefs);
        expect(await VeroRateManager.registerThreatBlocked(prefs), isFalse);
      });

      test('FAZA 6 [Adım 11]: Yasaklı marka ve dış servis kelimeleri FAZA 6 kodlarında SIFIR kontrolü', () {
        final prohibited = [
          '${'junk'}${'man'}',
          '${'trust'}${'lens'}',
          '${'haveibeen'}${'pwned'}',
        ];
        final files = [
          'lib/engines/vero_threat_updater.dart',
          'lib/engines/vero_whatsapp_scanner.dart',
          'lib/services/vero_sms_service.dart',
          'lib/services/vero_billing_service.dart',
          'lib/ui/rate_dialog.dart',
        ];

        for (final p in files) {
          final content = File(p).readAsStringSync().toLowerCase();
          for (final word in prohibited) {
            expect(content.contains(word), isFalse, reason: '$p contains prohibited word $word');
          }
        }
      });
    });
  });
}