import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// docs/architecture/FLAVOR_PARITY.md — full and lite are one app: the same
/// Dart code serves both, and only the bundled assets differ. A feature must
/// ask "is my content pack usable?" (ContentPackEngine.isUsable), never
/// "which flavor am I?". This guard fails the moment a flavor branch appears.
void main() {
  test('no flavor-specific branches anywhere in lib/', () {
    final forbidden = [
      RegExp(r'\bappFlavor\b'),
      RegExp(r'\bisLite\b'),
      RegExp(r'\bisFull\b'),
      RegExp(r'''fromEnvironment\(\s*['"]FLAVOR['"]'''),
      RegExp(r'talib_alilm\.lite'), // checking the package name at runtime
    ];
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue; // docs may mention flavors
        for (final re in forbidden) {
          if (re.hasMatch(line)) offenders.add('${f.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Flavor branches break full/lite parity:\n${offenders.join('\n')}');
  });

  test('first-launch essentials are never stripped from lite', () {
    final tool = File('tool/build_apk.py').readAsStringSync();
    final strip = tool.substring(tool.indexOf('LITE_STRIP = ('), tool.indexOf(')', tool.indexOf('LITE_STRIP = (')));
    for (final essential in ['assets/brand', 'assets/mushaf', 'assets/quran/quran', 'espeak-ng-data', 'assets/packs']) {
      expect(strip.contains(essential), isFalse, reason: '$essential must ship in both flavors');
    }
  });
}
