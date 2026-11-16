import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/fiqh_tree.dart';

/// ش1 (docs/KNOWLEDGE_TREE_ZAD_PLAN.md): «كتاب الطهارة» from Zad, Bulugh and
/// al-Rawd — the authors' words only, nothing from the modern editors.
void main() {
  final tree = FiqhTree.fromJson(
      jsonDecode(File(FiqhTree.zadTaharah).readAsStringSync()) as Map<String, dynamic>);

  test('eleven chapters in Zad\'s own order, each with rulings and an al-Rawd page', () {
    expect(tree.chapters.map((c) => c.title).toList(), [
      'المياه', 'باب الآنية', 'باب الاستنجاء', 'باب السواك وسنن الوضوء', 'باب فروض الوضوء وصفته',
      'باب مسح الخفين', 'باب نواقض الوضوء', 'باب الغسل', 'باب التيمم', 'باب إزالة النجاسة', 'باب الحيض',
    ]);
    for (final c in tree.chapters) {
      expect(c.masail, isNotEmpty, reason: c.title);
      expect(c.sharhExcerpt.length, greaterThan(40), reason: c.title);
      expect(c.sharhPage, greaterThan(0));
    }
    expect(tree.chapters.first.masail[1].text, startsWith('المياه ثلاثة: طهور'));
  });

  test('Bulugh al-Maram: hadith 1–150 of كتاب الطهارة, each exactly once, every chapter has its evidence', () {
    final all = [for (final l in tree.hadithByChapter.values) ...l]..sort((a, b) => a.n.compareTo(b.n));
    expect(all.map((h) => h.n).toList(), List.generate(150, (i) => i + 1));
    for (final c in tree.chapters) {
      expect(tree.evidenceFor(c), isNotEmpty, reason: c.evidenceChapter);
    }
    String bare(String t) => t.replaceAll(RegExp('[ً-ْ]'), '');
    expect(bare(all.first.text), contains('هو الطهور ماؤه'));
    expect(bare(all.first.text), contains('أخرجه الأربعة')); // Ibn Hajr's own takhrij is kept
  });

  test('none of the modern editors\' apparatus leaks in: footnotes, page markers, gradings, variant quotes', () {
    final footnoteRef = RegExp(r'\(\s*[٠-٩]+\s*\)|⦗|_{3}');
    for (final h in [for (final l in tree.hadithByChapter.values) ...l]) {
      expect(footnoteRef.hasMatch(h.text), isFalse, reason: 'hadith ${h.n}');
      expect(h.text, isNot(contains('صحيح. رواه'))); // al-Zuhayri's footnote grading
    }
    for (final c in tree.chapters) {
      for (final m in c.masail) {
        expect(RegExp(r'[٠-٩"<]').hasMatch(m.text), isFalse, reason: m.id);
      }
    }
  });

  test('ruling highlights come from the matn\'s own words, negation first', () {
    final miyah = tree.chapters.first.masail;
    expect(miyah.firstWhere((m) => m.text.endsWith('لم يكره.')).ruling, ['لا يُكره']);
    expect(miyah.firstWhere((m) => m.text.contains('بغير ممازج')).ruling, ['يُكره']);
  });

  group('every kitab of Zad\'s worship (ش7)', () {
    final index = (jsonDecode(File(FiqhTree.indexAsset).readAsStringSync()) as Map<String, dynamic>)['trees'] as List;
    final trees = {
      for (final t in index.cast<Map<String, dynamic>>())
        t['id'] as String: FiqhTree.fromJson(jsonDecode(File(t['asset'] as String).readAsStringSync()) as Map<String, dynamic>),
    };

    test('six kitabs in book order', () {
      expect(trees.keys.toList(), ['zad.taharah', 'zad.salah', 'zad.janaiz', 'zad.zakah', 'zad.siyam', 'zad.hajj']);
    });

    test('every chapter has rulings, an al-Rawd page and Bulugh evidence; no hadith twice in a kitab', () {
      for (final t in trees.values) {
        for (final c in t.chapters) {
          expect(c.masail, isNotEmpty, reason: '${t.id} ${c.title}');
          expect(c.sharhPage, greaterThan(0), reason: '${t.id} ${c.title}');
          expect(t.evidenceFor(c), isNotEmpty, reason: '${t.id} ${c.title} ← ${c.evidenceChapter}');
        }
        final ids = [for (final l in t.hadithByChapter.values) for (final h in l) h.label];
        expect(ids.toSet().length, ids.length, reason: t.id);
        for (final m in [for (final c in t.chapters) ...c.masail]) {
          expect(RegExp(r'[٠-٩"<⦗]').hasMatch(m.text), isFalse, reason: m.id);
          expect(RegExp(r'[.:؛؟!]$').hasMatch(m.text), isTrue, reason: '${m.id} split across pages?');
        }
      }
    });

    test('a chapter title shared by two kitabs resolves inside its own kitab («باب المواقيت»)', () {
      final salah = trees['zad.salah']!;
      final nums = [for (final l in salah.hadithByChapter.values) for (final h in l) h.n];
      expect(nums.every((n) => n >= 151 && n <= 531), isTrue, reason: 'Salah hadith outside كتاب الصلاة: $nums');
      final hajjMiqat = trees['zad.hajj']!.chapters.firstWhere((c) => c.title == 'باب المواقيت');
      expect(trees['zad.hajj']!.evidenceFor(hajjMiqat).first.n, greaterThan(700));
    });
  });
}
