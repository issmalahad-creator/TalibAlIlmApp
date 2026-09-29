import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/usul/narrator_tiers.dart';
import 'package:talib_alilm_app/services/usul/usul_answers.dart';

/// U2 of docs/quran/USUL_TAFSIR_TREE.md — the per-ayah answers. Checked on
/// hand-made sayings AND on the real data for 1:1, whose first athar carries
/// the takhrij «وإسناده ضعيف جدًّا».
Map<String, Object?> saying({
  required String text,
  String type = 'تفسير',
  List<String> narrators = const [],
  String? takhrij,
}) =>
    {
      'type': type,
      'text': takhrij == null
          ? text
          : '$text<sup class="ft"><a title="$takhrij">١</a></sup><footer class="saying-notes">…</footer>',
      'narrators': [for (final n in narrators) {'id': 0, 'name': n}],
    };

void main() {
  test('no pack in lite → every node says «غير محمَّل», except nuzul from the bundled books', () {
    final a = usulAnswersFor(sayings: null, asbab: [
      {'name': 'أسباب نزول القرآن - الواحدي', 'html': 'نزلت في كذا'},
    ]);
    expect(a[UsulKeys.bayanNabawi]!.status, UsulStatus.notDownloaded);
    expect(a[UsulKeys.turuqSahabi]!.status, UsulStatus.notDownloaded);
    expect(a[UsulKeys.nuzul]!.status, UsulStatus.sourced);
    expect(a[UsulKeys.nuzul]!.evidence.single.source, 'أسباب نزول القرآن - الواحدي');
  });

  test('a marfu hadith answers «بيان النبي ﷺ» with the quote and its narrator', () {
    final a = usulAnswersFor(sayings: [
      saying(text: 'عن أبي هريرة قال: قال رسول الله ﷺ: «...»', narrators: ['أبو هريرة']),
    ]);
    final b = a[UsulKeys.bayanNabawi]!;
    expect(b.status, UsulStatus.sourced);
    expect(b.evidence.single.sayer, 'أبو هريرة');
    expect(b.evidence.single.text, contains('قال رسول الله ﷺ'));
  });

  test('tiers: a Companion and a Successor answer their own nodes, unknown names none', () {
    final a = usulAnswersFor(sayings: [
      saying(text: 'قول', narrators: ['عبد الله بن عباس']),
      saying(text: 'قول', narrators: ['مجاهد بن جبر']),
      saying(text: 'قول', narrators: ['اسم غير مصنف']),
    ]);
    expect(a[UsulKeys.turuqSahabi]!.count, 1);
    expect(a[UsulKeys.turuqTabii]!.count, 1);
    expect(narratorTier('اسم غير مصنف'), isNull);
  });

  test('«النقل» quotes the takhrij verdict as written — no verdict of ours', () {
    final a = usulAnswersFor(sayings: [
      saying(text: 'عن فلان قال', takhrij: 'أخرجه ابن جرير. وإسناده ضعيف جدًّا، فيه فلان متروك.'),
    ]);
    final n = a[UsulKeys.naql]!;
    expect(n.status, UsulStatus.sourced);
    expect(n.evidence.single.judgment, 'وإسناده ضعيف جدًّا، فيه فلان متروك.');
  });

  test('several tafsir sayings without «اختلف» are only a hint, never a verdict', () {
    final a = usulAnswersFor(sayings: [
      saying(text: 'قول أول', narrators: ['مجاهد بن جبر']),
      saying(text: 'قول ثان', narrators: ['قتادة بن دعامة']),
    ]);
    expect(a[UsulKeys.ikhtilaf]!.status, UsulStatus.hint);
    expect(a[UsulKeys.ikhtilaf]!.evidence, isEmpty);
    expect(a[UsulKeys.ijma]!.status, UsulStatus.notFound);
  });

  test('evidence is capped at three and long quotes are clipped with «…»', () {
    final long = 'كلمة ' * 100;
    final a = usulAnswersFor(sayings: [for (var i = 0; i < 5; i++) saying(text: 'قال رسول الله ﷺ $long')]);
    final b = a[UsulKeys.bayanNabawi]!;
    expect(b.count, 5);
    expect(b.evidence, hasLength(3));
    expect(b.evidence.first.text, endsWith('…'));
  });

  test('real data, 1:1: the athar branch answers and the takhrij verdict is quoted', () {
    final f = File('assets/quran/corpus/packs/sayings.json.gz');
    if (!f.existsSync()) return; // stripped for a lite build — nothing to check here
    final rows = (jsonDecode(utf8.decode(gzip.decode(f.readAsBytesSync()))) as Map)['rows'] as List;
    final row = rows.firstWhere((r) => r['s'] == 1 && r['a'] == 1) as Map;
    final a = usulAnswersFor(sayings: (row['sayings'] as List).cast<Object?>());
    expect(a[UsulKeys.turuqSahabi]!.status, UsulStatus.sourced);
    // Matched on an undiacritised phrase: the data stores shadda+tanween in
    // its own order, so typed diacritics are not a reliable key.
    expect(a[UsulKeys.naql]!.evidence.map((e) => e.judgment), contains(contains('فيه أبو يعلى إسماعيل بن أمية متروك')));
  });
}
