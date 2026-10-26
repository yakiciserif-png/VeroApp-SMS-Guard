import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/classifier/classification.dart';
import '../core/classifier/naive_bayes.dart';
import '../core/classifier/otp_detector.dart';
import '../core/classifier/smart_classifier.dart';
import '../core/classifier/threat_database.dart';
import '../core/monetization/purchase_service.dart';
import '../core/platform/native_bridge.dart';
import '../core/rules/rule_engine.dart';
import '../engines/vero_community_shield.dart';
import '../engines/vero_link_scanner.dart';
import '../models/history_entry.dart';

typedef SeedLoader = Future<String> Function();

/// 1-Tap Protection Level (Esnek / Dengeli / Sıkı).
enum ProtectionMode { relaxed, balanced, strict }

/// FAZ 5 — [4] SMART INBOX (Akıllı Sekreter / 4 Klasörleme).
enum SmartInboxFolder {
  all,
  finance,
  deliveryAppointment,
  personalChat,
  spam,
}

/// Central application state (rules, blacklist/whitelist, threat shields,
/// protection mode, theme mode, history, model, preferences).
class AppState extends ChangeNotifier {
  AppState({NativeBridge bridge = const NativeBridge(), SeedLoader? seedLoader})
      : _bridge = bridge,
        _seedLoader = seedLoader ??
            (() => rootBundle.loadString('assets/model/seed_corpus.json'));

  static const _kRules = 'tl.rules';
  static const _kBlacklist = 'tl.blacklist';
  static const _kWhitelist = 'tl.whitelist';
  static const _kHistory = 'tl.history';
  static const _kModel = 'tl.model';
  static const _kLocale = 'tl.locale';
  static const _kAutoDismiss = 'tl.autoDismiss';
  static const _kAutoCleanOtp24h = 'tl.autoCleanOtp24h';
  static const _kShields = 'tl.shields';
  static const _kProtectionMode = 'tl.protectionMode';
  static const _kThemeMode = 'tl.themeMode';
  static const _kSubTier = 'vero.subTier';
  static const _kFamilyOwner = 'vero.familyOwner';
  static const _kFamilyMember = 'vero.familyMember';
  static const _kFamilyCode = 'vero.familyCode';
  static const _kCallGuard = 'vero.callGuard';
  static const _kKvkkConsent = 'vero.kvkkConsent';
  static const _kLinkScannerMode = 'vero.linkScannerMode';
  static const int maxHistory = 500;

  final NativeBridge _bridge;
  final SeedLoader _seedLoader;
  late SharedPreferences _prefs;

  late SmartClassifier classifier;
  final PurchaseService purchaseService = PurchaseService();
  final List<FilterRule> rules = [];
  final List<String> blacklist = [];
  final List<String> whitelist = [];
  final List<HistoryEntry> history = [];

  bool ready = false;
  Locale? locale; // null => follow system
  ThemeMode themeMode = ThemeMode.system;
  ProtectionMode protectionMode = ProtectionMode.balanced;
  bool autoDismissSpam = true;
  bool autoCleanOtp24h = false;
  bool callGuardEnabled = true;
  LinkScannerMode linkScannerMode = LinkScannerMode.automatic;
  bool hasAcceptedKvkkConsent = false;
  bool otpAlertDismissed = false;
  bool notificationAccess = false;
  bool smsPermissionGranted = false;
  bool isDefaultSmsRoleHeld = false;
  double lastInterceptLatencyMs = 0.0;
  ThreatShieldConfig shieldConfig = const ThreatShieldConfig();

  NativeBridge get bridge => _bridge;

  bool get isProOrFamily => purchaseService.isProOrFamily;
  bool get isFamilyOwner => purchaseService.isFamilyOwner;
  bool get isFamilyMember => purchaseService.isFamilyMember;
  VeroSubscriptionTier get subscriptionTier => purchaseService.tier;
  int get reportedCommunityNumbersCount => VeroCommunityShield.reportedCount;

  /// True when any OS-level real-time interception hook is active on Android.
  bool get isRealTimeProtectionActive =>
      notificationAccess || smsPermissionGranted || isDefaultSmsRoleHeld;

  /// Combines simple Whitelist + Blacklist items with advanced custom rules.
  List<FilterRule> get effectiveRules => [
        if (whitelist.isNotEmpty)
          FilterRule(
            id: '__whitelist__',
            name: 'Beyaz Liste (Whitelist)',
            pattern: whitelist.join(', '),
            type: RuleType.keyword,
            target: RuleTarget.any,
            action: MessageCategory.normal,
          ),
        if (blacklist.isNotEmpty)
          FilterRule(
            id: '__blacklist__',
            name: 'Kara Liste (Blacklist)',
            pattern: blacklist.join(', '),
            type: RuleType.keyword,
            target: RuleTarget.any,
            action: MessageCategory.spam,
          ),
        ...rules,
      ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final code = _prefs.getString(_kLocale);
    if (code != null) locale = Locale(code);
    autoDismissSpam = _prefs.getBool(_kAutoDismiss) ?? true;
    autoCleanOtp24h = _prefs.getBool(_kAutoCleanOtp24h) ?? false;
    callGuardEnabled = _prefs.getBool(_kCallGuard) ?? true;
    hasAcceptedKvkkConsent = _prefs.getBool(_kKvkkConsent) ?? false;

    final savedLinkMode = _prefs.getString(_kLinkScannerMode);
    if (savedLinkMode != null) {
      linkScannerMode = LinkScannerMode.values.firstWhere(
        (m) => m.name == savedLinkMode,
        orElse: () => LinkScannerMode.automatic,
      );
      VeroLinkScanner.instance.setMode(linkScannerMode);
    }

    await VeroCommunityShield.init(_prefs);

    final savedTier = _prefs.getString(_kSubTier);
    if (savedTier != null) {
      purchaseService.tier = VeroSubscriptionTier.values.firstWhere(
        (t) => t.name == savedTier,
        orElse: () => VeroSubscriptionTier.free,
      );
    }
    purchaseService.isFamilyOwner = _prefs.getBool(_kFamilyOwner) ?? true;
    purchaseService.isFamilyMember = _prefs.getBool(_kFamilyMember) ?? false;
    purchaseService.familyCode = _prefs.getString(_kFamilyCode) ?? '892341';

    final savedTheme = _prefs.getString(_kThemeMode);
    if (savedTheme != null) {
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    final savedMode = _prefs.getString(_kProtectionMode);
    if (savedMode != null) {
      protectionMode = ProtectionMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => ProtectionMode.balanced,
      );
    }

    final rawShields = _prefs.getString(_kShields);
    if (rawShields != null) {
      try {
        shieldConfig = ThreatShieldConfig.fromJson(
          jsonDecode(rawShields) as Map<String, dynamic>,
        );
      } catch (_) {
        shieldConfig = const ThreatShieldConfig();
      }
    }

    blacklist
      ..clear()
      ..addAll(_prefs.getStringList(_kBlacklist) ?? const []);
    whitelist
      ..clear()
      ..addAll(_prefs.getStringList(_kWhitelist) ?? const []);

    rules
      ..clear()
      ..addAll(_decodeList(_prefs.getString(_kRules)).map(FilterRule.fromJson));
    history
      ..clear()
      ..addAll(
        _decodeList(_prefs.getString(_kHistory)).map(HistoryEntry.fromJson),
      );

    NaiveBayesModel model;
    final savedModel = _prefs.getString(_kModel);
    if (savedModel != null) {
      try {
        model = NaiveBayesModel.fromJson(
          jsonDecode(savedModel) as Map<String, dynamic>,
        );
      } catch (_) {
        model = await _trainSeedModel();
      }
    } else {
      model = await _trainSeedModel();
    }
    classifier = SmartClassifier(
      model: model,
      rules: RuleEngine(effectiveRules),
      shieldConfig: shieldConfig,
    );

    ready = true;
    if (autoCleanOtp24h) {
      await runAutoCleaner();
    }
    notifyListeners();
    await refreshPlatformStatus();
    await syncNative();
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<NaiveBayesModel> _trainSeedModel() async {
    final model = NaiveBayesModel();
    final corpus = (jsonDecode(await _seedLoader()) as List)
        .cast<Map<String, dynamic>>();
    for (final row in corpus) {
      model.train(
        row['t'] as String,
        MessageCategory.fromLabel(row['l'] as String),
      );
    }
    return model;
  }

  // ---------------------------------------------------------------- analysis

  Map<MessageCategory, int> get stats {
    final counts = {for (final c in MessageCategory.values) c: 0};
    for (final h in history) {
      counts[h.category] = counts[h.category]! + 1;
    }
    return counts;
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(1 << 20)}';

  HistoryEntry analyze(
    String text, {
    MessageOrigin origin = MessageOrigin.manual,
    String? sender,
    DateTime? timestamp,
    bool persist = true,
  }) {
    final cleanSender =
        sender != null && sender.trim().isNotEmpty ? sender.trim() : null;
    final result = classifier.classify(text, sender: cleanSender);
    final entry = HistoryEntry(
      id: _newId(),
      text: text.trim(),
      category: result.category,
      confidence: result.confidence,
      source: result.source,
      subCategory: result.subCategory,
      ruleName: result.ruleName,
      otpCode: result.otpCode,
      signals: result.signals,
      probabilities: result.probabilities,
      intentVector: result.intentVector,
      whyReasons: result.whyReasons,
      stageBreakdown: result.stageBreakdown,
      timestamp: timestamp ?? DateTime.now(),
      origin: origin,
      sender: cleanSender,
    );
    history.insert(0, entry);
    if (entry.otpCode != null ||
        entry.subCategory == MessageSubCategory.otpCode ||
        entry.signals.contains('signalOtpCode')) {
      otpAlertDismissed = false;
    }
    if (history.length > maxHistory) {
      history.removeRange(maxHistory, history.length);
    }
    if (persist) {
      _saveHistory();
      notifyListeners();
    }
    return entry;
  }

  // ----------------------------------------- FAZ 5: OTP-ALERT & SMART INBOX

  static final RegExp _deliveryAppointmentRegex = RegExp(
    r'(kargo|teslim|teslimat|paket|gönderi|gonderi|kurye|randevu|hastane|mhrs|hekim|poliklinik|muayene|sipariş|siparis|takip\s*no|dağıtım|dagitim|delivery|parcel|shipment|appointment|clinic|tracking)',
    caseSensitive: false,
  );

  bool _isOtpEntry(HistoryEntry e) =>
      e.otpCode != null ||
      e.subCategory == MessageSubCategory.otpCode ||
      e.signals.contains('signalOtpCode') ||
      e.signals.contains('signalOtpWithLinkTrap');

  /// Count of OTP / verification SMS messages received within [window] (default 3 minutes)
  /// relative to the newest message timestamp or `DateTime.now()`.
  int recentOtpCount({Duration window = const Duration(minutes: 3)}) {
    final otpEntries = history.where(_isOtpEntry).toList();
    if (otpEntries.isEmpty) return 0;
    final anchor = otpEntries.first.timestamp;
    return otpEntries
        .where((e) => anchor.difference(e.timestamp).abs() <= window)
        .length;
  }

  /// True when >= 3 OTP/verification SMS arrived within a 3-minute burst
  /// (Account Takeover / Silent Thief / SMS Bombing alert).
  bool get isOtpAttackActive => !otpAlertDismissed && recentOtpCount() >= 3;

  void dismissOtpAlert() {
    otpAlertDismissed = true;
    notifyListeners();
  }

  /// Categorizes [entry] into one of the 4 Smart Inbox folders.
  SmartInboxFolder folderForEntry(HistoryEntry entry) {
    if (entry.category == MessageCategory.spam) {
      return SmartInboxFolder.spam;
    }
    if (entry.otpCode == null &&
        (_deliveryAppointmentRegex.hasMatch(entry.text) ||
            (entry.sender != null &&
                _deliveryAppointmentRegex.hasMatch(entry.sender!)))) {
      return SmartInboxFolder.deliveryAppointment;
    }
    if (entry.category == MessageCategory.transaction ||
        entry.otpCode != null ||
        entry.subCategory == MessageSubCategory.otpCode ||
        entry.subCategory == MessageSubCategory.bankTransaction) {
      return SmartInboxFolder.finance;
    }
    return SmartInboxFolder.personalChat;
  }

  Map<SmartInboxFolder, int> get folderCounts {
    final counts = {
      for (final f in SmartInboxFolder.values) f: 0,
    };
    counts[SmartInboxFolder.all] = history.length;
    for (final h in history) {
      final f = folderForEntry(h);
      counts[f] = (counts[f] ?? 0) + 1;
    }
    return counts;
  }

  // ----------------------------------------- FAZ 5: AUTO-CLEANER (DİJİTAL ÇÖPÇÜ)

  Future<void> setAutoCleanOtp24h(bool value) async {
    autoCleanOtp24h = value;
    await _prefs.setBool(_kAutoCleanOtp24h, value);
    if (value) {
      await runAutoCleaner();
    }
    notifyListeners();
  }

  /// Removes expired OTPs/delivery notices older than [otpMaxAge] (default 24h)
  /// and old spam older than [spamMaxAge] (default 7 days).
  /// When [cleanAllOtpNow] is true, removes all OTP & expired spam records immediately.
  Future<int> runAutoCleaner({
    Duration otpMaxAge = const Duration(hours: 24),
    Duration spamMaxAge = const Duration(days: 7),
    bool cleanAllOtpNow = false,
    DateTime? now,
  }) async {
    final refNow = now ?? DateTime.now();
    final before = history.length;
    history.removeWhere((e) {
      final age = refNow.difference(e.timestamp);
      final isOtpOrDelivery = _isOtpEntry(e) ||
          folderForEntry(e) == SmartInboxFolder.deliveryAppointment;
      if (cleanAllOtpNow && isOtpOrDelivery) return true;
      if (isOtpOrDelivery && age >= otpMaxAge) return true;
      if (e.category == MessageCategory.spam && age >= spamMaxAge) return true;
      return false;
    });
    final removed = before - history.length;
    if (removed > 0) {
      await _saveHistory();
      notifyListeners();
    }
    return removed;
  }

  Future<void> acceptKvkkConsent() async {
    hasAcceptedKvkkConsent = true;
    await _prefs.setBool(_kKvkkConsent, true);
    notifyListeners();
  }

  Future<void> resetKvkkConsent() async {
    hasAcceptedKvkkConsent = false;
    await _prefs.remove(_kKvkkConsent);
    notifyListeners();
  }

  // ------------------------- FAZ 5: COMMUNITY SHIELD & FALSE POSITIVE REPORT

  /// Exports a 100% privacy-preserving offline threat signature bundle
  /// (anonymized token signatures, rules, blacklist, whitelist — zero personal SMS).
  String exportCommunityShieldBundle() {
    final topSpamWeights = classifier.model.exportSpamWeights();
    return const JsonEncoder.withIndent('  ').convert({
      'type': 'vero_community_shield',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'rules': rules.map((r) => r.toJson()).toList(),
      'blacklist': blacklist,
      'whitelist': whitelist,
      'threatSignatures': topSpamWeights,
    });
  }

  /// Imports either a Community Shield JSON bundle or a plain Rules JSON array.
  Future<int> importCommunityShieldBundle(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is List) {
      return importRulesJson(rawJson);
    }
    if (decoded is! Map<String, dynamic>) return 0;

    var importedCount = 0;
    final rawRules = decoded['rules'];
    if (rawRules is List) {
      for (final item in rawRules.whereType<Map<String, dynamic>>()) {
        final r = FilterRule.fromJson(item);
        if (r.pattern.trim().isEmpty) continue;
        final idx = rules.indexWhere((x) => x.id == r.id);
        if (idx >= 0) {
          rules[idx] = r;
        } else {
          rules.add(r);
        }
        importedCount++;
      }
    }

    final rawBlack = decoded['blacklist'];
    if (rawBlack is List) {
      for (final b in rawBlack.map((e) => e.toString().trim())) {
        if (b.isNotEmpty && !blacklist.contains(b)) {
          blacklist.add(b);
          importedCount++;
        }
      }
    }

    final rawWhite = decoded['whitelist'];
    if (rawWhite is List) {
      for (final w in rawWhite.map((e) => e.toString().trim())) {
        if (w.isNotEmpty && !whitelist.contains(w)) {
          whitelist.add(w);
          importedCount++;
        }
      }
    }

    final rawSigs = decoded['threatSignatures'];
    if (rawSigs is Map) {
      for (final entry in rawSigs.entries) {
        final token = entry.key.toString().trim();
        final weight = (entry.value as num?)?.toDouble() ?? 0.0;
        if (token.length >= 3 && weight > 0.5) {
          classifier.model.train(token, MessageCategory.spam, weight: 1);
          importedCount++;
        }
      }
      await _prefs.setString(_kModel, jsonEncode(classifier.model.toJson()));
    }

    await _saveSimpleLists();
    await _saveRules();
    return importedCount;
  }

  /// Standalone or entry-linked False Positive / Missed Spam Report & On-Device Re-Training.
  Future<void> reportAndTrain({
    required String text,
    required MessageCategory expectedCategory,
    String? sender,
    HistoryEntry? existingEntry,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    if (existingEntry != null) {
      await correct(existingEntry, expectedCategory);
      return;
    }
    classifier.model.train(cleanText, expectedCategory, weight: 4);
    await _prefs.setString(_kModel, jsonEncode(classifier.model.toJson()));
    final entry = analyze(
      cleanText,
      sender: sender,
      origin: MessageOrigin.manual,
      persist: false,
    );
    final idx = history.indexWhere((h) => h.id == entry.id);
    if (idx >= 0) {
      history[idx] = entry.copyWith(
        category: expectedCategory,
        corrected: true,
      );
    }
    await _saveHistory();
    notifyListeners();
    await syncNative();
  }

  /// User feedback: re-labels [entry] and teaches the AI model (weight 3).
  Future<HistoryEntry> correct(
    HistoryEntry entry,
    MessageCategory category,
  ) async {
    classifier.model.train(entry.text, category, weight: 3);
    final updated = entry.copyWith(category: category, corrected: true);
    final i = history.indexWhere((h) => h.id == entry.id);
    if (i >= 0) history[i] = updated;
    await _prefs.setString(_kModel, jsonEncode(classifier.model.toJson()));
    await _saveHistory();
    notifyListeners();
    await syncNative();
    return updated;
  }

  /// Imports messages captured by the native listener while the UI was closed.
  Future<int> importPendingMessages() async {
    final pending = await _bridge.fetchPendingMessages();
    for (final m in pending.reversed) {
      analyze(
        m.text,
        origin: MessageOrigin.notification,
        sender: m.sender,
        timestamp: m.timestamp,
        persist: false,
      );
    }
    if (pending.isNotEmpty) {
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _saveHistory();
      notifyListeners();
    }
    return pending.length;
  }

  Future<void> deleteHistoryEntry(String id) async {
    history.removeWhere((h) => h.id == id);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() => _prefs.setString(
        _kHistory,
        jsonEncode(history.map((h) => h.toJson()).toList()),
      );

  // ------------------------------------------------ simple blacklist/whitelist

  Future<void> addBlacklistItem(String item) async {
    final clean = item.trim();
    if (clean.isEmpty || blacklist.contains(clean)) return;
    whitelist.remove(clean);
    blacklist.insert(0, clean);
    await _saveSimpleLists();
  }

  Future<void> removeBlacklistItem(String item) async {
    blacklist.remove(item);
    await _saveSimpleLists();
  }

  Future<void> addWhitelistItem(String item) async {
    final clean = item.trim();
    if (clean.isEmpty || whitelist.contains(clean)) return;
    blacklist.remove(clean);
    whitelist.insert(0, clean);
    await _saveSimpleLists();
  }

  Future<void> removeWhitelistItem(String item) async {
    whitelist.remove(item);
    await _saveSimpleLists();
  }

  Future<void> _saveSimpleLists() async {
    classifier.rules = RuleEngine(effectiveRules);
    await _prefs.setStringList(_kBlacklist, blacklist);
    await _prefs.setStringList(_kWhitelist, whitelist);
    notifyListeners();
    await syncNative();
  }

  // ------------------------------------------------------------------- rules

  Future<void> upsertRule(FilterRule rule) async {
    final i = rules.indexWhere((r) => r.id == rule.id);
    if (i >= 0) {
      rules[i] = rule;
    } else {
      rules.add(rule);
    }
    await _saveRules();
  }

  Future<void> deleteRule(String id) async {
    rules.removeWhere((r) => r.id == id);
    await _saveRules();
  }

  Future<void> reorderRules(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    rules.insert(newIndex, rules.removeAt(oldIndex));
    await _saveRules();
  }

  FilterRule newRule() => FilterRule(id: _newId(), name: '', pattern: '');

  String exportRulesJson() => const JsonEncoder.withIndent('  ')
      .convert(rules.map((r) => r.toJson()).toList());

  Future<int> importRulesJson(String rawJson) async {
    final list = (jsonDecode(rawJson) as List).cast<Map<String, dynamic>>();
    var added = 0;
    for (final item in list) {
      final imported = FilterRule.fromJson(item);
      if (imported.pattern.trim().isEmpty) continue;
      final existingIdx = rules.indexWhere((r) => r.id == imported.id);
      if (existingIdx >= 0) {
        rules[existingIdx] = imported;
      } else {
        rules.add(imported);
      }
      added++;
    }
    if (added > 0) {
      await _saveRules();
    }
    return added;
  }

  Future<void> _saveRules() async {
    classifier.rules = RuleEngine(effectiveRules);
    await _prefs.setString(
      _kRules,
      jsonEncode(rules.map((r) => r.toJson()).toList()),
    );
    notifyListeners();
    await syncNative();
  }

  // ----------------------------------------- protection mode & threat shields

  Future<void> setProtectionMode(ProtectionMode mode) async {
    protectionMode = mode;
    await _prefs.setString(_kProtectionMode, mode.name);
    final updatedShields = switch (mode) {
      ProtectionMode.relaxed => const ThreatShieldConfig(
          bettingShield: true,
          phishingShield: true,
          linkShield: false,
          marketingShield: false,
        ),
      ProtectionMode.balanced => const ThreatShieldConfig(
          bettingShield: true,
          phishingShield: true,
          linkShield: true,
          marketingShield: false,
        ),
      ProtectionMode.strict => const ThreatShieldConfig(
          bettingShield: true,
          phishingShield: true,
          linkShield: true,
          marketingShield: true,
        ),
    };
    await updateShieldConfig(updatedShields);
  }

  Future<void> updateShieldConfig(ThreatShieldConfig value) async {
    shieldConfig = value;
    classifier.shieldConfig = value;
    await _prefs.setString(_kShields, jsonEncode(value.toJson()));
    notifyListeners();
    await syncNative();
  }

  // --------------------------------------------------------- theme & settings

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> toggleThemeMode(Brightness currentBrightness) async {
    final next = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setLocale(Locale? value) async {
    locale = value;
    if (value == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, value.languageCode);
    }
    notifyListeners();
  }

  Future<void> setAutoDismiss(bool value) async {
    autoDismissSpam = value;
    await _prefs.setBool(_kAutoDismiss, value);
    notifyListeners();
    await syncNative();
  }

  Future<void> resetModel() async {
    classifier.model = await _trainSeedModel();
    await _prefs.remove(_kModel);
    notifyListeners();
    await syncNative();
  }

  Future<void> refreshPlatformStatus() async {
    final hooks = await _bridge.getSystemHooksStatus();
    final granted = hooks.notificationAccess ||
        await _bridge.isNotificationAccessGranted();
    final changed = granted != notificationAccess ||
        hooks.smsPermissionGranted != smsPermissionGranted ||
        hooks.isDefaultSmsRoleHeld != isDefaultSmsRoleHeld ||
        hooks.lastInterceptLatencyMs != lastInterceptLatencyMs;
    if (changed) {
      notificationAccess = granted;
      smsPermissionGranted = hooks.smsPermissionGranted;
      isDefaultSmsRoleHeld = hooks.isDefaultSmsRoleHeld;
      lastInterceptLatencyMs = hooks.lastInterceptLatencyMs;
      notifyListeners();
    }
  }

  /// Requests Android SMS permissions gracefully and refreshes hook state.
  Future<bool> requestSmsPermissions() async {
    final granted = await _bridge.requestSmsPermissions();
    smsPermissionGranted = granted;
    notifyListeners();
    await refreshPlatformStatus();
    return granted;
  }

  /// Requests Android 10+ Default SMS / Spam Filter Role via `RoleManager`.
  Future<bool> requestSpamRole() async {
    final held = await _bridge.requestSpamRole();
    isDefaultSmsRoleHeld = held;
    notifyListeners();
    await refreshPlatformStatus();
    return held;
  }

  // ------------------------------------------------------------ native sync

  /// Config consumed by Android `TrustFilterEngine.kt` and iOS
  /// `TrustFilterEngine.swift`.
  @visibleForTesting
  Map<String, dynamic> buildNativeConfig() => {
        'version': 1,
        'autoDismiss': autoDismissSpam,
        'spamThreshold': switch (protectionMode) {
          ProtectionMode.relaxed => 0.65,
          ProtectionMode.balanced => 0.0,
          ProtectionMode.strict => -0.35,
        },
        'shortUrlBoost': SmartClassifier.shortUrlBoost,
        'spamPrior': classifier.model.spamPriorLogRatio,
        'spamWeights': classifier.model.exportSpamWeights(),
        'otpKeywords': OtpDetector.otpKeywords,
        'transactionKeywords': OtpDetector.transactionKeywords,
        'shields': shieldConfig.toJson(),
        'bettingPhrases': ThreatDatabase.bettingPhrases,
        'govScamPhrases': ThreatDatabase.govAndLegalScamPhrases,
        'deliveryScamPhrases': ThreatDatabase.deliveryScamPhrases,
        'accountPhishingPhrases': ThreatDatabase.accountPhishingPhrases,
        'marketingPhrases': ThreatDatabase.marketingPhrases,
        'rules': effectiveRules.map((r) => r.toJson()).toList(),
      };

  Future<void> syncNative() async {
    if (!ready) return;
    await _bridge.syncFilterConfig(jsonEncode(buildNativeConfig()));
  }

  // --------------------------------------------------- Monetization & Call Guard

  Future<void> setCallGuardEnabled(bool value) async {
    callGuardEnabled = value;
    await _prefs.setBool(_kCallGuard, value);
    notifyListeners();
  }

  Future<void> setLinkScannerMode(LinkScannerMode mode) async {
    linkScannerMode = mode;
    VeroLinkScanner.instance.setMode(mode);
    await _prefs.setString(_kLinkScannerMode, mode.name);
    notifyListeners();
  }

  /// 0 ms Instant Upgrade via RevenueCat / IAP service.
  Future<void> upgradeSubscription(VeroSubscriptionTier tier) async {
    purchaseService.upgradeTo(tier);
    await _prefs.setString(_kSubTier, purchaseService.tier.name);
    await _prefs.setBool(_kFamilyOwner, purchaseService.isFamilyOwner);
    await _prefs.setBool(_kFamilyMember, purchaseService.isFamilyMember);
    await _prefs.setString(_kFamilyCode, purchaseService.familyCode);
    notifyListeners();
  }

  /// 0 ms Family Code validation & activation for Family Members.
  Future<bool> joinFamilyWithCode(String rawCode) async {
    final ok = purchaseService.joinFamilyWithCode(rawCode);
    if (!ok) return false;
    await _prefs.setString(_kSubTier, purchaseService.tier.name);
    await _prefs.setBool(_kFamilyOwner, purchaseService.isFamilyOwner);
    await _prefs.setBool(_kFamilyMember, purchaseService.isFamilyMember);
    await _prefs.setString(_kFamilyCode, purchaseService.familyCode);
    notifyListeners();
    return true;
  }

  /// Toggles between Family Owner view (`8 9 2  3 4 1` + `4/4 Üye Bağlı`) and Family Member view.
  Future<void> setFamilyOwnerMode(bool ownerMode) async {
    purchaseService.isFamilyOwner = ownerMode;
    if (ownerMode) {
      purchaseService.tier = VeroSubscriptionTier.familyYearly;
      purchaseService.isFamilyMember = false;
    }
    await _prefs.setString(_kSubTier, purchaseService.tier.name);
    await _prefs.setBool(_kFamilyOwner, purchaseService.isFamilyOwner);
    await _prefs.setBool(_kFamilyMember, purchaseService.isFamilyMember);
    notifyListeners();
  }

  /// [ADIM 4 & 5] Reports a spam phone number to the local Community Shield database (0 internet).
  Future<bool> reportSpamPhoneNumber(
    String rawNumber, {
    String category = 'SPAM_SCAM',
  }) async {
    final ok = await VeroCommunityShield.reportNumber(
      rawNumber,
      category: category,
      prefs: _prefs,
    );
    if (ok) notifyListeners();
    return ok;
  }

  /// [ADIM 5] Clears all locally reported spam phone numbers.
  Future<void> clearReportedSpamPhoneNumbers() async {
    await VeroCommunityShield.clearAll(_prefs);
    notifyListeners();
  }
}
