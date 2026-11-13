import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/curriculum_levels.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/l10n/basic_translations.dart';
import 'package:talib_alilm_app/models/qaida.dart';
import 'package:talib_alilm_app/repositories/curriculum_repository.dart';
import 'package:talib_alilm_app/screens/qaida/qaida_home_screen.dart';
import 'package:talib_alilm_app/screens/qaida/qaida_lesson_screen.dart';
import 'package:talib_alilm_app/services/qaida_content.dart';

/// The Noorani Qaida (Ismail 2026-11-13): nine lessons from
/// assets/qaida/qaida_lessons.json, sounds recorded by Ismail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseHelper.databaseName = 'talib_qaida_test.db';

  final json = jsonDecode(File(QaidaContent.lessonsAsset).readAsStringSync()) as Map<String, dynamic>;
  final lessons = [for (final l in (json['lessons'] as List)) QaidaLesson.fromJson(l as Map<String, dynamic>)];

  test('the JSON lessons are exactly kQaidaLessonIds, in order', () {
    expect(lessons.map((l) => l.id).toList(), kQaidaLessonIds);
  });

  test('405 distinct sounds; no empty cell; every cell fully vocalized where it should be', () {
    final ids = <String>{for (final l in lessons) for (final i in l.items) i.audioId};
    expect(ids.length, 405);
    for (final l in lessons) {
      for (final i in l.items) {
        expect(i.text.trim(), isNotEmpty);
      }
    }
    // harakat / tanween / madd / leen / sukoon / shadda lessons: every cell carries a mark
    final marks = RegExp('[ً-ْ]');
    for (final l in lessons.where((l) => int.parse(l.id.substring(1)) >= 4)) {
      for (final i in l.items) {
        expect(marks.hasMatch(i.text), isTrue, reason: '${l.id} ${i.text}');
      }
    }
  });

  test('the disjointed letters are the mushaf text of the āyah they cite', () {
    final ayat = <String, String>{};
    for (final line in File('assets/quran/quran-uthmani.txt').readAsLinesSync()) {
      final p = line.split('|');
      if (p.length >= 3) ayat['${p[0]}:${p[1]}'] = p.sublist(2).join('|');
    }
    final q03 = lessons.firstWhere((l) => l.id == 'q03');
    expect(q03.items.length, 14);
    for (final i in q03.items) {
      expect(ayat[i.ref], contains(i.text), reason: i.ref);
    }
  });

  test('every lesson title and note, and every Qaida string, exists in all 13 languages', () {
    const langs = ['ar', 'en', 'am', 'fr', 'sw', 'ur', 'tr', 'id', 'bn', 'ha', 'so', 'fa', 'ms'];
    final keys = [
      'feat_qaida', 'qaida_sub', 'qaida_items_n', 'qaida_lesson_n', 'qaida_play_all', 'qaida_stop',
      'qaida_mark_done', 'qaida_next', 'qaida_all_done', 'qaida_tap_hint', 'qaida_no_audio', 'qaida_audio_partial',
      for (final l in lessons) ...[l.titleKey, l.noteKey],
    ];
    for (final k in keys) {
      for (final lang in langs) {
        expect(basicTranslations[k]?[lang], isNotNull, reason: '$k/$lang');
      }
    }
  });

  Future<void> settle(WidgetTester t, Finder f) async {
    for (var i = 0; i < 80 && f.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
  }

  testWidgets('home lists nine lessons; a lesson without recordings says so; finishing it counts on the curriculum map',
      (t) async {
    QaidaContent.instance.resetForTest();
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));

    await t.pumpWidget(const MaterialApp(home: QaidaHomeScreen()));
    await settle(t, find.text(basicText('qaida_q01_title', 'ar')));
    expect(find.text(basicText('qaida_q01_title', 'ar')), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.pumpWidget(MaterialApp(home: QaidaLessonScreen(lessons: lessons, index: 3)));
    await settle(t, find.text(basicText('qaida_no_audio', 'ar')));
    expect(find.text('بَ'), findsOneWidget);
    expect(find.text(basicText('qaida_no_audio', 'ar')), findsOneWidget); // nothing recorded yet
    expect(find.text(basicText('qaida_play_all', 'ar')), findsNothing); // nothing to play

    await t.tap(find.text(basicText('qaida_mark_done', 'ar')));
    await settle(t, find.text(basicText('qaida_next', 'ar')));
    expect(find.text(basicText('qaida_next', 'ar')), findsOneWidget);

    final statuses = await t.runAsync(() => CurriculumRepository().statusesFor(curriculumLevels.first.items));
    final qaida = statuses!.firstWhere((s) => s.contentType == 'qaida');
    expect(qaida.state, CurriculumItemState.inProgress);
    expect(qaida.progressFraction, closeTo(1 / 9, 1e-9));
  });
}
