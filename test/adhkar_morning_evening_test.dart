import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/adhkar_repository.dart';

/// Guards `tool/fix_adhkar_morning_evening.py`: the upstream scrape had put
/// each morning/evening note on the wrong dhikr, and morning/evening were
/// one list with the evening wording hidden in those notes.
void main() {
  final chapters = jsonDecode(File('assets/adhkar/hisn_almuslim.json').readAsStringSync()) as List<dynamic>;
  final chapter = chapters.cast<Map<String, dynamic>>().firstWhere((c) => c['title'] == 'أذكار الصباح والمساء');
  final raw = (chapter['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  final items = [
    for (var i = 0; i < raw.length; i++)
      AdhkarItem(
        id: i,
        text: raw[i]['text'] as String,
        footnote: raw[i]['footnote'] as String?,
        repeatCount: raw[i]['repeat'] as int,
        timeOfDay: raw[i]['when'] as String?,
        eveningText: raw[i]['evening'] as String?,
      ),
  ];
  AdhkarItem byStart(String start) => items.firstWhere((i) => i.text.startsWith(start));

  test('each virtue note sits on its own dhikr', () {
    expect(byStart('حسبي الله').footnote, contains('سبع مرات'));
    expect(byStart('اللهم إني أصبحت').footnote, contains('أربع مرات'));
    expect(byStart('اللهم ما أصبح بي').footnote, contains('شكر يومه'));
    expect(byStart('اللهم أنت ربي').footnote, contains('دخل الجنة'));
    expect(byStart('بسم الله الذي لا يضر').footnote, contains('لم يضره شيء'));
    expect(byStart('رضيت بالله').footnote, contains('يرضيه'));
    expect(byStart('يا حي يا قيوم').footnote, contains('الحاكم'));
    for (final i in items) {
      expect(i.footnote ?? '', isNot(contains('وإذا أمسى')), reason: i.text);
    }
  });

  test('morning and evening sessions', () {
    final morning = [for (final i in items) ?i.forSession('morning')];
    final evening = [for (final i in items) ?i.forSession('evening')];
    expect(morning.length, 24);
    expect(evening.length, 22);
    expect(morning.any((i) => i.text.startsWith('أعوذ بكلمات الله التامات')), isFalse);
    expect(evening.any((i) => i.text.startsWith('أعوذ بكلمات الله التامات')), isTrue);
    for (final i in evening) {
      expect(i.text.replaceAll('وبك أصبحنا', ''), isNot(contains('أصبح')), reason: i.text);
    }
    for (final i in morning) {
      expect(i.text, isNot(contains('أمسى')), reason: i.text);
      expect(i.text, isNot(contains('وإذا أمسي')), reason: i.text);
    }
    expect(evening.firstWhere((i) => i.text.startsWith('أمسينا وأمسى الملك لله،')).text, contains('هذه الليلة'));
  });

  test('items of other chapters pass through unchanged', () {
    final other = AdhkarItem(id: 1, text: 'x', repeatCount: 1);
    expect(other.forSession('evening'), same(other));
  });
}
