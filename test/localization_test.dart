import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustlens_mobile/core/localization/app_localizations.dart';

void main() {
  group('Localization Files Verification', () {
    const supported = AppLocalizations.supportedCodes;

    test('all 10 languages exist and are non-empty valid JSON', () {
      for (final code in supported) {
        final file = File('assets/locales/$code.json');
        expect(file.existsSync(), isTrue, reason: 'assets/locales/$code.json must exist');

        final content = file.readAsStringSync();
        expect(content.trim().isNotEmpty, isTrue);

        final json = jsonDecode(content) as Map<String, dynamic>;
        expect(json.isNotEmpty, isTrue);
      }
    });

    test('all language files contain the exact key set as the English base locale', () {
      final enContent = File('assets/locales/en.json').readAsStringSync();
      final enKeys = (jsonDecode(enContent) as Map<String, dynamic>).keys.toSet();

      expect(enKeys.length, greaterThanOrEqualTo(45));

      for (final code in supported) {
        if (code == 'en') continue;
        final content = File('assets/locales/$code.json').readAsStringSync();
        final keys = (jsonDecode(content) as Map<String, dynamic>).keys.toSet();

        final missing = enKeys.difference(keys);
        expect(
          missing,
          isEmpty,
          reason: 'Language "$code" is missing keys: $missing',
        );
      }
    });

    test('seed corpus json exists and contains multi-language training samples', () {
      final file = File('assets/model/seed_corpus.json');
      expect(file.existsSync(), isTrue);

      final list = (jsonDecode(file.readAsStringSync()) as List).cast<Map<String, dynamic>>();
      expect(list.length, greaterThanOrEqualTo(50));

      final labels = list.map((e) => e['l'] as String).toSet();
      expect(labels.contains('spam'), isTrue);
      expect(labels.contains('ham'), isTrue);
      expect(labels.contains('transaction'), isTrue);
    });
  });
}
