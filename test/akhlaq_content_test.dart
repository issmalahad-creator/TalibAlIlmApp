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
    expect(slice.translations.length, 285);
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
      'scenario_option': {
        for (final s in slice.scenarios)
          for (final o in s.options) '${s.id}:${o.key}',
      },
      'stage': slice.curriculum.map((c) => '${c.stage}').toSet(),
      'virtue': {slice.virtue.slug},
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
        // Never AI-generated: either genuinely not sourced yet (pending),
        // or copied verbatim from a real bundled licensed Qur'an
        // translation (approved) — never 'generated'/'machine_assisted'/
        // 'human_reviewed', which would imply someone produced the wording.
        expect(['pending', 'approved'], contains(t.translationStatus),
            reason: '${t.refKind}/${t.refId}/${t.lang}');
      }
    }
    // en covers every evidence text
    final enEv = slice.translations
        .where((t) =>
            t.refKind == 'evidence' && t.lang == 'en' && t.layer == 'text')
        .map((t) => t.refId)
        .toSet();
    expect(enEv.length, 11);
    // en covers every scenario option's text + why (2026-09-13: Ismail
    // asked for a real translation under the Arabic everywhere, not just
    // the stem — this was the gap the original pass deferred).
    final totalOptions =
        slice.scenarios.fold<int>(0, (n, s) => n + s.options.length);
    for (final layer in ['text', 'why']) {
      final enOpt = slice.translations
          .where((t) =>
              t.refKind == 'scenario_option' &&
              t.lang == 'en' &&
              t.layer == layer)
          .map((t) => t.refId)
          .toSet();
      expect(enOpt.length, totalOptions, reason: 'layer=$layer');
    }
    for (final layer in ['probe', 'feedback', 'reflection']) {
      final enLayer = slice.translations
          .where((t) =>
              t.refKind == 'scenario' && t.lang == 'en' && t.layer == layer)
          .map((t) => t.refId)
          .toSet();
      expect(enLayer.length, 12, reason: 'layer=$layer');
    }
    // am covers evidence (10 literal + 1 real bundled Qur'an translation),
    // every principle, subskill, stage outcome, term gloss, and the virtue
    // title (2026-09-13: Ismail is in Ethiopia and asked specifically that
    // every AKHLAQ text have a real translation under the Arabic).
    final amEv = slice.translations
        .where((t) =>
            t.refKind == 'evidence' && t.lang == 'am' && t.layer == 'text')
        .map((t) => t.refId)
        .toSet();
    expect(amEv.length, 11);
    for (final entry in {
      'principle': slice.principles.length,
      'subskill': slice.subskills.length,
      'stage': slice.curriculum.length,
    }.entries) {
      final amCount = slice.translations
          .where((t) => t.refKind == entry.key && t.lang == 'am')
          .length;
      expect(amCount, entry.value, reason: entry.key);
    }
    expect(
        slice.translations
            .where((t) => t.refKind == 'term_gloss' && t.lang == 'am')
            .length,
        6);
    expect(
        slice.translations
            .where((t) => t.refKind == 'virtue' && t.lang == 'am')
            .length,
        1);
    // EV-11 (Qur'an) in Amharic must be the real bundled licensed
    // translation, never Claude-generated for the ayah text itself.
    final amQuran = slice.translations.firstWhere((t) =>
        t.refKind == 'evidence' && t.refId == 'EV-11' && t.lang == 'am');
    expect(amQuran.translationType, 'quran_meaning');
    expect(amQuran.translator.toLowerCase().contains('claude'), isFalse);
    expect(amQuran.translationStatus, 'approved');
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
    expect(c.availableLanguages(), containsAll(['en', 'fr', 'am']));
    c.debugSetSlice(null);
  });
}
