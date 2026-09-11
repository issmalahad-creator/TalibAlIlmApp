import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';

/// AKHLAQ — the الرفق content spec must parse into the model, and the
/// same invariants `tool/akhlaq_validate.py` enforces must hold in Dart.
void main() {
  final raw = File('docs/akhlaq/alrifq/ar-rifq.json').readAsStringSync();
  final slice = AkhlaqContent.parseJsonString(raw);

  test('parses with the expected shape', () {
    expect(slice.slice, 'al-rifq');
    expect(slice.virtue.slug, 'rifq');
    expect(slice.evidence.length, 11);
    expect(slice.principles.length, 9);
    expect(slice.subskills.length, 12);
    expect(slice.behaviors.length, 37);
    expect(slice.scenarios.length, 12);
    expect(slice.curriculum.length, 7);
    expect(slice.translations.length, 116);
  });

  test('every evidence has a source + text; marfūʿ@confirmed has takhrij',
      () {
    for (final e in slice.evidence) {
      expect(e.textAr.trim(), isNotEmpty, reason: '${e.id} text');
      expect(e.book.trim(), isNotEmpty, reason: '${e.id} book');
      expect(e.edition.trim(), isNotEmpty, reason: '${e.id} edition');
      expect(['source_confirmed', 'source_located', 'source_uncertain'],
          contains(e.sourceStatus),
          reason: '${e.id} status');
      if (e.isMarfu && e.isConfirmed) {
        expect(e.grader.trim(), isNotEmpty, reason: '${e.id} grader');
        expect(e.grading.trim(), isNotEmpty, reason: '${e.id} grading');
        expect(e.takhrij.trim(), isNotEmpty, reason: '${e.id} takhrij');
      }
    }
    // 9 confirmed / 2 located (EV-07, EV-11)
    expect(
        slice.evidence.where((e) => e.sourceStatus == 'source_confirmed').length,
        9);
    expect(
        slice.evidence.where((e) => e.sourceStatus == 'source_located').length,
        2);
  });

  test('every principle is pedagogical, never attributed to a scholar', () {
    for (final p in slice.principles) {
      expect(p.interpretationBy, 'منهج التطبيق التربوي', reason: p.id);
      expect(p.statementAr.contains('قال الشيخ'), isFalse, reason: p.id);
      for (final ev in p.evidence) {
        expect(slice.evidenceById(ev), isNotNull, reason: '${p.id} → $ev');
      }
    }
  });

  test('every behavior traces to an evidence OR is [TARBAWI]', () {
    final tarbawi = <String>[];
    for (final b in slice.behaviors) {
      if (b.isTarbawi) {
        tarbawi.add(b.id);
        continue;
      }
      expect(slice.evidenceById(b.basis), isNotNull,
          reason: '${b.id} basis "${b.basis}"');
    }
    expect(tarbawi, hasLength(6));
  });

  test('every scenario is linked to a subskill and has a 1..8 difficulty',
      () {
    final subSlugs = slice.subskills.map((s) => s.slug).toSet();
    final byDiff = <int, int>{};
    for (final sc in slice.scenarios) {
      expect(sc.subskills, isNotEmpty, reason: sc.id);
      for (final ss in sc.subskills) {
        expect(subSlugs, contains(ss), reason: '${sc.id} → $ss');
      }
      expect(sc.difficulty, inInclusiveRange(1, 8), reason: sc.id);
      expect(sc.options.map((o) => o.verdict), contains('aqrab'),
          reason: '${sc.id} has no aqrab option');
      for (final o in sc.options) {
        for (final ev in o.evidence) {
          expect(slice.evidenceById(ev), isNotNull,
              reason: '${sc.id} opt ${o.key} → $ev');
        }
      }
      byDiff[sc.difficulty] = (byDiff[sc.difficulty] ?? 0) + 1;
    }
    expect(byDiff, {1: 1, 2: 1, 3: 2, 4: 2, 5: 2, 6: 1, 7: 2, 8: 1});
    expect(slice.scenarios.where((s) => s.composite).length, 3);
  });

  test('translations: every row has an original; QURAN_MEANING not automated',
      () {
    final ids = {
      'evidence': slice.evidence.map((e) => e.id).toSet(),
      'principle': slice.principles.map((p) => p.id).toSet(),
      'subskill': slice.subskills.map((s) => s.slug).toSet(),
      'scenario': slice.scenarios.map((s) => s.id).toSet(),
      'stage': slice.curriculum.map((c) => '${c.stage}').toSet(),
    };
    for (final t in slice.translations) {
      if (ids.containsKey(t.refKind)) {
        expect(ids[t.refKind], contains(t.refId),
            reason: '${t.refKind}/${t.refId}');
      } else {
        expect(t.refKind, 'term_gloss');
      }
      if (t.translationType == 'quran_meaning') {
        expect(t.translator.toLowerCase().contains('claude'), isFalse);
        expect(t.translationStatus, 'pending');
      }
    }
    // en covers every evidence text
    final enEv = slice.translations
        .where((t) =>
            t.refKind == 'evidence' && t.lang == 'en' && t.layer == 'text')
        .map((t) => t.refId)
        .toSet();
    expect(enEv.length, 11);
  });

  test('AkhlaqContent.translation never fabricates a missing language', () {
    final c = AkhlaqContent.instance;
    c.debugSetSlice(slice);
    // EN literal exists for EV-01
    expect(
        c.translation(
            refKind: 'evidence', refId: 'EV-01', layer: 'text', lang: 'en'),
        isNotNull);
    // Urdu is pending → null (UI then shows Arabic only)
    expect(
        c.translation(
            refKind: 'evidence', refId: 'EV-01', layer: 'text', lang: 'ur'),
        isNull);
    // the source language returns null (it's the original, not a translation)
    expect(
        c.translation(
            refKind: 'evidence',
            refId: 'EV-01',
            layer: 'text',
            lang: AkhlaqContent.arSource),
        isNull);
    expect(c.availableLanguages(), containsAll(['en', 'fr']));
    c.debugSetSlice(null);
  });
}
