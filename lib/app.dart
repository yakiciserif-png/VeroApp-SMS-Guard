import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'state/app_state.dart';
import 'ui/cyberpunk_theme.dart';
import 'ui/history_screen.dart';
import 'ui/home_screen.dart';
import 'ui/rules_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/first_launch_consent_dialog.dart';

/// Gives descendants access to [AppState] and rebuilds them on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class VeroAppSmsGuardApp extends StatelessWidget {
  const VeroAppSmsGuardApp({
    super.key,
    required this.state,
    this.appTitle,
  });

  final AppState state;
  final String? appTitle;

  static const Color seed = CyberpunkColors.neonCyan;

  @override
  Widget build(BuildContext context) {
    final cyberDark = CyberpunkTheme.build(brightness: Brightness.dark);
    final cyberLight = CyberpunkTheme.build(brightness: Brightness.light);

    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: appTitle ??
              ((!kIsWeb && Platform.isIOS)
                  ? 'VeroApp Call Guard - AI Kalkan'
                  : 'VeroApp: SMS & Arama Kalkanı'),
          debugShowCheckedModeBanner: false,
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            for (final l in supported) {
              if (l.languageCode == device?.languageCode) return l;
            }
            return const Locale('en');
          },
          themeMode: state.themeMode == ThemeMode.light
              ? ThemeMode.light
              : ThemeMode.dark,
          theme: cyberLight,
          darkTheme: cyberDark,
          home: state.ready ? const RootShell() : const CyberSplashScreen(),
        ),
      ),
    );
  }
}

/// Cyberpunk Variant 3 Splash Screen (Hex Shield + AI Neural Core + VeroApp SMS Guard).
class CyberSplashScreen extends StatelessWidget {
  const CyberSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CyberpunkColors.bgPrimary,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                Color(0xFF171336),
                CyberpunkColors.bgPrimary,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CyberHexShieldIcon(size: 96),
                  const SizedBox(height: 20),
                  const Text(
                    'VeroApp SMS Guard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CyberpunkColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        color: CyberpunkColors.neonCyan,
                        backgroundColor: CyberpunkColors.borderSubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onResume());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }

  Future<void> _onResume() async {
    final app = AppScope.read(context);
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (!app.hasAcceptedKvkkConsent && mounted && !isTest) {
      await FirstLaunchConsentDialog.showIfNeeded(context);
    }
    await app.refreshPlatformStatus();
    final imported = await app.importPendingMessages();
    if (!mounted || imported == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).t('syncedCount', {'n': '$imported'}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          HistoryScreen(),
          RulesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: CyberpunkColors.borderSubtle, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.shield_outlined),
              selectedIcon: const Icon(Icons.shield),
              label: l.t('navHome'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history),
              label: l.t('navHistory'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.rule),
              label: l.t('navRules'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.t('navSettings'),
            ),
          ],
        ),
      ),
    );
  }
}
