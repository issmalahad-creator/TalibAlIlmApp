import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_alilm_app/services/daily_benefit_service.dart';

List<DailyBenefit> _pool() => [
      for (var i = 0; i < 10; i++) DailyBenefit(id: 'nawawi:$i', kind: 'hadith', text: 'h$i', source: 's'),
      for (var i = 0; i < 10; i++) DailyBenefit(id: 'hisn:1:$i', kind: 'dhikr', text: 'd$i', source: 's'),
      for (var i = 0; i < 10; i++) DailyBenefit(id: 'ayah:1:$i', kind: 'ayah', text: 'a$i', source: 's'),
      for (var i = 0; i < 40; i++) DailyBenefit(id: 'fawaid:212:$i:$i', kind: 'faida', text: 'f$i', source: 's'),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = DailyBenefitService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    svc.resetForTest(pool: _pool());
  });

  test('never repeats within the recent-memory window (70 picks from 70 items)', () async {
    final seen = <String>{};
    for (var i = 0; i < 70; i++) {
      final b = await svc.next();
      expect(seen.add(b.id), isTrue, reason: 'repeated ${b.id} at pick $i');
    }
  });

  test('two picks in a row are never the same kind', () async {
    var last = (await svc.next()).kind;
    for (var i = 0; i < 40; i++) {
      final k = (await svc.next()).kind;
      expect(k, isNot(last));
      last = k;
    }
  });

  test('small pools are not drowned by the big one (kind picked first)', () async {
    final counts = <String, int>{};
    for (var i = 0; i < 60; i++) {
      final k = (await svc.next()).kind;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    // 40 of 70 items are fawa'id, but every kind still shows up regularly.
    for (final k in ['hadith', 'dhikr', 'ayah', 'faida']) {
      expect(counts[k] ?? 0, greaterThanOrEqualTo(8), reason: '$k: $counts');
    }
  });

  test('memory survives a restart (persisted), so the next launch is new too', () async {
    final first = await svc.next();
    svc.resetForTest(pool: _pool()); // "restart": fresh service state, same prefs
    for (var i = 0; i < 30; i++) {
      expect((await svc.next()).id, isNot(first.id));
    }
  });

  test('splash pick and the Home card differ in the same launch', () async {
    await svc.preloadForSplash();
    final splash = svc.splashPick.value!;
    final home = await svc.next();
    expect(home.id, isNot(splash.id));
    expect(home.kind, isNot(splash.kind));
  });

  test('the bundled pool is well-formed: sourced, whole, no editor intro, no basmala prefix', () {
    final j = jsonDecode(File('assets/brand/daily_benefits.json').readAsStringSync()) as Map<String, dynamic>;
    final items = (j['items'] as List).cast<Map<String, dynamic>>();
    expect(items.length, greaterThan(200));
    for (final it in items) {
      expect((it['source'] as String).trim(), isNotEmpty, reason: it['id'] as String);
      expect((it['text'] as String).contains('<'), isFalse, reason: it['id'] as String);
      if ((it['id'] as String).startsWith('fawaid:')) {
        final apiPage = int.parse((it['id'] as String).split(':')[2]);
        expect(apiPage, greaterThanOrEqualTo(11), reason: 'editor intro leaked: ${it['id']}');
      }
      if (it['kind'] == 'ayah' && it['ayah'] == 1 && it['surah'] != 1) {
        expect((it['text'] as String).startsWith('بِسْمِ'), isFalse, reason: it['id'] as String);
      }
    }
    final kinds = items.map((e) => e['kind']).toSet();
    expect(kinds, containsAll(['hadith', 'dhikr', 'ayah', 'faida']));
  });
}
