import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/akhlaq/akhlaq_content.dart';

/// AKHLAQ — proves the schema built for الرفق is genuinely generic: the
/// عيادة المريض slice (docs/akhlaq/adab_book/ar-iyadah.json) parses with
/// the SAME `AkhlaqSlice`/`AkhlaqContent` model, zero code changes.
void main() {
  final raw =
      File('docs/akhlaq/adab_book/ar-iyadah.json').readAsStringSync();
  final slice = AkhlaqContent.parseJsonString(raw);

  test('parses the second vertical slice with the same generic model', () {
    expect(slice.slice, 'iyadat-almarid');
    expect(slice.virtue.slug, 'iyadat_almarid');
    expect(slice.evidence.length, 4);
    expect(slice.principles.length, 7);
    expect(slice.subskills.length, 7);
    expect(slice.behaviors.length, 13);
    expect(slice.scenarios.length, 8);
    expect(slice.curriculum.length, 4);
    expect(slice.translations.length, 11);
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
    expect(tarbawi, hasLength(7));
  });

  test('every scenario is linked to a real subskill and has an aqrab option',
      () {
    final subSlugs = slice.subskills.map((s) => s.slug).toSet();
    for (final sc in slice.scenarios) {
      expect(sc.subskills, isNotEmpty, reason: sc.id);
      for (final ss in sc.subskills) {
        expect(subSlugs, contains(ss), reason: '${sc.id} → $ss');
      }
      expect(sc.options.map((o) => o.verdict), contains('aqrab'),
          reason: '${sc.id} has no aqrab option');
      for (final o in sc.options) {
        for (final ev in o.evidence) {
          expect(slice.evidenceById(ev), isNotNull,
              reason: '${sc.id} opt ${o.key} → $ev');
        }
      }
    }
    // one composite scenario (S-IY-07, the honesty-vs-gentleness tension)
    expect(slice.scenarios.where((s) => s.composite).length, 1);
  });

  test('no fabricated marfūʿ: confirmed hadith carry grader + takhrij', () {
    for (final e in slice.evidence) {
      if (e.isMarfu && e.isConfirmed) {
        expect(e.grader.trim(), isNotEmpty, reason: '${e.id} grader');
        expect(e.grading.trim(), isNotEmpty, reason: '${e.id} grading');
        expect(e.takhrij.trim(), isNotEmpty, reason: '${e.id} takhrij');
      }
    }
  });
}
