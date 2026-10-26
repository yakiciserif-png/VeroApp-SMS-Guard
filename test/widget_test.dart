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
      expect(manifest.contains('android.permission.INTERNET'), isFalse);
      expect(manifest.contains('com.google.android.gms.ads'), isFalse);
    });

    test('FAZA 1 [Adım 3]: Offline Caller ID (spam_numbers.bin) 50.000 kayıt ve <0.1ms binary search', () {
      final spamBin = File('assets/spam_db/spam_numbers.bin');
      expect(spamBin.existsSync(), isTrue);
      final bytes = spamBin.readAsBytesSync();
      expect(bytes.length, equals(400000)); // 50,000 * 8 bytes = 400 KB (390.62 KB)
      VeroCallerIdEngine.loadFromBytes(bytes);
      expect(VeroCallerIdEngine.recordCount, equals(50000));

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
        equals('🚨 Bu numara spam olarak işaretlendi: SPAM_SCAM'),
      );

      final resRobocall = VeroCallGuardEngine.inspectNumber('0212 901 00 10');
      expect(resRobocall.isSuspicious, isTrue);
      expect(
        resRobocall.warningTitleTr,
        equals('🚨 Bu numara spam olarak işaretlendi: SPAM_ROBOCALL'),
      );

      final resTelesales = VeroCallGuardEngine.inspectNumber('0850 480 99 88');
      expect(resTelesales.isSuspicious, isTrue);
      expect(
        resTelesales.warningTitleTr,
        equals('🚨 Bu numara spam olarak işaretlendi: SPAM_TELESALES'),
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
      expect(find.text('Kaç numara bildirdin: 1'), findsOneWidget);
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
        expect(find.text('🚨 DOLANDIRICILIK UYARISI'), findsOneWidget);
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
  });
}
