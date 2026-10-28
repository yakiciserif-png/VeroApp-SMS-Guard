import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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
  final state = AppState();
  runApp(VeroAppSmsGuardApp(state: state, appTitle: appPlatformTitle));

  // Initialize app state asynchronously without blocking initial frame rendering.
  // Internal 1.8s timeout + 2.0s splash screen failsafe guarantee transition within 2 seconds.
  state.init().catchError((e, st) {
    debugPrint('[main] state.init error: $e');
    state.forceReady();
  });
}
