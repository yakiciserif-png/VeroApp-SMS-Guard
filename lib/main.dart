import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/platform/vero_logger.dart';
import 'engines/vero_crash_logger.dart';
import 'state/app_state.dart';

String get appPlatformTitle {
  if (!kIsWeb && Platform.isIOS) {
    return 'VeroApp SMS Guard - AI Kalkan';
  }
  return 'VeroApp: SMS & Arama Kalkanı';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local crash logging before any component mounts
  VeroCrashLogger.init();
  VeroLogger.i('VeroApp SMS Guard starting in 100% offline-first mode');

  // Pre-load SharedPreferences before mounting UI to guarantee 100% persistence
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    VeroLogger.w('SharedPreferences initial load failed, continuing with in-memory fallback', error: e, stackTrace: st);
  }

  final state = AppState(prefs: prefs);
  runApp(VeroAppSmsGuardApp(state: state, appTitle: appPlatformTitle));

  // Initialize app state asynchronously without blocking initial frame rendering.
  // Internal 1.8s timeout + 2.0s splash screen failsafe guarantee transition within 2 seconds.
  unawaited(
    state.init().catchError((Object e, StackTrace st) {
      VeroLogger.e('AppState async initialization error, forcing ready state', error: e, stackTrace: st);
      state.forceReady();
    }),
  );
}
