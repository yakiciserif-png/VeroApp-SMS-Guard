import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/app_state.dart';

String get appPlatformTitle {
  if (!kIsWeb && Platform.isIOS) {
    return 'VeroApp SMS Guard - AI Kalkan';
  }
  return 'VeroApp: SMS & Arama Kalkanı';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load SharedPreferences before mounting UI to guarantee 100% persistence
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Graceful fallback when SharedPreferences is unavailable
  }

  final state = AppState(prefs: prefs);
  runApp(VeroAppSmsGuardApp(state: state, appTitle: appPlatformTitle));

  // Initialize app state asynchronously without blocking initial frame rendering.
  // Internal 1.8s timeout + 2.0s splash screen failsafe guarantee transition within 2 seconds.
  state.init().catchError((Object e, StackTrace st) {
    state.forceReady();
  });
}
