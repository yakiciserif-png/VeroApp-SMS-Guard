import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustlens_mobile/core/classifier/classification.dart';
import 'package:trustlens_mobile/core/classifier/safe_click_engine.dart';
import 'package:trustlens_mobile/core/platform/native_bridge.dart';
import 'package:trustlens_mobile/core/rules/rule_engine.dart';
import 'package:trustlens_mobile/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final corpus = File('assets/model/seed_corpus.json').readAsStringSync();
    state = AppState(
      seedLoader: () async => corpus,
      bridge: const NativeBridge(enabled: false),
    );
    await state.init();
  });

  group('AppState Tests', () {
    test('initializes with seed model and empty history', () {
      expect(state.ready, isTrue);
      expect(state.history, isEmpty);
      expect(state.rules, isEmpty);
      expect(state.classifier.model.vocabularySize, greaterThan(100));
    });

    test('analyzes message, creates history entry and persists it', () {
      final entry = state.analyze('Congratulations! You won a \$1000 gift card.');
      expect(entry.category, equals(MessageCategory.spam));
      expect(state.history.length, equals(1));
      expect(state.stats[MessageCategory.spam], equals(1));
    });

    test('allows user feedback to correct classification and update model', () async {
      final entry = state.analyze('Meeting today at 3pm for project review.');
      expect(entry.category, equals(MessageCategory.normal));

      // Correct it to spam
      final updated = await state.correct(entry, MessageCategory.spam);
      expect(updated.category, equals(MessageCategory.spam));
      expect(updated.corrected, isTrue);
      expect(state.history.first.category, equals(MessageCategory.spam));
    });

    test('supports adding, updating, exporting, and deleting custom rules', () async {
      final rule = FilterRule(
        id: 'r1',
        name: 'Block Casino',
        pattern: 'roulette, blackjack',
        action: MessageCategory.spam,
      );

      await state.upsertRule(rule);
      expect(state.rules.length, equals(1));

      final match = state.analyze('Come play roulette tonight with friends!');
      expect(match.category, equals(MessageCategory.spam));
      expect(match.source, equals(DecisionSource.userRule));
      expect(match.ruleName, equals('Block Casino'));

      final exported = state.exportRulesJson();
      expect(exported.contains('Block Casino'), isTrue);

      await state.deleteRule('r1');
      expect(state.rules, isEmpty);

      final count = await state.importRulesJson(exported);
      expect(count, equals(1));
      expect(state.rules.length, equals(1));
    });

    test('supports 1-tap ProtectionMode switching (relaxed, balanced, strict)', () async {
      await state.setProtectionMode(ProtectionMode.relaxed);
      expect(state.protectionMode, equals(ProtectionMode.relaxed));
      expect(state.shieldConfig.marketingShield, isFalse);
      expect(state.shieldConfig.bettingShield, isTrue);

      await state.setProtectionMode(ProtectionMode.strict);
      expect(state.protectionMode, equals(ProtectionMode.strict));
      expect(state.shieldConfig.marketingShield, isTrue);
    });

    test('supports Simple Blacklist and Whitelist without regex', () async {
      await state.addBlacklistItem('08509998877');
      await state.addWhitelistItem('Annem');
      expect(state.blacklist, contains('08509998877'));
      expect(state.whitelist, contains('Annem'));

      final blocked = state.analyze('Normal merhaba mesaji', sender: '08509998877');
      expect(blocked.category, equals(MessageCategory.spam));
      expect(blocked.source, equals(DecisionSource.userRule));

      final trusted = state.analyze('Bedava bonus kazandin hemen tikla', sender: 'Annem');
      expect(trusted.category, equals(MessageCategory.normal));
      expect(trusted.source, equals(DecisionSource.userRule));
    });

    test('supports Dark and Light theme mode toggling', () async {
      expect(state.themeMode, equals(ThemeMode.system));
      await state.setThemeMode(ThemeMode.dark);
      expect(state.themeMode, equals(ThemeMode.dark));
      await state.toggleThemeMode(Brightness.dark);
      expect(state.themeMode, equals(ThemeMode.light));
    });

    test('builds comprehensive native configuration for background engines', () {
      final config = state.buildNativeConfig();
      expect(config['version'], equals(1));
      expect(config['spamWeights'], isA<Map>());
      expect(config['otpKeywords'], isA<List>());
      expect(config['transactionKeywords'], isA<List>());
      expect(config['shields'], isA<Map>());
      expect(config['rules'], isA<List>());
    });

    test('FAZ 4: SystemHooksStatus parses native hook states and degrades gracefully when denied', () async {
      final parsed = SystemHooksStatus.fromMap({
        'notificationAccess': true,
        'smsPermissionGranted': true,
        'isDefaultSmsRoleHeld': false,
        'lastInterceptLatencyMs': 1.85,
      });
      expect(parsed.notificationAccess, isTrue);
      expect(parsed.smsPermissionGranted, isTrue);
      expect(parsed.isDefaultSmsRoleHeld, isFalse);
      expect(parsed.lastInterceptLatencyMs, closeTo(1.85, 0.01));
      expect(parsed.isAnyRealTimeHookActive, isTrue);

      // Graceful degradation when permissions/roles are denied or missing
      final deniedSms = await state.requestSmsPermissions();
      final deniedRole = await state.requestSpamRole();
      expect(deniedSms, isFalse);
      expect(deniedRole, isFalse);
      expect(state.isRealTimeProtectionActive, isFalse);
    });

    test('FAZ 4: Real-time classification latency stays well below 20 ms (< 0.02 s) budget', () {
      final sw = Stopwatch()..start();
      const iterations = 50;
      for (var i = 0; i < iterations; i++) {
        state.classifier.classify(
          'Son 24 saat! Hesabınıza 2000 TL deneme bonusu tanımlandı: bit.ly/vipbonus',
          sender: '+639171234567',
        );
      }
      sw.stop();
      final avgMs = sw.elapsedMicroseconds / 1000.0 / iterations;
      expect(avgMs, lessThan(20.0));
    });

    test('FAZ 5 [1]: SafeClickEngine detects brand spoofing, shorteners, IP hosts, and suspicious TLDs offline', () {
      final spoof = SafeClickEngine.analyzeUrl('http://e-devlet-iade-odeme.xyz/login');
      expect(spoof.riskLevel, equals(SafeClickRisk.critical));
      expect(spoof.impersonatedBrand, isNotNull);
      expect(spoof.findingKeys, contains('safeClickRiskBrandSpoof'));
      expect(spoof.findingKeys, contains('safeClickRiskTld'));

      final ipLink = SafeClickEngine.analyzeUrl('http://185.220.101.9/verify');
      expect(ipLink.riskLevel, equals(SafeClickRisk.critical));
      expect(ipLink.findingKeys, contains('safeClickRiskIpHost'));

      final shortener = SafeClickEngine.analyzeUrl('https://bit.ly/3xYz');
      expect(shortener.riskLevel, equals(SafeClickRisk.caution));
      expect(shortener.findingKeys, contains('safeClickRiskShortener'));

      final official = SafeClickEngine.analyzeUrl('https://turkiye.gov.tr');
      expect(official.riskLevel, equals(SafeClickRisk.safe));
      expect(official.findingKeys, contains('safeClickClean'));
    });

    test('FAZ 5 [2] & [3]: OTP-Alert detects 3+ OTPs in 3 minutes and Auto-Cleaner purges expired OTPs', () async {
      final now = DateTime.now();
      // Add an expired OTP from 26 hours ago
      state.analyze(
        'Banka giriş doğrulama kodunuz: 192837. Kimseyle paylaşmayın.',
        sender: 'BANKA',
        timestamp: now.subtract(const Duration(hours: 26)),
      );
      expect(state.isOtpAttackActive, isFalse);

      // Add 3 OTPs within 2 minutes -> triggers OTP-Alert!
      state.analyze(
        'Tek kullanımlık doğrulama kodunuz: 445566.',
        sender: 'BANKA',
        timestamp: now.subtract(const Duration(minutes: 2)),
      );
      state.analyze(
        'Giriş için onay kodunuz: 778899.',
        sender: 'SOSYAL',
        timestamp: now.subtract(const Duration(minutes: 1)),
      );
      state.analyze(
        'Doğrulama şifreniz: 112233. Paylaşmayınız.',
        sender: 'BANKA',
        timestamp: now,
      );

      expect(state.recentOtpCount(), greaterThanOrEqualTo(3));
      expect(state.isOtpAttackActive, isTrue);

      state.dismissOtpAlert();
      expect(state.isOtpAttackActive, isFalse);

      // Run Auto-Cleaner to remove the 26-hour-old OTP
      final removed = await state.runAutoCleaner(now: now);
      expect(removed, equals(1));
      expect(state.history.length, equals(3));
    });

    test('FAZ 5 [4]: Smart Inbox automatically categorizes Finance, Delivery, Personal, and Spam folders', () {
      final fin = state.analyze(
        'Giriş için tek kullanımlık doğrulama kodunuz: 654321.',
        sender: 'GARANTI',
      );
      final deliv = state.analyze(
        'Kargonuz dağıtıma çıkarılmıştır, bugün teslim edilecektir.',
        sender: 'KARGO',
      );
      final chat = state.analyze(
        'Hakan abi emaneti dükkana bıraktım akşam geçerken alırsın.',
        sender: 'Hakan Abi',
      );
      final spam = state.analyze(
        'Son 24 saat! 2000 TL deneme bonusu ve 250 freespin: bit.ly/win',
        sender: '+639170009988',
      );

      expect(state.folderForEntry(fin), equals(SmartInboxFolder.finance));
      expect(state.folderForEntry(deliv), equals(SmartInboxFolder.deliveryAppointment));
      expect(state.folderForEntry(chat), equals(SmartInboxFolder.personalChat));
      expect(state.folderForEntry(spam), equals(SmartInboxFolder.spam));

      final counts = state.folderCounts;
      expect(counts[SmartInboxFolder.finance], equals(1));
      expect(counts[SmartInboxFolder.deliveryAppointment], equals(1));
      expect(counts[SmartInboxFolder.personalChat], equals(1));
      expect(counts[SmartInboxFolder.spam], equals(1));
    });

    test('FAZ 5 [5]: Community Shield exports & imports anonymized threat bundles and Report retrains AI', () async {
      await state.addBlacklistItem('bahis-vip.xyz');
      await state.upsertRule(
        FilterRule(
          id: 'cs1',
          name: 'VIP Rule',
          pattern: 'vipslot',
          action: MessageCategory.spam,
        ),
      );
      final bundle = state.exportCommunityShieldBundle();
      expect(bundle.contains('vero_community_shield'), isTrue);

      await state.deleteRule('cs1');
      await state.removeBlacklistItem('bahis-vip.xyz');
      expect(state.rules, isEmpty);

      final imported = await state.importCommunityShieldBundle(bundle);
      expect(imported, greaterThan(0));
      expect(state.blacklist, contains('bahis-vip.xyz'));
      expect(state.rules.any((r) => r.id == 'cs1'), isTrue);

      // Report and retrain on-device AI
      await state.reportAndTrain(
        text: 'Özel esnaf toplantısı yarın saat 10da oda binasında yapılacak.',
        expectedCategory: MessageCategory.normal,
        sender: 'ESNAF ODASI',
      );
      expect(state.history.first.category, equals(MessageCategory.normal));
      expect(state.history.first.corrected, isTrue);
    });
  });
}

