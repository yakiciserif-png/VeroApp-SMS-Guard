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
  await state.init();
}
