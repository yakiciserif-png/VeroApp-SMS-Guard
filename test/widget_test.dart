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

  testWidgets('Master Architecture Seal: Book Antiqua font, Call Guard, APK Sensor, 50px AdMob Banner & VERO AİLE 4-Member Code Card at 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1) Verify Book Antiqua typography, Offline 1.5 MB Bloom Filter & Call Guard / APK Sensor engines
    expect(CyberpunkTheme.fontFamily, equals('Book Antiqua'));
    expect(File('assets/fonts/BookAntiqua-Regular.ttf').existsSync(), isTrue);
    expect(File('assets/fonts/BookAntiqua-Bold.ttf').existsSync(), isTrue);
    final bloomBinFile = File('assets/breach_db/bloom_filter.bin');
    expect(bloomBinFile.existsSync(), isTrue);
    expect(bloomBinFile.lengthSync(), equals(1572864)); // 1.50 MB (12.58M bits)
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

    // 2) Free Tier: 50px AdMob bottom banner is visible
    expect(find.byKey(const Key('adMobAdaptiveBanner')), findsOneWidget);

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

    // Upgrade to VERO AİLE in 0 ms -> AdMob banner disappears immediately
    await state.upgradeSubscription(VeroSubscriptionTier.familyYearly);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adMobAdaptiveBanner')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
