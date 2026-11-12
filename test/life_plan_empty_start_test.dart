import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/life_plan_suggestions.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/repositories/life_plan_repository.dart';
import 'package:talib_alilm_app/widgets/life_suggestion_picker.dart';

/// Ismail 2026‑11‑12: «فارغة مع اقتراحات». A new user's Life Engine starts
/// with NO plan (no one else's personal schedule) and is offered general
/// suggestion packs to pick from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final repo = LifePlanRepository();

  setUpAll(() {
    DatabaseHelper.databaseName = 'talib_life_empty_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
  });

  test('a new user starts with an empty plan, but a running day count',
      () async {
    await repo.ensureStarted();
    expect(await repo.pillars(), isEmpty);
    expect(await repo.slots(), isEmpty);
    expect(await repo.meta('start_date'), LifePlanRepository.today());
    expect(await repo.dayIndex(), 0);
    final prog = await repo.progress(LifePlanRepository.today());
    expect(prog.totalCount, 0);
    expect(prog.percent, 0);
  });

  test('ensureStarted never moves an existing start date', () async {
    await repo.setMeta('start_date', '2026-01-01');
    await repo.ensureStarted();
    expect(await repo.meta('start_date'), '2026-01-01');
  });

  test('every suggestion string exists in all 13 languages', () {
    const langs = ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms'];
    final keys = {
      for (final s in kLifeSuggestionPacks) ...[
        s.labelKey,
        s.targetKey,
        for (final b in s.blocks) b.$3,
      ],
      'life_start_title', 'life_start_body', 'life_start_add_selected',
      'life_start_build_own', 'life_add_suggestions', 'life_sug_none_left',
    };
    for (final k in keys) {
      final m = basicTranslations[k];
      expect(m, isNotNull, reason: k);
      for (final l in langs) {
        expect(m![l]?.trim(), isNotEmpty, reason: '$k/$l');
      }
    }
  });

  test('adding all suggestions builds a time-ordered plan', () async {
    await repo.addSuggestions(kLifeSuggestionPacks, 'en');
    final pillars = await repo.pillars();
    expect(pillars.length, kLifeSuggestionPacks.length);
    expect(pillars.every((p) => p.key.startsWith('sug_')), isTrue);
    final slots = await repo.slots();
    expect(slots.length,
        kLifeSuggestionPacks.fold<int>(0, (n, p) => n + p.blocks.length));
    for (var i = 1; i < slots.length; i++) {
      expect(slots[i].startMin, greaterThanOrEqualTo(slots[i - 1].startMin));
    }
    expect(slots.first.activity, contains('Fajr'));
    expect(await repo.availableSuggestions(), isEmpty);
  });

  testWidgets('the picker hands back only the ticked packs', (t) async {
    List<LifeSuggestionPack>? got;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LifeSuggestionPicker(
            packs: kLifeSuggestionPacks,
            lang: 'ar',
            onAdd: (p) => got = p,
          ),
        ),
      ),
    ));
    // untick the first pack, then add
    await t.tap(find.byType(Checkbox).first);
    await t.pump();
    await t.tap(find.text(basicText('life_start_add_selected', 'ar')));
    await t.pump();
    expect(got, isNotNull);
    expect(got!.length, kLifeSuggestionPacks.length - 1);
    expect(got!.any((p) => p.key == kLifeSuggestionPacks.first.key), isFalse);
  });
}
